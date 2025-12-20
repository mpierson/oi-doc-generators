package exml

import (
	//    "database/sql"
	"bufio"
	"bytes"
	"errors"
	"fmt"
	"io"
	"log"
	"regexp"
	"slices"
	"sort"
	"strings"
	"sync"

	//    "compress/gzip"
	"encoding/xml"

	"github.com/jmoiron/sqlx"

	"pso.oneidentity.com/oneim"
	"pso.oneidentity.com/oneim/dbx"
)

// caller's options for encoding
type EncodingOptions struct {
	NoContent        bool
	NoAttributeSort  bool
	PluralObjectName string
	MaxWorkers       int
	IsSingleton      bool
	ExcludeAttrs     []string
	RawXML           bool // do not apply xml encoding to content
	SkipEmpty        bool // if attribute is null, do not included in XML
	PostFilter       func(*TableContext) bool
	F_Attrs          func(c *TableContext) ([]xml.Attr, error)
	F_Content        func(c *TableContext)
}

var Options_NONE = EncodingOptions{}

func getNonNullOptions(o []EncodingOptions) EncodingOptions {
	if o != nil {
		return o[0]
	} else {
		return Options_NONE
	}
}

func (opt EncodingOptions) getPluralName(name string) string {

	pluralName := name + "s"
	if len(opt.PluralObjectName) > 0 {
		pluralName = opt.PluralObjectName
	}
	return pluralName

}

func (opt EncodingOptions) singleThread() EncodingOptions {
	if opt.MaxWorkers > 0 {
		return opt
	}
	opt.MaxWorkers = 1
	return opt
}

// type passed to closure when processing one row of table
type TableContext struct {
	DBContext *sqlx.DB
	Name      string
	Row       *map[string]interface{}
	Writer    io.Writer
	Options   EncodingOptions
}

func (c *TableContext) GetStringVal(name string) string {
	rval, ok := (*c.Row)[name]
	if ok && rval != nil {
		return fmt.Sprintf("%v", rval)
	}
	return ""
}

func NewTableContext(name string, attrs *map[string]interface{}, o io.Writer) *TableContext {

	tc := TableContext{
		Name:   name,
		Row:    attrs,
		Writer: o,
	}

	return &tc
}

// =======================================================

type RowEncodingJob struct {
	Context *TableContext
}

type RowEncodingResult struct {
	Data []byte
}

func EncodeRowWorker(i int, table string, options EncodingOptions,
	jobs <-chan RowEncodingJob, results chan<- RowEncodingResult,
	wg *sync.WaitGroup) {

	defer wg.Done()
	//log.Println("starting worker ", i, table)

	for job := range jobs {
		//log.Println((*job.Context.Row)["XObjectKey"])
		buf, err := EncodeRow(job.Context, options)
		if err != nil {
			log.Println(err)
		}
		results <- RowEncodingResult{Data: buf}
	}
	//log.Println("worker done ", i, table)

}

func EncodeRowResultCollector(table string, results <-chan RowEncodingResult, o io.Writer, wg *sync.WaitGroup) {
	defer wg.Done()
	//log.Println("starting collector ", table)
	for result := range results {
		o.Write(result.Data)
	}
	//log.Println("collector done ", table)
}

func EncodeRow(context *TableContext, options EncodingOptions) ([]byte, error) {

	// create buffered encoder for current row's XML output
	var b = bytes.NewBuffer(make([]byte, 0, 1000))
	var writer = bufio.NewWriter(b)

	e := xml.NewEncoder(writer)

	// start elem, with attrs
	var attrs []xml.Attr
	if options.F_Attrs != nil {
		var err error
		attrs, err = options.F_Attrs(context)
		if err != nil {
			return nil, err
		}
	}
	elem := xml.StartElement{
		Name: xml.Name{Local: context.Name},
		Attr: attrs,
	}
	e.EncodeToken(elem)

	if !options.NoContent {

		// generate Property elements for each DB column

		// create a Properties parent, if there will be additional content
		propElem := elem
		if options.F_Content != nil {
			propElemName := (context.Name + "Properties")
			propElem = xml.StartElement{Name: xml.Name{Local: propElemName}}
			e.EncodeToken(propElem)
		}

		err := encodeRowProperties(context, e, options)
		if err != nil {
			return nil, err
		}

		if options.F_Content != nil {
			e.EncodeToken(propElem.End())
			e.Flush()
		}
	}

	// generate embedded content
	if options.F_Content != nil {
		var childContext = TableContext{DBContext: context.DBContext,
			Name:   context.Name,
			Row:    context.Row,
			Writer: writer}
		options.F_Content(&childContext)
	}

	e.EncodeToken(elem.End())
	e.Flush()

	writer.Flush()

	return b.Bytes(), nil
}

