package dbx

import (
	//    "database/sql"
	"database/sql"
	"errors"
	"fmt"
	"log"
	"net/url"
	"strings"
	"time"

	_ "github.com/chaisql/chai"
	"github.com/jmoiron/sqlx"
	_ "github.com/microsoft/go-mssqldb"

	"pso.oneidentity.com/ois"
)

const MAX_RESULTS = 1000

type DBConfig struct {
	UserName       string
	Password       string
	HostName       string
	Port           int
	DatabaseName   string
	MaxConnections int
}

func CreateCtxFromStruct(config *DBConfig) (*sqlx.DB, error) {
	return CreateCtx(config.UserName, config.Password, config.HostName, config.Port, config.DatabaseName, config.MaxConnections)
}

func CreateCtx(
	username string, password string,
	host string, port int, database string,
	maxConnections int) (*sqlx.DB, error) {

	query := url.Values{}
	query.Add("database", database)

	u := &url.URL{
		Scheme:   "sqlserver",
		User:     url.UserPassword(username, password),
		Host:     fmt.Sprintf("%s:%d", host, port),
		RawQuery: query.Encode(),
	}
	db, err := sqlx.Open("sqlserver", u.String())
	if err != nil {
		log.Println(err)
		return db, err
	}
	if maxConnections > 0 {
		db.SetMaxOpenConns(maxConnections)
	}

	err = db.Ping()
	if err != nil {
		log.Println(err)
		return db, err
	}
	fmt.Println("Connected!")

	return db, nil
}

func GetTableCount(db *sqlx.DB, table string, clause string) (int, error) {
	count := -1
	q := fmt.Sprintf("SELECT count(*) FROM %s WHERE %s", table, clause)
	row := db.QueryRow(q)
	row.Scan(&count)
	return count, nil
}

func GetTableRows(db *sqlx.DB, table string, clause string) (*sqlx.Rows, error) {
	return db.Queryx(fmt.Sprintf("SELECT * FROM %s WHERE %s", table, clause))
}
func GetAllTableRows(db *sqlx.DB, table string) (*sqlx.Rows, error) {
	return GetTableRows(db, table, "1=1")
}

// use maxRows=-1 to fetch all
func GetBufferedTableData(db *sqlx.DB, table string, clause string, maxRows int) ([]map[string]interface{}, error) {
	bufSize := maxRows
	if bufSize <= 0 {
		bufSize = MAX_RESULTS
	}

	// array of results
	var r = make([]map[string]interface{}, bufSize)
	count := 0

	rows, err := GetTableRows(db, table, clause)
	if err != nil {
		log.Println(err)
		return r, err
	}

	for (count < bufSize) && rows.Next() {
		buf := make(map[string]interface{})
		err = rows.MapScan(buf)
		if err != nil {
			log.Println(err)
			return r, err
		}

		r[count] = buf
		count++
	}

	return r, nil
}

// return map of key-value pairs from connection string - key=val;key=val;...
func DecodeConnectionString(cs string) map[string]string {
	return ois.DecodeMap(cs, ";", "=")
}

// return foreign key where clause
func GetFKWC(row *map[string]interface{}, attrName string) (string, error) {
	return GetCRWC(attrName, row, attrName)
}

// return CR relation where clause
func GetCRWC(foreignAttrName string, row *map[string]interface{}, attrName string) (string, error) {
	rval, ok := (*row)[attrName]
	if ok && rval != nil {
		return fmt.Sprintf("%s = '%v'", foreignAttrName, rval), nil
	}
	return "", errors.New("unable to parse foreign key value")
}