// iterate properties of row, create XML Property element for each
func encodeRowProperties(context *TableContext, e *xml.Encoder, options EncodingOptions) error {

	keys := make([]string, 0, len(*context.Row))
	for k := range *context.Row {
		keys = append(keys, k)
	}
	if !options.NoAttributeSort {
		sort.Strings(keys)
	}

	for _, key := range keys {

		val := (*context.Row)[key]

		if (options.ExcludeAttrs == nil || !slices.Contains(options.ExcludeAttrs, key)) &&
			(val != nil || !options.SkipEmpty) {

			// add Property element for attribute
			pElem := xml.StartElement{
				Name: xml.Name{Local: "Property"},
				Attr: []xml.Attr{{Name: xml.Name{Local: "Field"}, Value: key}},
			}
			if err := e.EncodeElement(val, pElem); err != nil {
				return err
			}
		}
	}

	return nil
}

func EncodeTable(tableName string,
	db *sqlx.DB, rows *sqlx.Rows,
	o io.Writer,
	options EncodingOptions) error {

	defer rows.Close()

	max_workers := 8
	if options.MaxWorkers > 0 {
		max_workers = options.MaxWorkers
	}

	// simple case of singleton
	if options.IsSingleton {
		return encodeTable_Singleton(tableName, db, rows, o, options)
	} else if max_workers == 1 {
		// single thread
		return encodeTable_SingleThread(tableName, db, rows, o, options)
	}

	// use multiple threads for encoding of n rows...

	// create encoder XML output
	e := xml.NewEncoder(o)

	elem := xml.StartElement{
		Name: xml.Name{Local: options.getPluralName(tableName)},
	}
	e.EncodeToken(elem)
	e.Flush()

	// channels for jobs/results
	jobs := make(chan RowEncodingJob)
	results := make(chan RowEncodingResult)

	// create row processors
	var wg sync.WaitGroup
	wg.Add(max_workers)
	for w := 1; w <= max_workers; w++ {
		go EncodeRowWorker(w, tableName, options, jobs, results, &wg)
	}

	var cwg sync.WaitGroup
	cwg.Add(1)
	go EncodeRowResultCollector(tableName, results, o, &cwg)

	for rows.Next() {

		buf := make(map[string]interface{})
		err := rows.MapScan(buf)
		if err != nil {
			log.Println(err)
			return err
		}

		t_context := TableContext{DBContext: db, Name: tableName, Row: &buf, Writer: o}

		// if caller provided a filter function, apply it
		f_checkRow := options.PostFilter
		if f_checkRow == nil {
			f_checkRow = func(c *TableContext) bool { return true }
		}
		if f_checkRow(&t_context) {
			jobs <- RowEncodingJob{Context: &t_context}
		}
	}
	close(jobs)
	wg.Wait()
	close(results)
	cwg.Wait()

	e.EncodeToken(elem.End())
	e.Flush()

	return nil
}

func encodeTable_SingleThread(tableName string,
	db *sqlx.DB, rows *sqlx.Rows,
	o io.Writer,
	options EncodingOptions) error {

	// create encoder XML output
	e := xml.NewEncoder(o)

	elem := xml.StartElement{
		Name: xml.Name{Local: options.getPluralName(tableName)},
	}
	e.EncodeToken(elem)
	e.Flush()

	for rows.Next() {

		buf := make(map[string]interface{})
		err := rows.MapScan(buf)
		if err != nil {
			log.Println(err)
			return err
		}

		t_context := TableContext{DBContext: db, Name: tableName, Row: &buf, Writer: o}

		// if caller provided a filter function, apply it
		f_checkRow := options.PostFilter
		if f_checkRow == nil {
			f_checkRow = func(c *TableContext) bool { return true }
		}
		if f_checkRow(&t_context) {

			buf, err := EncodeRow(&t_context, options)
			if err != nil {
				log.Println(err)
			}
			o.Write(buf)
		}
	}

	e.EncodeToken(elem.End())
	e.Flush()

	return nil
}

func encodeTable_Singleton(tableName string,
	db *sqlx.DB, rows *sqlx.Rows,
	o io.Writer,
	options EncodingOptions) error {

	if rows.Next() {

		s_buf := make(map[string]interface{})
		s_err := rows.MapScan(s_buf)
		if s_err != nil {
			log.Println(s_err)
			return s_err
		}

		s_context := TableContext{DBContext: db, Name: tableName, Row: &s_buf, Writer: o}
		s_bytes, e_err := EncodeRow(&s_context, options)
		if e_err != nil {
			log.Println(e_err)
			return e_err
		}
		o.Write(s_bytes)
	}
	return nil
}

func EncodeRelatedTable(context *TableContext,
	sqlName string, whereClause string,
	xmlName string,
	options EncodingOptions) error {
	return EncodeMatchingRows(context.DBContext, sqlName, whereClause, xmlName, context.Writer, options.singleThread())
}

func EncodeMatchingRows(db *sqlx.DB,
	sqlName string, whereClause string,
	xmlName string, o io.Writer,
	options EncodingOptions) error {

	//log.Println(whereClause)

	rows, err := dbx.GetTableRows(db, sqlName, whereClause)
	if err != nil {
		log.Println(err)
		return err
	}

	return EncodeTable(xmlName, db, rows, o, options)
}

func EncodeSingletonTable(db *sqlx.DB,
	sqlName string, whereClause string,
	xmlName string, o io.Writer,
	options EncodingOptions) error {

	rows, err := dbx.GetTableRows(db, sqlName, whereClause)
	if err != nil {
		log.Println(err)
		return err
	}

	return EncodeTable(xmlName, db, rows, o, options)
}

func EncodeForeignSingleton(context *TableContext,
	sqlName string, keyAttr string,
	xmlName string,
	options EncodingOptions) error {

	o1 := options
	o1.IsSingleton = true
	return EncodeForeignTable(context, sqlName, keyAttr, xmlName, o1)
}

// include content from table with matching UID, column name and column value
func EncodeForeignTable(context *TableContext,
	sqlName string, sharedColumn string, tableName string,
	options EncodingOptions) error {
	var tableId = (*context.Row)[sharedColumn]
	var whereClause = fmt.Sprintf("%s = '%s'", sharedColumn, tableId)
	return EncodeMatchingRows(context.DBContext, sqlName, whereClause, tableName, context.Writer, options.singleThread())
}

// include content from table with matching UID, different column name
func EncodeChildTable(context *TableContext,
	sqlName string, column string, foreignColumn string, tableName string,
	options EncodingOptions) error {
	var tableId = (*context.Row)[column]
	var whereClause = fmt.Sprintf("%s = '%s'", foreignColumn, tableId)
	return EncodeMatchingRows(context.DBContext, sqlName, whereClause, tableName, context.Writer, options.singleThread())
}

// include content from assignment table, via m-to-n table
func EncodeMNTable(context *TableContext,
	homeTableColumn string, assignmentTableName string, targetTableName string, targetColumn string,
	xmlName string,
	options EncodingOptions) error {

	homeTableId := (*context.Row)[homeTableColumn]
	wc := fmt.Sprintf("%[3]s in (select %[3]s from %[2]s where %[1]s = '%[4]s')", homeTableColumn, assignmentTableName, targetColumn, homeTableId)

	return EncodeMatchingRows(context.DBContext, targetTableName, wc, xmlName, context.Writer, options.singleThread())
}

// use given map of attribute name to DB column name, to create slice of xml attrs
func MakeXMLAttrs(row *map[string]interface{}, names map[string]string) ([]xml.Attr, error) {

	var attrs []xml.Attr
	attrs = make([]xml.Attr, len(names))
	for k, v := range names {

		// get named value from row
		rval, ok := (*row)[v]
		if ok && rval != nil {
			attrs = append(attrs, makeXmlAttr(k, rval))
		}
	}
	return attrs, nil
}

func MakeXMLAttrsFromMap(m map[string]string) ([]xml.Attr, error) {

	var attrs []xml.Attr
	attrs = make([]xml.Attr, len(m))
	for k, v := range m {
		attrs = append(attrs, makeXmlAttr(k, v))
	}
	return attrs, nil

}