// PopulateChaiFromRows creates a new Chai in-memory database and populates it
// with data from the provided sql.Rows. The table name must be provided.
// Returns the database connection and any error encountered.
/*
 Claude prompt:
 Please write a golang function that accepts sql.Rows as a parameter, creates a new chai in-memory database, and populates this new database with the content of the sql.Rows parameter.  User shouldn't need to provide a table name.  Name can be random and should be returned to caller
*/
func PopulateTempDBFromRows(rows *sqlx.Rows) (*sqlx.DB, string, error) {
	// Generate a random table name
	tableName := fmt.Sprintf("table_%d", time.Now().UnixNano())

	// Create a new Chai in-memory database
	db, err := sqlx.Open("chai", ":memory:")
	if err != nil {
		return nil, "", fmt.Errorf("failed to create chai database: %w", err)
	}

	// Get column information
	columns, err := rows.Columns()
	if err != nil {
		db.Close()
		return nil, "", fmt.Errorf("failed to get columns: %w", err)
	}

	if len(columns) == 0 {
		db.Close()
		return nil, "", fmt.Errorf("no columns found in rows")
	}

	// Get column types (if available)
	columnTypes, err := rows.ColumnTypes()
	if err != nil {
		db.Close()
		return nil, "", fmt.Errorf("failed to get column types: %w", err)
	}

	// Build CREATE TABLE statement
	createStmt := buildCreateTableStatement(tableName, columns, columnTypes)

	// Create the table
	_, err = db.Exec(createStmt)
	if err != nil {
		db.Close()
		return nil, "", fmt.Errorf("failed to create table: %w", err)
	}

	// Build INSERT statement
	placeholders := make([]string, len(columns))
	for i := range placeholders {
		placeholders[i] = "?"
	}
	insertStmt := fmt.Sprintf("INSERT INTO %s (%s) VALUES (%s)",
		tableName,
		strings.Join(columns, ", "),
		strings.Join(placeholders, ", "))

	// Prepare the insert statement
	stmt, err := db.Prepare(insertStmt)
	if err != nil {
		db.Close()
		return nil, "", fmt.Errorf("failed to prepare insert statement: %w", err)
	}
	defer stmt.Close()

	// Iterate through rows and insert into Chai database
	values := make([]interface{}, len(columns))
	valuePtrs := make([]interface{}, len(columns))
	for i := range values {
		valuePtrs[i] = &values[i]
	}

	rowCount := 0
	for rows.Next() {
		err = rows.Scan(valuePtrs...)
		if err != nil {
			db.Close()
			return nil, "", fmt.Errorf("failed to scan row %d: %w", rowCount, err)
		}

		_, err = stmt.Exec(values...)
		if err != nil {
			db.Close()
			return nil, "", fmt.Errorf("failed to insert row %d: %w", rowCount, err)
		}
		rowCount++
	}

	// Check for errors during iteration
	if err = rows.Err(); err != nil {
		db.Close()
		return nil, "", fmt.Errorf("error iterating rows: %w", err)
	}

	return db, tableName, nil
}

// buildCreateTableStatement constructs a CREATE TABLE statement based on column information
func buildCreateTableStatement(tableName string, columns []string, columnTypes []*sql.ColumnType) string {
	var columnDefs []string

	for i, col := range columns {
		colType := "TEXT" // Default to TEXT

		if i < len(columnTypes) {
			// Map SQL types to Chai types
			dbType := columnTypes[i].DatabaseTypeName()
			switch strings.ToUpper(dbType) {
			case "INT", "INTEGER", "BIGINT", "SMALLINT", "TINYINT":
				colType = "INTEGER"
			case "REAL", "DOUBLE", "FLOAT", "DECIMAL", "NUMERIC":
				colType = "DOUBLE"
			case "BOOL", "BOOLEAN":
				colType = "BOOLEAN"
			case "BLOB", "BYTEA":
				colType = "BLOB"
			default:
				colType = "TEXT"
			}
		}

		columnDefs = append(columnDefs, fmt.Sprintf("%s %s", col, colType))
	}

	return fmt.Sprintf("CREATE TABLE %s (%s)", tableName, strings.Join(columnDefs, ", "))
}

// InsertMap inserts a map of column-value pairs into the specified table.
// It returns the sql.Result and any error encountered.
/*

 Claude prompt:
 Please write a golang function that takes a sql.Database, table name, and map, then inserts the map values into the named table.  The insert query format should be supported by the chai in-memory database engine.

 	data := map[string]interface{}{
 		"id":    1,
 		"name":  "John Doe",
 		"email": "john@example.com",
 	}
 	result, err := InsertMap(db, "users", data)

 NB: need to adjust prompt to avoid parameterized INSERT statement
*/
func InsertMap(db *sqlx.DB, tableName string, data map[string]string) (sql.Result, error) {

	if len(data) == 0 {
		return nil, fmt.Errorf("data map cannot be empty")
	}

	// Build column names and placeholders
	columns := make([]string, 0, len(data))
	placeholders := make([]string, 0, len(data))
	values := make([]string, 0, len(data))

	i := 1
	for col, val := range data {
		columns = append(columns, col)
		placeholders = append(placeholders, fmt.Sprintf("$%d", i))
		values = append(values, val)
		i++
	}

	// Construct INSERT query
	query := fmt.Sprintf(
		"INSERT INTO %s (%s) VALUES ('%s')",
		tableName,
		strings.Join(columns, ", "),
		strings.Join(values, "', '"),
	)

	// Execute the query
	result, err := db.Exec(query)
	if err != nil {
		log.Println(query)
		return nil, fmt.Errorf("failed to insert into %s: %w", tableName, err)
	}

	return result, nil
}