func makeXmlAttr(name string, val interface{}) xml.Attr {
	var attr xml.Attr
	n := xml.Name{Local: cleanXMLAttrName(name)}
	if val != nil {

		/*
		   var encodedVal string

		   // override the default string representation of bool
		   switch v := val.(type) {
		   case bool:
		       // v is a string here, so e.g. v + " Yeah!" is possible.
		       encodedVal =
		   default:
		       // And here I'm feeling dumb. ;)
		       fmt.Printf("I don't know, ask stackoverflow.")
		   }
		*/

		//return xml.Attr {Name: n, Value: fmt.Sprintf("%s", val) }
		return xml.Attr{Name: n, Value: fmt.Sprintf("%v", val)}
	}
	return attr
}

func cleanXMLAttrName(name string) string {

	re := regexp.MustCompile(`[^A-Za-z_.-]`)
	return string(re.ReplaceAll([]byte(name), nil))

}

func EncodeReference(context *TableContext,
	table string, whereClause string,
	xmlName string,
	options ...EncodingOptions) error {

	singleton_options := getNonNullOptions(options)
	singleton_options.IsSingleton = true
	return EncodeSingletonTable(context.DBContext,
		table, whereClause,
		xmlName,
		context.Writer,
		singleton_options)
}

// encode object via XObjectKey reference
func EncodeReferenceObjectKey(context *TableContext,
	objectKey string,
	xmlName string,
	options ...EncodingOptions) error {

	opt := getNonNullOptions(options)

	if opt.SkipEmpty {
		if len(objectKey) == 0 {
			return nil
		}
	}

	t, ids := oneim.GetKeyParts(objectKey)

	// add table name, object name to xml attributes
	if opt.F_Attrs == nil {
		// create placeholder fn
		opt.F_Attrs = func(c *TableContext) ([]xml.Attr, error) {
			return []xml.Attr{}, nil
		}
	}
	f_old := opt.F_Attrs
	opt.F_Attrs = func(c *TableContext) ([]xml.Attr, error) {
		attrs, err := f_old(c)
		if err == nil {
			// table name
			attrs_new := AddXmlAttribute(attrs, "table", t)

			// UID
			if len(ids) == 1 {
				attrs_new = AddXmlAttribute(attrs_new, "id", ids[0])
			}

			// Ident_<table name>
			name_attr := "Ident_" + cleanXMLAttrName(t)
			name_val := (*c.Row)[name_attr]
			attrs_new = AddXmlAttribute(attrs_new, "name", name_val)

			// <table name>Name
			name_attr_2 := cleanXMLAttrName(t) + "Name"
			name_val_2 := (*c.Row)[name_attr_2]
			attrs_new = AddXmlAttribute(attrs_new, "name", name_val_2)

			// display name
			dname_val := (*c.Row)["DisplayName"]
			attrs_new = AddXmlAttribute(attrs_new, "name", dname_val)

			// key
			attrs_new = AddXmlAttribute(attrs_new, "XObjectKey", objectKey)

			// TODO: M-N table keys / display name

			return attrs_new, nil
		} else {
			return nil, err
		}
	}

	return EncodeReference(context,
		t, fmt.Sprintf("XObjectKey = '%s'", objectKey),
		xmlName,
		opt)
}

func AddXmlAttribute(attrs []xml.Attr, name string, value interface{}) []xml.Attr {

	// skip empty attrs
	if value == nil {
		return attrs
	}

	// is there already an attr with this name
	existing_attr := slices.IndexFunc(attrs, func(a xml.Attr) bool {
		return name == a.Name.Local
	})
	if existing_attr < 0 {
		new_attr := xml.Attr{
			Name:  xml.Name{Local: cleanXMLAttrName(name)},
			Value: fmt.Sprintf("%v", value),
		}
		return append(attrs, new_attr)
	}

	return attrs
}

// encode object via FK reference, key column name is same in both tables
func EncodeFKReference(context *TableContext,
	table string, keyAttr string,
	xmlName string,
	options ...EncodingOptions) error {

	opt := getNonNullOptions(options)
	wc, err := dbx.GetFKWC(context.Row, keyAttr)
	if err != nil {
		return err
	} else if len(wc) == 0 {
		if opt.SkipEmpty {
			return nil
		} else {
			return errors.New("failed to generate where clause for foreign key reference " + keyAttr)
		}
	}

	return EncodeReference(context, table, wc, xmlName, opt)
}

// encode object via FK reference, key column names are different
func EncodeCRReference(context *TableContext,
	table string, keyAttr string, crAttr string,
	xmlName string,
	options EncodingOptions) error {

	wc, err := dbx.GetCRWC(crAttr, context.Row, keyAttr)
	if err != nil {
		return err
	} else if len(wc) == 0 {
		if options.SkipEmpty {
			return nil
		} else {
			return errors.New("failed to generate where clause for child key reference " + keyAttr + ", " + crAttr)
		}
	}

	return EncodeReference(context, table, wc, xmlName, options)
}

func EncodeRowCount(context *TableContext,
	table string, whereClause string,
	xmlName string,
	options ...EncodingOptions) error {

	opt := getNonNullOptions(options)

	// create encoder XML output
	e := xml.NewEncoder(context.Writer)

	elem := xml.StartElement{
		Name: xml.Name{Local: opt.getPluralName(xmlName)},
	}

	count, err := dbx.GetTableCount(context.DBContext, table, whereClause)
	if err = e.EncodeElement(count, elem); err != nil {
		return err
	}
	e.EncodeToken(elem.End())

	e.Flush()

	return nil
}

func EncodeRowAttribute(context *TableContext, attr string, options ...EncodingOptions) error {

	return EncodeAttribute(context.Writer, attr, context.GetStringVal(attr), getNonNullOptions(options))

}

func EncodeAttribute(o io.Writer, attr string, val string, options ...EncodingOptions) error {

	opt := getNonNullOptions(options)
	if len(val) > 0 || !opt.SkipEmpty {

		if opt.RawXML {
			// write raw content to element, removing xml declaration if present
			rawContent := strings.Replace(val, `<?xml version="1.0" encoding="utf-8"?>`, "", 1)
			o.Write([]byte(fmt.Sprintf("<%s>%s</%s>", attr, rawContent, attr)))
		} else {

			e := xml.NewEncoder(o)
			elem := xml.StartElement{
				Name: xml.Name{Local: attr},
			}

			if err := e.EncodeElement(val, elem); err != nil {
				return err
			}

			e.EncodeToken(elem.End())
			e.Flush()
		}
	}

	return nil
}

func EncodeRawAttribute(context *TableContext, attr string, options ...EncodingOptions) error {
	opt := getNonNullOptions(options)
	val := context.GetStringVal(attr)
	if len(val) > 0 || !opt.SkipEmpty {
		// TODO: xml encoding?
		context.Writer.Write([]byte(fmt.Sprintf("%s", val)))
	}
	return nil
}

func EncodeValueAsElement(o io.Writer, xmlName string, val string, options EncodingOptions) error {

	// create encoder XML output
	e := xml.NewEncoder(o)

	elem := xml.StartElement{
		Name: xml.Name{Local: xmlName},
	}

	e.EncodeElement(val, elem)
	e.EncodeToken(elem.End())

	e.Flush()

	return nil
}

func EncodeValuesAsElements(o io.Writer, xmlName string, values []string, options EncodingOptions) error {

	// create encoder XML output
	e := xml.NewEncoder(o)

	pElem := xml.StartElement{
		Name: xml.Name{Local: options.getPluralName(xmlName)},
	}
	e.EncodeToken(pElem)
	e.Flush()

	for _, v := range values {
		EncodeValueAsElement(o, xmlName, v, options)
	}

	e.EncodeToken(pElem.End())
	e.Flush()

	return nil
}

func GetColumnValue(context *TableContext, tableName string, whereClause string, columnName string) (string, error) {
	rows, err := dbx.GetTableRows(context.DBContext, tableName, whereClause)
	if err != nil {
		log.Println(err)
		return "", err
	}

	if rows.Next() {
		s_buf := make(map[string]interface{})
		s_err := rows.MapScan(s_buf)
		if s_err != nil {
			log.Println(s_err)
			return "", s_err
		}

		objKey := s_buf[columnName]
		if objKey != nil {
			return fmt.Sprintf("%v", objKey), nil
		} else {
			return "", fmt.Errorf("%s not found in table %s", columnName, tableName)
		}

	}
	return "", fmt.Errorf("Zero %s rows matching %s", tableName, whereClause)
}
