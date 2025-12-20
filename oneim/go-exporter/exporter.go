package main

import (
	//    "database/sql"

	"flag"
	"fmt"
	"io"
	"log"
	"maps"
	"net/url"
	"os"
	"regexp"
	"slices"
	"strconv"
	"strings"
	"time"
	"unicode"

	//     "bufio"
	"encoding/xml"

	_ "net/http/pprof"

	"github.com/jmoiron/sqlx"
	_ "github.com/microsoft/go-mssqldb"

	"pso.oneidentity.com/oneim"
	"pso.oneidentity.com/oneim/dbx"
	"pso.oneidentity.com/oneim/exml"
)

var db *sqlx.DB

var EXPORTER_VERSION = "0.91"

type ExporterConfig struct {
	DBConfig          dbx.DBConfig
	OneIMMajorVersion int
	OutFileName       string
	IsVerbose         bool
	MaxThreads        int
}

// convenience function to create attr generator for given XML name-to-DB name map
func makeAttrFn(m map[string]string, strAttrs ...[]string) func(*exml.TableContext) ([]xml.Attr, error) {

	m0 := maps.Clone(m)
	if m0 == nil {
		m0 = map[string]string{}
	}

	for _, v := range strAttrs {
		// make new map from list of strings
		for _, s := range v {
			m0[firstLetterToLower(s)] = s
		}
	}

	return func(c *exml.TableContext) ([]xml.Attr, error) {
		m1 := maps.Clone(m0)
		maps.Copy(m1, oneim.MAP_Metadata)
		return exml.MakeXMLAttrs(c.Row, m1)
	}
}

// returns function that creates attributes from given map and func
func makeAttrFn2(m map[string]string,
	attrFunc func(*exml.TableContext) (string, string, error),
) func(*exml.TableContext) ([]xml.Attr, error) {

	f1 := makeAttrFn(m)
	return func(c *exml.TableContext) ([]xml.Attr, error) {
		attrs, err := f1(c)
		if err != nil {
			return nil, err
		}

		attrName, attrVal, err := attrFunc(c)
		if err != nil {
			return nil, err
		}
		attrs = exml.AddXmlAttribute(attrs, attrName, attrVal)

		return attrs, nil
	}
}

func firstLetterToLower(s string) string {
	if len(s) == 0 {
		return s
	}

	r := []rune(s)
	r[0] = unicode.ToLower(r[0])

	return string(r)
}

func (c ExporterConfig) dbg(msg string) {
	if c.IsVerbose {
		fmt.Println(time.Now().Format(time.RFC3339) + ": " + msg)
	}
}

func main() {

	config := ExporterConfig{DBConfig: dbx.DBConfig{}}

	// Command line parameters
	flag.StringVar(&config.DBConfig.UserName, "user", "", "database user name")
	flag.StringVar(&config.DBConfig.Password, "password", "", "database password")
	flag.StringVar(&config.DBConfig.HostName, "host", "", "database host")
	flag.IntVar(&config.DBConfig.Port, "port", 1433, "database port")
	flag.StringVar(&config.DBConfig.DatabaseName, "database", "", "database name")
	flag.IntVar(&config.DBConfig.MaxConnections, "max-connections", 0, "max number of concurrent db connections")

	flag.IntVar(&config.OneIMMajorVersion, "majorVersion", 9, "Major version of OneIM")
	flag.BoolVar(&config.IsVerbose, "verbose", false, "Verbose output to stdout")
	flag.IntVar(&config.MaxThreads, "max-threads", 8, "Max threads to spawn for each encoding")

	flag.StringVar(&config.OutFileName, "file", "", "output file name")

	flag.Parse()

	/*
		go func() {
			log.Println(http.ListenAndServe("localhost:6060", nil))
		}()
	*/

	StartExporter(config)
}

func StartExporter(config ExporterConfig) {

	// setup DB connection
	db1, err := dbx.CreateCtxFromStruct(&config.DBConfig)
	defer db1.Close()
	if err != nil {
		log.Fatal(err)
	}

	// test connection
	pingErr := db1.Ping()
	if pingErr != nil {
		log.Fatal(pingErr)
	}

	// create io stream for output
	xmlFile, err := os.Create(config.OutFileName)
	if err != nil {
		fmt.Println("Error creating XML file: ", err)
		return
	}
	defer xmlFile.Close()

	encodeOneIMAsXML(config, db1, xmlFile)

}

func encodeOneIMAsXML(config ExporterConfig, db *sqlx.DB, o io.Writer) error {

	io.WriteString(o, xml.Header)

	// get instance basics
	im, _ := dbx.GetBufferedTableData(db, "DialogDatabase", "1=1", 1)

	instanceAttrs := fmt.Sprintf(`name="%s" version="%s" exporterVersion="%s" date="%s"`,
		im[0]["CustomerName"],
		im[0]["EditionVersion"],
		EXPORTER_VERSION,
		time.Now().Format(time.RFC3339))
	io.WriteString(o, fmt.Sprintf("<IdentityManager %s>", instanceAttrs))

	encodePrimaryDB(config, db, o)
	encodeServers(config, db, o)
	encodePasswordPolicies(config, db, o)
	encodeSystemUsers(config, db, o)
	encodeConfigParameters(config, db, o)
	encodeStructures(config, db, o)
	encodeRoles(config, db, o, "AERole", "1=1", "ApplicationRole", "UID_AERole", "Ident_AERole", "PersonInAERole")
	encodeRoleClasses(config, db, o)
	encodeAccountDefinitions(config, db, o)

	encodeApprovalPolicies(config, db, o)
	encodeApprovalWorkflows(config, db, o)
	encodeApprovalRules(config, db, o)
	encodeSchedules(config, db, o)
	encodeITShops(config, db, o)
	encodeITShopCatalog(config, db, o)
	encodeAttestationPolicies(config, db, o)
	encodeAttestationProcedures(config, db, o)
	encodeComplianceRules(config, db, o)

	encodeTargetSystems(config, db, o)
	encodeSynchronizationProjects(config, db, o)

	encodeWebApps(config, db, o)

	encodeSchema(config, db, o)
	encodeProcesses(config, db, o)

	encodeScripts(config, db, o)

	encodeMailTemplates(config, db, o)

	encodeLimitedSQL(config, db, o)

	encodeChangeLabels(config, db, o)

	// legacy web projects
	encodeWebDesignerObjects(config, db, "AP", "WDProject", o)
	encodeWebDesignerObjects(config, db, "CO", "WDModule", o)
	encodeWebDesignerObjects(config, db, "CC", "WDComponent", o)
	encodeWebDesignerObjects(config, db, "LY", "WDLayout", o)
	encodeWebDesignerObjects(config, db, "CF", "WDConfig", o)
	encodeWebDesignerObjects(config, db, "PA", "WDFormTmpl", o)

	io.WriteString(o, "</IdentityManager>")

	config.dbg("done")

	return nil
}

// -------------------------------------

func encodeObjectKeyReferenceSimple(c *exml.TableContext, keyAttr string, xmlName string) {
	encodeObjectKeyReference(c, keyAttr, xmlName, nil)
}
func encodeObjectKeyReference(c *exml.TableContext, keyAttr string, xmlName string, attrs []string) {
	opts := exml.EncodingOptions{NoContent: true}
	if attrs != nil {
		opts.F_Attrs = makeAttrFn(nil, attrs)
	}

	keyVal := c.GetStringVal(keyAttr)
	if len(keyVal) > 0 {
		exml.EncodeReferenceObjectKey(c, keyVal, xmlName, opts)
	}
}

func encodeOrgReference(c *exml.TableContext, UID_Org string, xmlName string) {
	exml.EncodeCRReference(c,
		"BaseTree", UID_Org, "UID_Org",
		xmlName,
		exml.EncodingOptions{
			NoContent: true,
			F_Attrs:   stdOrgAttrs,
		},
	)
}
func encodePersonReference(c *exml.TableContext, UID_Person string, xmlName string) {
	exml.EncodeCRReference(c,
		"Person", UID_Person, "UID_Person",
		xmlName,
		exml.EncodingOptions{
			NoContent: true,
			SkipEmpty: true,
			F_Attrs: makeAttrFn(map[string]string{
				"id":       "UID_Person",
				"name":     "CentralAccount",
				"fullName": "InternalName",
			}),
		},
	)
}

func encodeScheduleReference(c *exml.TableContext, columnName string, xmlName string) {

	exml.EncodeCRReference(c,
		"DialogSchedule", columnName, "UID_DialogSchedule", xmlName,
		exml.EncodingOptions{
			NoContent: true,
			F_Attrs: makeAttrFn(map[string]string{
				"UID_DialogSchedule": "UID_DialogSchedule",
				"name":               "Name"}),
			F_Content: func(tz_c *exml.TableContext) {
				exml.EncodeForeignSingleton(tz_c,
					"DialogTimeZone", "UID_DialogTimeZone", "TimeZone",
					exml.EncodingOptions{
						NoContent: true,
						F_Attrs: makeAttrFn(map[string]string{
							"UID_DialogTimeZone": "UID_DialogTimeZone",
							"name":               "Ident_DialogTimeZone"}),
					},
				)
			},
		},
	)
}

func encodeApprovalPolicyReference(c *exml.TableContext) {
	exml.EncodeFKReference(c,
		"PWODecisionMethod", "UID_PWODecisionMethod", "ApprovalPolicy",
		exml.EncodingOptions{
			NoContent: true,
			F_Attrs: makeAttrFn(map[string]string{
				"id":    "UID_PWODecisionMethod",
				"name":  "Ident_PWODecisionMethod",
				"usage": "UsageArea"}),
			F_Content: encodeApprovalPolicyContent,
		},
	)
}

func encodeTableReference(c *exml.TableContext, UID_DialogTable string, xmlName string) {

	exml.EncodeCRReference(c,
		"DialogTable", UID_DialogTable, "UID_DialogTable",
		xmlName,
		exml.EncodingOptions{
			NoContent: true,
			F_Attrs: makeAttrFn(map[string]string{
				"UID_DialogTable": "UID_DialogTable",
				"name":            "TableName",
			}),
		},
	)

}

func encodeColumnReferenceSimple(c *exml.TableContext) {
	encodeColumnReference(c, "UID_DialogColumn", "Column")
}
func encodeColumnReference(c *exml.TableContext, UID_DialogColumn string, xmlName string) {

	exml.EncodeCRReference(c,
		"DialogColumn", UID_DialogColumn, "UID_DialogColumn",
		xmlName,
		exml.EncodingOptions{
			NoContent: true,
			F_Attrs: makeAttrFn(map[string]string{
				"UID_DialogColumn": "UID_DialogColumn",
				"name":             "ColumnName",
				"table":            "UID_DialogTable",
				"caption":          "Caption",
			}),
			F_Content: func(col_c *exml.TableContext) {
				encodeTableReference(col_c, "UID_DialogTable", "Table")
			},
		},
	)
}

func encodeObjectPatches(c *exml.TableContext) {

	wc := fmt.Sprintf(`ObjectKeyOfRow = '%s'`, c.GetStringVal("XObjectKey"))
	exml.EncodeRelatedTable(c, "QBMBufferConfig", wc,
		"Patch",
		exml.EncodingOptions{
			NoContent:        true,
			PluralObjectName: "Patches",
			F_Attrs: makeAttrFn(
				map[string]string{"id": "UID_QBMBufferConfig"},
				[]string{"ColumnName", "HasContentFull"},
			),
			F_Content: func(p_c *exml.TableContext) {
				exml.EncodeRowAttribute(p_c, "ContentShort")
				exml.EncodeRowAttribute(p_c, "ContentFull")
			},
		},
	)
}

func encodeJobReferenceS(c *exml.TableContext, ParentAttr string, xmlName string) {
	encodeJobReference(c, ParentAttr, "UID_Job", xmlName)
}
func encodeJobReference(c *exml.TableContext, ParentAttr string, JobAttr string, xmlName string) {
	exml.EncodeCRReference(c,
		"Job", ParentAttr, JobAttr, xmlName,
		exml.EncodingOptions{
			NoContent: true,
			F_Attrs: makeAttrFn(
				map[string]string{"id": "UID_Job"},
				[]string{
					"Name",
					"Priority",
				},
			),
			F_Content: func(j_c *exml.TableContext) {
				exml.EncodeRowAttribute(j_c, "Description")
			},
		},
	)
}

// -------------------------------------

func encodePrimaryDB(config ExporterConfig, db *sqlx.DB, o io.Writer) error {

	config.dbg("DialogDatabase")
	exml.EncodeSingletonTable(db, "DialogDatabase", "1=1", "PrimaryDatabase", o,
		exml.EncodingOptions{
			NoContent:   true,
			IsSingleton: true,
			F_Attrs: func(pdb_context *exml.TableContext) ([]xml.Attr, error) {
				baseAttrs, _ := exml.MakeXMLAttrs(pdb_context.Row, oneim.MAP_Metadata)

				connString := pdb_context.GetStringVal("ConnectionString")
				csMap := dbx.DecodeConnectionString(connString)
				// remove password
				delete(csMap, "Password")
				connAttrs, _ := exml.MakeXMLAttrsFromMap(csMap)

				return slices.Concat(baseAttrs, connAttrs), nil
			},
		})

	return nil
}

func encodePasswordPolicies(config ExporterConfig, db *sqlx.DB, o io.Writer) error {

	rows, err := dbx.GetAllTableRows(db, "QBMPwdPolicy")
	if err != nil {
		return err
	}

	return exml.EncodeTable("PasswordPolicy", db, rows, o,
		exml.EncodingOptions{
			PluralObjectName: "PasswordPolicies",
			F_Attrs: makeAttrFn(map[string]string{"id": "UID_QBMPwdPolicy",
				"name":      "DisplayName",
				"isDefault": "IsDefault"}),
			F_Content: func(pp_context *exml.TableContext) {
				// owner
				exml.EncodeCRReference(pp_context,
					"AERole", "UID_AERoleOwner", "UID_AERole",
					"OwnerRole",
					exml.EncodingOptions{
						NoContent: true,
						F_Attrs: makeAttrFn(map[string]string{"id": "UID_AERole",
							"name":     "Ident_AERole",
							"fullPath": "FullPath"}),
					},
				)

				// object assignments
				exml.EncodeForeignTable(pp_context,
					"QBMObjectHasPwdPolicy", "UID_QBMPwdPolicy", "MappedObject",
					exml.EncodingOptions{
						NoContent: true,
						F_Content: encodePasswordPolicyObjectAssignments,
					},
				)
			},
		},
	)
}

// for QBMObjectHasPwdPolicy
func encodePasswordPolicyObjectAssignments(mo_context *exml.TableContext) {
	encodeObjectKeyReferenceSimple(mo_context, "ObjectKeyElement", "AssignedObject")
	encodeColumnReferenceSimple(mo_context)
}

func encodeSystemUsers(config ExporterConfig, db *sqlx.DB, o io.Writer) error {

	config.dbg("DialogUser")
	rows, err := dbx.GetAllTableRows(db, "DialogUser")
	if err != nil {
		return err
	}

	return exml.EncodeTable("Administrator", db, rows, o,
		exml.EncodingOptions{
			F_Attrs: makeAttrFn(map[string]string{
				"id":               "UID_DialogUser",
				"name":             "UserName",
				"lastLogin":        "LastLogin",
				"isAdmin":          "IsAdmin",
				"passwordLastSet":  "PasswordLastSet",
				"passwordNoExpire": "PasswordNeverExpires",
			}),
		},
	)
}

func encodeStructures(config ExporterConfig, db *sqlx.DB, o io.Writer) error {

	config.dbg("Department, Locality, ProfitCenter")
	encodeOneStructure(config, db, o, "Department", "DepartmentName", "Department")
	encodeOneStructure(config, db, o, "Locality", "Ident_locality", "Location")
	encodeOneStructure(config, db, o, "ProfitCenter", "AccountNumber", "CostCenter")

	return nil
}

func encodeOneStructure(config ExporterConfig, db *sqlx.DB, o io.Writer,
	table string, nameAttribute string, xmlName string) error {

	keyAttr := "UID_" + table
	return encodeRoles(config, db, o,
		table, "1=1", xmlName, keyAttr, nameAttribute, "PersonIn"+table,
		func(d_c *exml.TableContext) {
			wc := fmt.Sprintf(`%s = '%s'`, keyAttr, d_c.GetStringVal(keyAttr))
			exml.EncodeMatchingRows(d_c.DBContext, "Person", wc,
				"PrimaryAssignment",
				d_c.Writer,
				exml.EncodingOptions{
					NoContent: true,
					SkipEmpty: true,
					F_Attrs: makeAttrFn(map[string]string{
						"id":       "UID_Person",
						"name":     "CentralAccount",
						"fullName": "InternalName",
					}),
				},
			)
		},
	)
}

func encodeRoles(config ExporterConfig, db *sqlx.DB, o io.Writer,
	roleTable string, whereClause string,
	xmlName string,
	idAttr string, nameAttr string,
	membershipTable string,
	childEncodings ...func(*exml.TableContext)) error {

	config.dbg("Role class: " + roleTable)
	rows, err := dbx.GetTableRows(db, roleTable, whereClause)
	if err != nil {
		return err
	}

	post_filter := func(c *exml.TableContext) bool {
		path := c.GetStringVal("FullPath")
		return !strings.HasPrefix(path, "Request & Fulfillment\\IT Shop\\Product owners")
	}

	return exml.EncodeTable(xmlName, db, rows, o,
		exml.EncodingOptions{
			PostFilter: post_filter,
			F_Attrs: makeAttrFn(map[string]string{
				"id":        idAttr,
				"name":      nameAttr,
				"shortName": "ShortName",
				"fullPath":  "FullPath"}),
			F_Content: func(role_c *exml.TableContext) {
				encodeRoleContent(config, role_c, idAttr, membershipTable)

				// invoke caller's functions, if any
				for _, f := range childEncodings {
					f(role_c)
				}
			},
		},
	)
}
func encodeRoleContent(config ExporterConfig, role_c *exml.TableContext, idAttr string, membershipTable string) {

	exml.EncodeRowAttribute(role_c, "Description")

	exml.EncodeCRReference(role_c,
		"AERole", "UID_AERoleManager", "UID_AERole", "ManagerRole",
		exml.EncodingOptions{
			NoContent: true,
			SkipEmpty: true,
			F_Attrs: makeAttrFn(map[string]string{
				"id":       "UID_AERole",
				"name":     "Ident_AERole",
				"fullPath": "FullPath"}),
		},
	)

	exml.EncodeCRReference(role_c,
		"Person", "UID_PersonHead", "UID_Person", "Manager",
		exml.EncodingOptions{
			NoContent: true,
			SkipEmpty: true,
			F_Attrs: makeAttrFn(map[string]string{
				"id":       "UID_Person",
				"name":     "CentralAccount",
				"fullName": "InternalName"}),
		},
	)

	exml.EncodeCRReference(role_c,
		"AERole", "UID_AERoleAttestator", "UID_AERole", "AttestorRole",
		exml.EncodingOptions{
			NoContent: true,
			SkipEmpty: true,
			F_Attrs: makeAttrFn(map[string]string{
				"id":       "UID_AERole",
				"name":     "Ident_AERole",
				"fullPath": "FullPath"}),
		},
	)

	// QERVBaseTreeHasElement is only available from v9 forward
	if config.OneIMMajorVersion >= 9 {
		exml.EncodeChildTable(role_c,
			"QERVBaseTreeHasElement", idAttr, "UID_Org", "ObjectAssignment",
			exml.EncodingOptions{
				NoContent: true,
				SkipEmpty: true,
				F_Attrs: makeAttrFn(map[string]string{
					"UID_Element": "UID_Element",
					"origin":      "InheritInfoOrigin"}),
				F_Content: func(ct_c *exml.TableContext) {
					exml.EncodeReferenceObjectKey(ct_c,
						ct_c.GetStringVal("ObjectKeyElement"),
						"AssignedObject",
						exml.EncodingOptions{
							SkipEmpty: true,
							// include all possible object name attributes...
							F_Attrs: makeAttrFn(map[string]string{
								"name":                  "DisplayName",
								"accountName":           "AccountName",
								"accountDefinitionName": "Ident_TSBAccountDef",
							}),
						},
					)
				},
			},
		)
	}

	// user export depends on number of assignments...
	wc, _ := dbx.GetFKWC(role_c.Row, idAttr)
	memberCount, _ := dbx.GetTableCount(role_c.DBContext, membershipTable, wc)
	if memberCount > 20 {
		exml.EncodeAttribute(role_c.Writer, "UserCount", strconv.Itoa(memberCount))
	} else {
		exml.EncodeForeignTable(role_c,
			membershipTable, idAttr, "UserAssignment",
			exml.EncodingOptions{
				NoContent: true,
				SkipEmpty: true,
				F_Attrs: makeAttrFn(map[string]string{
					"UID_Person": "UID_Person",
					"origin":     "XOrigin"}),
				F_Content: func(pir_c *exml.TableContext) {
					exml.EncodeFKReference(pir_c,
						"Person", "UID_Person", "Member",
						exml.EncodingOptions{
							NoContent: true,
							SkipEmpty: true,
							F_Attrs: makeAttrFn(map[string]string{
								"id":         "UID_Person",
								"name":       "CentralAccount",
								"fullName":   "InternalName",
								"isInActive": "IsInActive",
							}),
						},
					)
				},
			},
		)
	}

	encodeDynamicRoles(config, role_c, "objectKeyBaseTree")

	exml.EncodeChildTable(role_c,
		"TSBITData", idAttr, "UID_Org", "ITData",
		exml.EncodingOptions{
			SkipEmpty: true,
			NoContent: true,
			F_Attrs:   makeAttrFn(nil, []string{"FixValue", "DisplayValue"}),
			F_Content: func(itd_c *exml.TableContext) {
				encodeColumnReference(itd_c, "UID_DialogColumnTarget", "TargetColumn")
				encodeObjectKeyReference(itd_c, "ObjectKeyValue", "Value",
					[]string{"CanonicalName", "FQDN", "DisplayName"})
				encodeObjectKeyReference(itd_c, "ObjectKeyAppliesTo", "AppliesTo", []string{"FullPath"})
			},
		},
	)
}

func stdOrgAttrs(c *exml.TableContext) ([]xml.Attr, error) {
	attrs := map[string]string{
		"id":       "UID_Org",
		"name":     "Ident_Org",
		"fullPath": "FullPath",
	}
	maps.Copy(attrs, oneim.MAP_Metadata)
	return exml.MakeXMLAttrs(c.Row, attrs)
}

func encodeRoleClasses(config ExporterConfig, db *sqlx.DB, o io.Writer) error {
	rows, err := dbx.GetAllTableRows(db, "OrgRoot")
	if err != nil {
		return err
	}

	// filter OOTB role classes
	postFilter := func(c *exml.TableContext) bool {
		id := c.GetStringVal("UID_OrgRoot")
		r, _ := regexp.MatchString(`^...-`, id)
		return !r
	}
	return exml.EncodeTable("RoleClass", db, rows, o,
		exml.EncodingOptions{
			PluralObjectName: "RoleClasses",
			PostFilter:       postFilter,
			F_Attrs: makeAttrFn(map[string]string{
				"id":        "UID_OrgRoot",
				"name":      "Ident_OrgRoot",
				"isTopDown": "IsTopDown",
			}),
			F_Content: func(rc_c *exml.TableContext) {

				exml.EncodeForeignTable(rc_c,
					"OrgRootAssign", "UID_OrgRoot", "ClassAssignment",
					exml.EncodingOptions{
						NoContent: true,
						F_Attrs: makeAttrFn(map[string]string{
							"UID_BaseTreeAssign":    "UID_BaseTreeAssign",
							"allowAssignment":       "IsAssignmentAllowed",
							"allowDirectAssignment": "IsDirectAssignmentAllowed",
						}),
						F_Content: func(rc_c *exml.TableContext) {
							exml.EncodeFKReference(rc_c,
								"BaseTreeAssign", "UID_BaseTreeAssign", "Type",
								exml.EncodingOptions{
									NoContent: true,
									F_Attrs: makeAttrFn(map[string]string{
										"id":   "UID_BaseTreeAssign",
										"name": "DisplayNameElement"}),
								},
							)
						},
					},
				)

				whereClause := fmt.Sprintf(`UID_OrgRoot = '%s'`, rc_c.GetStringVal("UID_OrgRoot"))
				encodeRoles(config, rc_c.DBContext, rc_c.Writer,
					"Org", whereClause,
					"Role",
					"UID_Org", "Ident_Org",
					"PersonInOrg")
			},
		},
	)
}

func encodeConfigParameters(config ExporterConfig, db *sqlx.DB, o io.Writer) error {

	config.dbg("DialogConfigParm")
	rows, err := dbx.GetAllTableRows(db, "DialogConfigParm")
	if err != nil {
		return err
	}

	return exml.EncodeTable("ConfigParam", db, rows, o,
		exml.EncodingOptions{
			F_Attrs: makeAttrFn(map[string]string{
				"id":        "UID_ConfigParm",
				"name":      "ConfigParm",
				"enabled":   "Enabled",
				"fullPath":  "FullPath",
				"shortName": "ConfigParm"}),
		},
	)
}

func encodeDynamicRoles(config ExporterConfig, context *exml.TableContext, keyAttr string) error {

	return exml.EncodeChildTable(context,
		"DynamicGroup", "XObjectKey", keyAttr, "DynamicRole",
		exml.EncodingOptions{
			SkipEmpty: true,
			F_Attrs: makeAttrFn(map[string]string{
				"UID_DynamicGroup": "UID_DynamicGroup",
				"name":             "DisplayName"}),
			F_Content: func(dg_c *exml.TableContext) {
				encodeDynamicRoleContent(config, dg_c, keyAttr)
			},
		},
	)
}

func encodeDynamicRoleContent(config ExporterConfig, dg_c *exml.TableContext, keyAttr string) {

	exml.EncodeRowAttribute(dg_c, "Description")
	exml.EncodeRowAttribute(dg_c, "WhereClause")

	encodeTableReference(dg_c, "UID_DialogTableObjectClass", "ObjectClass")

	encodeScheduleReference(dg_c, "UID_DialogSchedule", "Schedule")

	if config.OneIMMajorVersion >= 9 {
		wc_col := fmt.Sprintf(
			`XObjectKey in (
				select ObjectKeyDialogColumn from DynamicGroupHasImmediateColumn 
				  where UID_DynamicGroup = '%s' and IsInActive = 0)`,
			dg_c.GetStringVal("UID_DynamicGroup"))
		exml.EncodeMatchingRows(dg_c.DBContext, "DialogColumn", wc_col,
			"RecalcProperty",
			dg_c.Writer,
			exml.EncodingOptions{
				PluralObjectName: "RecalcProperties",
				NoContent:        true,
				F_Attrs: makeAttrFn(map[string]string{
					"id":      "UID_DialogColumn",
					"name":    "ColumnName",
					"caption": "Caption",
					"table":   "UID_DialogTable",
				}),
			},
		)
	}

	if config.OneIMMajorVersion >= 9 {
		exml.EncodeForeignTable(dg_c,
			"QERDynamicGroupBlacklist", "UID_DynamicGroup", "Exclusion",
			exml.EncodingOptions{
				NoContent: true,
				F_Attrs: makeAttrFn(map[string]string{
					"isNotMatched":       "IsNotMatched",
					"isAssignedByOthers": "IsAssignedByOthers",
					"UID_Person":         "UID_Person",
				}),
				F_Content: func(ex_c *exml.TableContext) {
					exml.EncodeRowAttribute(ex_c, "Description")
					encodePersonReference(ex_c, "UID_Person", "Person")
				},
			},
		)
	}
}

func encodeServers(config ExporterConfig, db *sqlx.DB, o io.Writer) error {

	config.dbg("QBMServer")
	rows, err := dbx.GetAllTableRows(db, "QBMServer")
	if err != nil {
		return err
	}

	return exml.EncodeTable("Server", db, rows, o,
		exml.EncodingOptions{
			F_Attrs: makeAttrFn(map[string]string{
				"id":               "UID_QBMServer",
				"name":             "Ident_Server",
				"serviceInstalled": "IsQBMServiceInstalled",
				"physicalServer":   "PhysicalServerName",
				"queueName":        "QueueName",
				"FQDN":             "FQDN"}),
			F_Content: encodeServerContent,
		},
	)
}

func encodeServerContent(dt_c *exml.TableContext) {

	wc := fmt.Sprintf(`UID_QBMDeployTarget in (
								select UID_QBMDeployTarget from QBMServerHasDeployTarget
								where UID_QBMServer = '%s')`, dt_c.GetStringVal("UID_QBMServer"))
	exml.EncodeMatchingRows(dt_c.DBContext, "QBMDeployTarget", wc,
		"DeployTarget",
		dt_c.Writer,
		exml.EncodingOptions{
			NoContent: true,
			F_Attrs: makeAttrFn(map[string]string{
				"id":       "UID_QBMDeployTarget",
				"name":     "DisplayValue",
				"fullPath": "FullPath"}),
		},
	)

	wc = fmt.Sprintf(`UID_QBMServerTag in (
								select UID_QBMServerTag from QBMServerHasServerTag
								where UID_QBMServer = '%s')`, dt_c.GetStringVal("UID_QBMServer"))
	exml.EncodeMatchingRows(dt_c.DBContext, "QBMServerTag", wc,
		"ServerTag",
		dt_c.Writer,
		exml.EncodingOptions{
			NoContent: true,
			F_Attrs: makeAttrFn(map[string]string{
				"name":        "Ident_QBMServerTag",
				"description": "Description"}),
		},
	)

	exml.EncodeRawAttribute(dt_c, "JobserverConfiguration")
}

func encodeWebApps(config ExporterConfig, db *sqlx.DB, o io.Writer) error {

	config.dbg("QBMWebApplication")
	rows, err := dbx.GetAllTableRows(db, "QBMWebApplication")
	if err != nil {
		return err
	}

	return exml.EncodeTable("WebApp", db, rows, o,
		exml.EncodingOptions{
			F_Attrs: func(wa_c *exml.TableContext) ([]xml.Attr, error) {
				baseAttrs, _ := exml.MakeXMLAttrs(wa_c.Row, oneim.MAP_Metadata)

				id := wa_c.GetStringVal("UID_QBMWebApplication")
				baseURL := wa_c.GetStringVal("BaseURL")
				URL, _ := url.Parse(baseURL)
				urlMap := map[string]string{
					"id":     id,
					"name":   baseURL,
					"host":   URL.Host,
					"scheme": URL.Scheme,
					"path":   URL.Path,
				}
				urlAttrs, _ := exml.MakeXMLAttrsFromMap(urlMap)

				return slices.Concat(baseAttrs, urlAttrs), nil
			},
			F_Content: func(wa_c *exml.TableContext) {
				exml.EncodeFKReference(wa_c,
					"QBMProduct", "UID_DialogProduct", "AppType",
					exml.EncodingOptions{
						NoContent: true,
						F_Attrs: makeAttrFn(map[string]string{
							"id":   "UID_DialogProduct",
							"name": "Ident_Product"}),
					},
				)

				exml.EncodeCRReference(wa_c,
					"DialogAEDS", "UID_DialogAEDSWebProject", "UID_DialogAEDS",
					"WebProject",
					exml.EncodingOptions{
						NoContent: true,
						F_Attrs: makeAttrFn(map[string]string{
							"id":   "UID_DialogAEDS",
							"name": "FileName"}),
					},
				)

				exml.EncodeFKReference(wa_c,
					"DialogAuthentifier", "UID_DialogAuthentifier", "AuthenticationType",
					exml.EncodingOptions{
						NoContent: true,
						F_Attrs: makeAttrFn(map[string]string{
							"id":   "UID_DialogAuthentifier",
							"name": "Ident_DialogAuthentifier"}),
					},
				)

				exml.EncodeCRReference(wa_c,
					"DialogAuthentifier", "UID_DialogAuthSecondary", "UID_DialogAuthentifier",
					"SecondaryAuthenticationType",
					exml.EncodingOptions{
						NoContent: true,
						F_Attrs: makeAttrFn(map[string]string{
							"id":   "UID_DialogAuthentifier",
							"name": "Ident_DialogAuthentifier"}),
					},
				)

			},
		},
	)
}

// typical attrs for WD elements
func stdWDAttrs(c *exml.TableContext) ([]xml.Attr, error) {
	wdAttrs := map[string]string{"id": "UID_DialogAEDS", "name": "FileName",
		"type": "ObjectType", "subType": "SubObjectType",
		"description": "Description"}
	maps.Copy(wdAttrs, oneim.MAP_Metadata)
	return exml.MakeXMLAttrs(c.Row, wdAttrs)
}

func encodeWebDesignerObjects(config ExporterConfig, db *sqlx.DB, wdType string, xmlName string, o io.Writer) error {

	config.dbg("DialogAEDS: " + wdType)
	rows, err := dbx.GetTableRows(db, "DialogAEDS", fmt.Sprintf("ObjectType = '%s'", wdType))
	if err != nil {
		return err
	}

	exml.EncodeTable(xmlName, db, rows, o,
		exml.EncodingOptions{
			NoContent: true,
			F_Attrs:   stdWDAttrs,
			F_Content: func(wp_context *exml.TableContext) {
				exml.EncodeCRReference(wp_context,
					"DialogAEDS", "UID_DialogAEDSParent", "UID_DialogAEDS",
					"Parent",
					exml.EncodingOptions{
						NoContent: true,
						F_Attrs:   stdWDAttrs,
					},
				)
				wpOpts := exml.EncodingOptions{RawXML: true, SkipEmpty: true}
				exml.EncodeRowAttribute(wp_context, "Configuration", wpOpts)
				exml.EncodeRowAttribute(wp_context, "CustomConfiguration", wpOpts)
				exml.EncodeRowAttribute(wp_context, "CustomCode", wpOpts)

				exml.EncodeChildTable(wp_context,
					"QBMWebApplication", "UID_DialogAEDS", "UID_DialogAEDSWebProject",
					"WebApplication",
					exml.EncodingOptions{
						NoContent: true,
						F_Attrs: makeAttrFn(map[string]string{
							"id":  "UID_QBMWebApplication",
							"url": "BaseURL"}),
					},
				)

			},
		},
	)

	return nil
}

func encodeSchedules(config ExporterConfig, db *sqlx.DB, o io.Writer) error {

	config.dbg("DialogSchedule")
	rows, err := dbx.GetAllTableRows(db, "DialogSchedule")
	if err != nil {
		return err
	}

	return exml.EncodeTable("Schedule", db, rows, o,
		exml.EncodingOptions{
			F_Attrs: makeAttrFn(map[string]string{
				"id":                 "UID_DialogSchedule",
				"name":               "Name",
				"UID_DialogTimeZone": "UID_DialogTimeZone",
				"frequency":          "Frequency",
				"frequencyType":      "FrequencyType",
				"enabled":            "Enabled",
				"startDate":          "StartDate",
				"lastRun":            "LastRun",
				"nextRun":            "NextRun",
				"belongsTo":          "UID_DialogTableBelongsTo",
			}),
			F_Content: func(ds_c *exml.TableContext) {
				exml.EncodeFKReference(ds_c,
					"DialogTimeZone", "UID_DialogTimeZone", "TimeZone",
					exml.EncodingOptions{
						NoContent: true,
						F_Attrs: makeAttrFn(map[string]string{
							"id":               "UID_DialogTimeZone",
							"longName":         "Ident_DialogTimeZone",
							"name":             "ShortName",
							"UTCOffeset":       "UTCOffset",
							"currentUTCOffset": "CurrentUTCOffset",
						}),
					},
				)

				types := ds_c.GetStringVal("FrequencySubType")
				if len(types) > 0 {
					exml.EncodeValuesAsElements(
						ds_c.Writer,
						"Type",
						strings.Split(types, " "),
						exml.EncodingOptions{PluralObjectName: "SubTypes"})
				}

				times := ds_c.GetStringVal("StartTime")
				if len(times) > 0 {
					exml.EncodeValuesAsElements(
						ds_c.Writer,
						"T",
						strings.Split(times, " "),
						exml.EncodingOptions{PluralObjectName: "StartTimes"})
				}

			},
		},
	)
}

// ----- IT Shop ------------------------------------------------

func stdITShopAttrs(c *exml.TableContext) ([]xml.Attr, error) {
	attrs := map[string]string{
		"id":       "UID_ITShopOrg",
		"name":     "Ident_Org",
		"fullPath": "FullPath",
	}
	maps.Copy(attrs, oneim.MAP_Metadata)
	return exml.MakeXMLAttrs(c.Row, attrs)
}

func encodeITShops(config ExporterConfig, db *sqlx.DB, o io.Writer) error {

	config.dbg("ITShopOrg")

	// load all shopping centers into temp DB
	rows, err := dbx.GetTableRows(db, "ITShopOrg", "ITShopInfo = 'SC'")
	if err != nil {
		return err
	}
	tempDB, tableName, err := dbx.PopulateTempDBFromRows(rows)

	// add default shopping center
	defaultSC := map[string]string{
		"Ident_Org":     "DEFAULT",
		"FullPath":      "DEFAULT",
		"Description":   "Default Shopping Center",
		"ITShopInfo":    "SC",
		"UID_ITShopOrg": "",
	}
	_, err = dbx.InsertMap(tempDB, tableName, defaultSC)
	if err != nil {
		log.Println(err)
		return err
	}

	config.dbg("  ... temp DB created")

	return exml.EncodeMatchingRows(tempDB, tableName, "1=1", "ShoppingCenter", o,
		exml.EncodingOptions{
			F_Attrs: makeAttrFn(map[string]string{
				"id":       "UID_ITShopOrg",
				"name":     "Ident_Org",
				"fullPath": "FullPath",
			}),
			F_Content: func(sc_c *exml.TableContext) {
				// note that we need to fetch from the real DB, not the temp
				c := sc_c
				c.DBContext = db

				wc_shop := fmt.Sprintf(
					"isnull(UID_ParentITShopOrg, '') = '%s' and ITShopInfo = 'SH'", c.GetStringVal("UID_ITShopOrg"))
				exml.EncodeMatchingRows(c.DBContext,
					"ITShopOrg", wc_shop, "Shop",
					c.Writer,
					exml.EncodingOptions{
						F_Attrs: stdITShopAttrs,
						F_Content: func(sh_c *exml.TableContext) {
							encodeITShopShopContent(config, sh_c)
						},
					},
				)

			},
		},
	)
}

func encodeITShopShopContent(config ExporterConfig, c *exml.TableContext) {

	config.dbg("IT Shop content")

	// generic ITShopOrg content
	encodeITShopOrgContent(c)

	// Shelf objects
	config.dbg(" Shelf")
	wc_shelf := fmt.Sprintf(
		"isnull(UID_ParentITShopOrg, '') = '%s' and ITShopInfo = 'BO'", c.GetStringVal("UID_ITShopOrg"))
	exml.EncodeMatchingRows(c.DBContext,
		"ITShopOrg", wc_shelf, "Shelf",
		c.Writer,
		exml.EncodingOptions{
			PluralObjectName: "Shelves",
			F_Attrs:          stdITShopAttrs,
			F_Content: func(bo_c *exml.TableContext) {
				encodeITShopOrgContent(bo_c)

				wc_product := fmt.Sprintf(
					"isnull(UID_ParentITShopOrg, '') = '%s' and ITShopInfo = 'PR'", bo_c.GetStringVal("UID_ITShopOrg"))
				config.dbg("  Products: " + bo_c.GetStringVal("UID_ITShopOrg"))
				exml.EncodeMatchingRows(bo_c.DBContext,
					"ITShopOrg", wc_product, "Product",
					bo_c.Writer,
					exml.EncodingOptions{
						F_Attrs: stdITShopAttrs,
						F_Content: func(product_c *exml.TableContext) {
							encodeITShopProductContent(config, product_c)
						},
					},
				)

			},
		},
	)

	// customer node(s)
	config.dbg(" Customer")
	wc_cust := fmt.Sprintf(
		"isnull(UID_ParentITShopOrg, '') = '%s' and ITShopInfo = 'CU'", c.GetStringVal("UID_ITShopOrg"))
	exml.EncodeMatchingRows(c.DBContext,
		"ITShopOrg", wc_cust, "Customer",
		c.Writer,
		exml.EncodingOptions{
			NoContent: true,
			F_Attrs:   stdITShopAttrs,
			F_Content: func(cust_c *exml.TableContext) {
				encodeITShopOrgContent(cust_c)
				encodeRoleContent(config, cust_c, "UID_ITShopOrg", "PersonInITShopOrg")
			},
		},
	)
}

func encodeITShopProductContent(config ExporterConfig, c *exml.TableContext) {
	encodeITShopOrgContent(c)

	if config.OneIMMajorVersion >= 9 {
		// entitlement assigned to product
		wc_ent := fmt.Sprintf("UID_Org = '%s'", c.GetStringVal("UID_ITShopOrg"))
		objKey, err := exml.GetColumnValue(c, "QERVBaseTreeHasElement", wc_ent, "ObjectKeyElement")
		if err != nil {
			log.Println(err)
		} else if len(objKey) > 0 {
			exml.EncodeReferenceObjectKey(c, objKey, "Entitlement",
				exml.EncodingOptions{
					NoContent: true,
					F_Attrs: makeAttrFn(map[string]string{
						"inheritInfoOrigin": "InheritInfoOrigin",
					}),
				},
			)
		}
	}

	// count of requests
	wc_pwo := fmt.Sprintf("UID_ITShopOrgFinal = '%s'", c.GetStringVal("UID_ITShopOrg"))
	exml.EncodeRowCount(c, "PersonWantsOrg", wc_pwo, "Request")
}

func encodeITShopOrgContent(c *exml.TableContext) {
	exml.EncodeRowAttribute(c, "Description")

	encodePersonReference(c, "UID_PersonHead", "Owner")
	encodeOrgReference(c, "UID_OrgRuler", "OwnerRole")
	encodeOrgReference(c, "UID_OrgAttestator", "Attestor")

	exml.EncodeMNTable(c,
		"UID_ITShopOrg", "ITShopOrgHasPWODecisionMethod", "PWODecisionMethod", "UID_PWODecisionMethod",
		"ApprovalPolicy",
		exml.EncodingOptions{
			PluralObjectName: "ApprovalPolicies",
			NoContent:        true,
			F_Attrs: makeAttrFn(map[string]string{
				"id":    "UID_PWODecisionMethod",
				"name":  "Ident_PWODecisionMethod",
				"usage": "UsageArea"}),
			F_Content: encodeApprovalPolicyContent,
		},
	)
}

func encodeITShopCatalog(config ExporterConfig, db *sqlx.DB, o io.Writer) error {

	rows, err := dbx.GetAllTableRows(db, "AccProductGroup")
	if err != nil {
		return err
	}

	return exml.EncodeTable("CatalogGroup", db, rows, o,
		exml.EncodingOptions{
			F_Attrs: makeAttrFn(map[string]string{
				"id":            "UID_AccProductGroup",
				"name":          "Ident_AccProductGroup",
				"fullPath":      "FullPath",
				"isSpecial":     "IsSpecial",
				"isSNOWEnabled": "IsServiceNowEnabled",
			}),
			F_Content: func(pg_c *exml.TableContext) {

				exml.EncodeRowAttribute(pg_c, "Description")
				exml.EncodeRowAttribute(pg_c, "Remarks")
				encodeOrgReference(pg_c, "UID_OrgRuler", "Owner")
				encodeOrgReference(pg_c, "UID_OrgAttestator", "Attestor")

				encodeApprovalPolicyReference(pg_c)

				exml.EncodeForeignTable(pg_c,
					"AccProduct", "UID_AccProductGroup", "CatalogItem",
					exml.EncodingOptions{
						F_Attrs: makeAttrFn(map[string]string{
							"id":           "UID_AccProduct",
							"name":         "Ident_AccProduct",
							"fullPath":     "FullPath",
							"isSpecial":    "IsSpecial",
							"isInActive":   "IsInActive",
							"maxValidDays": "MaxValidDays",
						}),
						F_Content: func(catalog_c *exml.TableContext) {
							encodeCatalogItemContent(config, catalog_c)
						},
					},
				)
			},
		},
	)
}

func encodeCatalogItemContent(config ExporterConfig, p_c *exml.TableContext) {
	exml.EncodeRowAttribute(p_c, "Description")
	encodeOrgReference(p_c, "UID_OrgRuler", "Owner")
	encodeOrgReference(p_c, "UID_OrgAttestator", "Attestor")

	exml.EncodeFKReference(p_c,
		"QERTermsOfUse", "UID_QERTermsOfUse",
		"Terms",
		exml.EncodingOptions{
			NoContent: true,
			F_Attrs: makeAttrFn(map[string]string{
				"id":   "UID_QERTermsOfUse",
				"name": "Ident_QERTermsOfUse",
			}),
		},
	)

	exml.EncodeFKReference(p_c,
		"PWODecisionMethod", "UID_PWODecisionMethod", "ApprovalPolicy",
		exml.EncodingOptions{
			NoContent: true,
			F_Attrs: makeAttrFn(map[string]string{
				"id":    "UID_PWODecisionMethod",
				"name":  "Ident_PWODecisionMethod",
				"usage": "UsageArea"}),
			F_Content: encodeApprovalPolicyContent,
		},
	)

	wc_itshop := fmt.Sprintf("UID_AccProduct = '%s' and ITShopInfo = 'PR'", p_c.GetStringVal("UID_AccProduct"))
	exml.EncodeMatchingRows(p_c.DBContext,
		"ITShopOrg", wc_itshop, "ITShopOrg",
		p_c.Writer,
		exml.EncodingOptions{
			NoContent: true,
			F_Attrs:   stdITShopAttrs,
			F_Content: func(sh_c *exml.TableContext) {
				encodeITShopProductContent(config, sh_c)
			},
		},
	)
}

// ----- Approval Policies --------------------

func encodeApprovalPolicies(config ExporterConfig, db *sqlx.DB, o io.Writer) error {

	config.dbg("PWODecisionMethod")
	rows, err := dbx.GetAllTableRows(db, "PWODecisionMethod")
	if err != nil {
		return err
	}

	return exml.EncodeTable("ApprovalPolicy", db, rows, o,
		exml.EncodingOptions{
			PluralObjectName: "ApprovalPolicies",
			F_Attrs: makeAttrFn(map[string]string{
				"id":    "UID_PWODecisionMethod",
				"name":  "Ident_PWODecisionMethod",
				"usage": "UsageArea"}),
			F_Content: encodeApprovalPolicyContent,
		},
	)
}

func encodeApprovalPolicyContent(ap_c *exml.TableContext) {
	encodeApprovalWorkflowRef(ap_c, "UID_SubMethodOrderProduct", "RequestWorkflow")
	encodeApprovalWorkflowRef(ap_c, "UID_SubMethodOrderProlongate", "RenewalWorkflow")
	encodeApprovalWorkflowRef(ap_c, "UID_SubMethodOrderUnsubscribe", "UnsubscribeWorkflow")

	encodeEmailTemplateRef(ap_c, "UID_DialogRichMailGrant", "MailTemplateApproved")
	encodeEmailTemplateRef(ap_c, "UID_DialogRichMailNoGrant", "MailTemplateDenied")
	encodeEmailTemplateRef(ap_c, "UID_DialogRichMailUnsubscribe", "MailTemplateUnsubscribed")
	encodeEmailTemplateRef(ap_c, "UID_DialogRichMailAbort", "MailTemplateAborted")
	encodeEmailTemplateRef(ap_c, "UID_DialogRichMailExpiration", "MailTemplateExpired")
	encodeEmailTemplateRef(ap_c, "UID_DialogRichMailProlongate", "MailTemplateRenewed")
}

func encodeApprovalWorkflowRef(ap_c *exml.TableContext, dmID string, wfName string) error {
	return exml.EncodeCRReference(ap_c,
		"PWODecisionSubMethod", dmID, "UID_PWODecisionSubMethod", wfName,
		exml.EncodingOptions{
			NoContent: true,
			F_Attrs: makeAttrFn(map[string]string{
				"id":   "UID_PWODecisionSubMethod",
				"name": "Ident_PWODecisionSubMethod"}),
		},
	)
}

func encodeApprovalWorkflows(config ExporterConfig, db *sqlx.DB, o io.Writer) error {

	rows, err := dbx.GetAllTableRows(db, "PWODecisionSubMethod")
	if err != nil {
		return err
	}

	return exml.EncodeTable("ApprovalWorkflow", db, rows, o,
		exml.EncodingOptions{
			F_Attrs: makeAttrFn(map[string]string{
				"id":          "UID_PWODecisionSubMethod",
				"name":        "Ident_PWODecisionSubMethod",
				"revision":    "RevisionNumber",
				"daysToAbort": "DaysToAbort",
				"usage":       "UsageArea",
			}),
			F_Content: func(aw_c *exml.TableContext) {
				exml.EncodeRowAttribute(aw_c, "Description")

				exml.EncodeForeignTable(aw_c,
					"PWODecisionStep", "UID_PWODecisionSubMethod", "ApprovalStep",
					exml.EncodingOptions{
						F_Attrs: makeAttrFn(map[string]string{
							"id":                  "UID_PWODecisionStep",
							"name":                "Ident_PWODecisionStep",
							"level":               "LevelNumber",
							"levelName":           "LevelDisplay",
							"subLevel":            "SubLevelNumber",
							"positiveSteps":       "PositiveSteps",
							"negativeSteps":       "NegativeSteps",
							"escalationSteps":     "EscalationSteps",
							"UID_PWODecisionRule": "UID_PWODecisionRule",
						}),
						F_Content: encodeApprovalStepContent,
					},
				)
			},
		},
	)
}

func encodeApprovalStepContent(c *exml.TableContext) {
	exml.EncodeRowAttribute(c, "Description")

	exml.EncodeFKReference(c,
		"PWODecisionRule", "UID_PWODecisionRule", "Rule",
		exml.EncodingOptions{
			NoContent: true,
			F_Attrs: makeAttrFn(map[string]string{
				"id":   "UID_PWODecisionRule",
				"name": "DecisionRule",
			}),
			F_Content: func(dr_c *exml.TableContext) {
				exml.EncodeRowAttribute(dr_c, "Description")
			},
		},
	)

	assignedOrgKey := c.GetStringVal("ObjectKeyOfAssignedOrg")
	exml.EncodeReferenceObjectKey(c, assignedOrgKey, "AssignedRole",
		exml.EncodingOptions{
			NoContent: true,
			SkipEmpty: true,
			F_Attrs: makeAttrFn(map[string]string{
				"fullPath": "FullPath",
			}),
			F_Content: func(ao_c *exml.TableContext) {
				exml.EncodeRowAttribute(ao_c, "Description")
			},
		},
	)

	encodeEmailTemplateRef(c, "UID_DialogRichMailReminder", "MailTemplateRemind")
	encodeEmailTemplateRef(c, "UID_DialogRichMailEscalate", "MailTemplateEscalate")
	encodeEmailTemplateRef(c, "UID_DialogRichMailGrant", "MailTemplateApprove")
	encodeEmailTemplateRef(c, "UID_DialogRichMailNoGrant", "MailTemplateDeny")
	encodeEmailTemplateRef(c, "UID_DialogRichMailInsert", "MailTemplateNew")
	encodeEmailTemplateRef(c, "UID_DialogRichMailToDelegat", "MailTemplateToDelegate")
	encodeEmailTemplateRef(c, "UID_DialogRichMailFromDelegat", "MailTemplateFromDelegate")

}

func encodeApprovalRules(config ExporterConfig, db *sqlx.DB, o io.Writer) error {

	rows, err := dbx.GetAllTableRows(db, "PWODecisionRule")
	if err != nil {
		return err
	}

	return exml.EncodeTable("ApprovalDecisionRule", db, rows, o,
		exml.EncodingOptions{
			NoContent: true,
			F_Attrs: makeAttrFn(map[string]string{
				"id":               "UID_PWODecisionRule",
				"name":             "DecisionRule",
				"usage":            "UsageArea",
				"sortOrder":        "SortOrder",
				"maxCountApprover": "MaxCountApprover",
			}),
			F_Content: func(dr_c *exml.TableContext) {
				exml.EncodeRowAttribute(dr_c, "Description")

				exml.EncodeForeignTable(dr_c,
					"PWODecisionRuleRulerDetect", "UID_PWODecisionRule", "Query",
					exml.EncodingOptions{
						PluralObjectName: "Queries",
						NoContent:        true,
						F_Attrs: makeAttrFn(map[string]string{
							"id":   "UID_PWODecisionRuleRulerDetect",
							"name": "Ident_RulerDetect",
						}),
						F_Content: func(drq_c *exml.TableContext) {
							exml.EncodeRowAttribute(drq_c, "SQLQuery")
						},
					},
				)

			},
		},
	)

}

// ----- Email Templates -------------------------------

func encodeEmailTemplateRef(c *exml.TableContext, keyColumn string, xmlName string) error {

	exml.EncodeCRReference(c,
		"DialogRichMail", keyColumn, "UID_DialogRichMail", xmlName,
		exml.EncodingOptions{
			NoContent: true,
			SkipEmpty: true,
			F_Attrs: makeAttrFn(map[string]string{
				"id":           "UID_DialogRichMail",
				"name":         "Ident_DialogRichMail",
				"targetFormat": "TargetFormat",
			}),
		},
	)

	return nil
}

// ----- Account Definitions -------------------------------

func encodeAccountDefinitions(config ExporterConfig, db *sqlx.DB, o io.Writer) error {

	config.dbg("TSBAccountDef")
	rows, err := dbx.GetAllTableRows(db, "TSBAccountDef")
	if err != nil {
		return err
	}

	return exml.EncodeTable("AccountDefinition", db, rows, o,
		exml.EncodingOptions{
			F_Attrs: makeAttrFn(
				map[string]string{"id": "UID_TSBAccountDef", "name": "Ident_TSBAccountDef"},
				[]string{"IsAutoAssignToPerson"},
			),
			F_Content: func(ad_c *exml.TableContext) {

				encodeObjectKeyReferenceSimple(ad_c, "ObjectKeyTargetSystem", "TargetSystem")

				encodeTableReference(ad_c, "UID_DialogTableAccountType", "Table")

				exml.EncodeCRReference(ad_c,
					"TSBBehavior", "UID_TSBBehaviorDefault", "UID_TSBBehavior",
					"DefaultBehavior",
					exml.EncodingOptions{
						NoContent: true,
						F_Attrs: makeAttrFn(map[string]string{"id": "UID_AERole",
							"name":            "Ident_TSBBehavior",
							"ITDataUsage":     "ITDataUsage",
							"ADAInheritGroup": "ADAInheritGroup",
						}),
						F_Content: func(adb_c *exml.TableContext) {
							exml.EncodeRowAttribute(adb_c, "Description")
						},
					},
				)

				wc_behaviors := fmt.Sprintf(
					"UID_TSBBehavior in ( select UID_TSBBehavior from TSBAccountDefHasBehavior where UID_TSBAccountDef = '%s')",
					ad_c.GetStringVal("UID_TSBAccountDef"),
				)
				exml.EncodeRelatedTable(ad_c,
					"TSBBehavior", wc_behaviors, "Behavior",
					exml.EncodingOptions{
						F_Attrs: makeAttrFn(map[string]string{
							"name":            "Ident_TSBBehavior",
							"ITDataUsage":     "ITDataUsage",
							"ADAInheritGroup": "ADAInheritGroup",
						}),
						F_Content: func(b_c *exml.TableContext) {
							exml.EncodeRowAttribute(b_c, "Description")
						},
					},
				)

				encodeAccountDefITDataContent(ad_c)
			},
		},
	)

}

func encodeAccountDefITDataContent(c *exml.TableContext) error {

	exml.EncodeForeignTable(c,
		"TSBITDataMapping", "UID_TSBAccountDef", "DataMapping",
		exml.EncodingOptions{
			F_Attrs: makeAttrFn(map[string]string{
				"UID_DialogColumn":  "UID_DialogColumn",
				"alwaysUseDefault":  "UseAlwaysDefaultValue",
				"notifyDefaultUsed": "NotifyDefaultUsed",
				"fixValue":          "FixValue",
				"from":              "ITDataFrom",
			}),
			F_Content: func(itm_c *exml.TableContext) {

				exml.EncodeReferenceObjectKey(itm_c,
					itm_c.GetStringVal("ObjectKeyDefaultValue"),
					"DefaultValue",
					exml.EncodingOptions{
						SkipEmpty: true,
						F_Content: func(dv_c *exml.TableContext) {
							exml.EncodeRowAttribute(dv_c, "Description")
						},
					},
				)

				encodeColumnReferenceSimple(itm_c)

				wc_itd := fmt.Sprintf(
					"ObjectKeyAppliesTo = '%s' and UID_DialogColumnTarget = '%s'",
					c.GetStringVal("XObjectKey"),
					itm_c.GetStringVal("UID_DialogColumn"),
				)
				exml.EncodeRelatedTable(itm_c,
					"TSBITData", wc_itd, "DataMap",
					exml.EncodingOptions{
						F_Attrs: makeAttrFn(map[string]string{
							"name": "DisplayValue",
						}),
						F_Content: func(itd_c *exml.TableContext) {

							exml.EncodeReferenceObjectKey(itd_c,
								itd_c.GetStringVal("ObjectKeyValue"),
								"DataMapValue",
								exml.EncodingOptions{
									SkipEmpty: true,
									F_Content: func(dmv_c *exml.TableContext) {
										exml.EncodeRowAttribute(dmv_c, "Description")
									},
								},
							)

							exml.EncodeForeignSingleton(itd_c,
								"BaseTree", "UID_Org", "Structure",
								exml.EncodingOptions{
									NoContent: true,
									F_Attrs:   stdOrgAttrs,
									F_Content: func(bt_c *exml.TableContext) {
										exml.EncodeFKReference(bt_c,
											"OrgRoot", "UID_OrgRoot", "Type",
											exml.EncodingOptions{
												NoContent: true,
												F_Attrs: makeAttrFn(map[string]string{
													"name": "Ident_OrgRoot",
												}),
											},
										)
									},
								},
							)

						},
					},
				)
			},
		},
	)

	return nil
}

// ----- Attestation Policies -------------------------------

func encodeAttestationPolicies(config ExporterConfig, db *sqlx.DB, o io.Writer) error {

	config.dbg("AttestationPolicy")
	rows, err := dbx.GetAllTableRows(db, "AttestationPolicy")
	if err != nil {
		return err
	}

	return exml.EncodeTable("AttestationPolicy", db, rows, o,
		exml.EncodingOptions{
			PluralObjectName: "AttestationPolicies",
			F_Attrs: makeAttrFn(map[string]string{
				"id":           "UID_AttestationPolicy",
				"name":         "Ident_AttestationPolicy",
				"isInActive":   "IsInActive",
				"oldCaseLimit": "LimitOfOldCases",
				"solutionDays": "SolutionDays",
			}),
			F_Content: func(ap_c *exml.TableContext) {
				exml.EncodeRowAttribute(ap_c, "Description")
				exml.EncodeRowAttribute(ap_c, "WhereClause")
				encodeScheduleReference(ap_c, "UID_DialogSchedule", "Schedule")
				encodeApprovalPolicyReference(ap_c)

				encodePersonReference(ap_c, "UID_PersonOwner", "Owner")
				encodeOrgReference(ap_c, "UID_AERoleOwner", "OwnerRole")

				exml.EncodeFKReference(ap_c,
					"AttestationPolicyGroup", "UID_AttestationPolicyGroup", "PolicyGroup",
					exml.EncodingOptions{
						SkipEmpty: true,
						F_Attrs: makeAttrFn(map[string]string{
							"UID_AttestationPolicyGroup": "UID_AttestationPolicyGroup",
							"name":                       "Ident_AttestationPolicyGroup",
							"isInActive":                 "IsInActive",
						}),
						F_Content: func(apg_c *exml.TableContext) {
							exml.EncodeRowAttribute(apg_c, "Description")
							encodeScheduleReference(ap_c, "UID_DialogSchedule", "Schedule")
							encodePickCategoryReference(ap_c)
						},
					},
				)

				exml.EncodeFKReference(ap_c,
					"AttestationObject", "UID_AttestationObject", "Procedure",
					exml.EncodingOptions{
						F_Attrs: makeAttrFn(map[string]string{
							"UID_AttestationObject": "UID_AttestationObject",
							"name":                  "Ident_AttestationObject",
						}),
						F_Content: func(ao_c *exml.TableContext) {
							exml.EncodeRowAttribute(ao_c, "Description")
						},
					},
				)

				exml.EncodeFKReference(ap_c,
					"QERTermsOfUse", "UID_QERTermsOfUse",
					"Terms",
					exml.EncodingOptions{
						NoContent: true,
						F_Attrs: makeAttrFn(map[string]string{
							"id":   "UID_QERTermsOfUse",
							"name": "Ident_QERTermsOfUse",
						}),
					},
				)

				exml.EncodeFKReference(ap_c,
					"QBMCulture", "UID_DialogCulture",
					"Language",
					exml.EncodingOptions{
						NoContent: true,
						SkipEmpty: true,
						F_Attrs: makeAttrFn(map[string]string{
							"id":          "UID_DialogCulture",
							"name":        "Ident_DialogCulture",
							"displayName": "DisplayName",
							"nativeName":  "NativeName",
						}),
					},
				)

				wc_ap, _ := dbx.GetFKWC(ap_c.Row, "UID_AttestationPolicy")
				encodeATTCaseSummary(ap_c, wc_ap)

				wc_ar, _ := dbx.GetFKWC(ap_c.Row, "UID_AttestationPolicy")
				wc_ar_cases := fmt.Sprintf(
					`(%s) and ( select count(*) from AttestationCase c 
						where c.UID_AttestationRun = AttestationRun.UID_AttestationRun) > 0`,
					wc_ar)
				exml.EncodeRelatedTable(ap_c,
					"AttestationRun", wc_ar_cases, "AttestationCycle",
					exml.EncodingOptions{
						SkipEmpty: true,
						NoContent: true,
						F_Attrs: makeAttrFn2(
							map[string]string{
								"date":          "PolicyProcessed",
								"historyNumber": "HistoryNumber",
							},
							func(ar_c *exml.TableContext) (string, string, error) {
								rval, ok := (*ar_c.Row)["PolicyProcessed"]
								if !ok {
									return "", "", fmt.Errorf("PolicyProcessed not found")
								}
								dval, ok := rval.(time.Time)
								if !ok {
									return "", "", fmt.Errorf("PolicyProcessed not expected format")
								}

								return "sortableDate", dval.Format("20060102"), nil
							},
						),
						F_Content: func(ar_c *exml.TableContext) {
							wc_ap, _ := dbx.GetFKWC(ar_c.Row, "UID_AttestationRun")
							encodeATTCaseSummary(ar_c, wc_ap)
						},
					},
				)

			},
		},
	)

}

func encodePickCategoryReference(c *exml.TableContext) {
	exml.EncodeFKReference(c,
		"QERPickCategory", "UID_QERPickCategory", "PolicyPickCategory",
		exml.EncodingOptions{
			SkipEmpty: true,
			NoContent: true,
			F_Attrs: makeAttrFn(map[string]string{
				"name":                      "DisplayName",
				"isManual":                  "IsManual",
				"removeAfterAttestationRun": "RemoveAfterAttestationRun",
			}),
			F_Content: func(pc_c *exml.TableContext) {
				encodeTableReference(pc_c, "UID_DialogTable", "Table")

				exml.EncodeForeignTable(pc_c,
					"QERPickedItem", "UID_QERPickCategory", "PolicyPickedItem",
					exml.EncodingOptions{
						NoContent: true,
						SkipEmpty: true,
						F_Content: func(pi_c *exml.TableContext) {
							exml.EncodeReferenceObjectKey(pi_c,
								pi_c.GetStringVal("ObjectKeyItem"), "Item",
								exml.EncodingOptions{
									NoContent: true,
									F_Attrs: makeAttrFn(map[string]string{
										"CentralAccount": "CentralAccount",
										"InternalName":   "InternalName",
									}),
								},
							)
						},
					},
				)
			},
		},
	)
}

func encodeATTCaseSummary(c *exml.TableContext, whereClause string) {

	exml.EncodeRowCount(c, "AttestationCase", whereClause, "Case")

	wc_open := fmt.Sprintf(`(%s) and IsClosed = 0`, whereClause)
	exml.EncodeRowCount(c, "AttestationCase", wc_open, "OpenCase")

	wc_closed := fmt.Sprintf(`(%s) and IsClosed = 1`, whereClause)
	exml.EncodeRowCount(c, "AttestationCase", wc_closed, "ClosedCase")

	wc_approved := fmt.Sprintf(`(%s) and IsClosed = 1 and IsGranted = 1`, whereClause)
	exml.EncodeRowCount(c, "AttestationCase", wc_approved, "ApprovedCase")

	wc_denied := fmt.Sprintf(`(%s) and IsClosed = 1 and IsGranted = 0`, whereClause)
	exml.EncodeRowCount(c, "AttestationCase", wc_denied, "DeniedCase")
}

func encodeAttestationProcedures(config ExporterConfig, db *sqlx.DB, o io.Writer) error {

	rows, err := dbx.GetAllTableRows(db, "AttestationObject")
	if err != nil {
		return err
	}

	return exml.EncodeTable("AttestationProcedure", db, rows, o,
		exml.EncodingOptions{
			F_Attrs: makeAttrFn(map[string]string{
				"id":   "UID_AttestationObject",
				"name": "Ident_AttestationObject",
			}),
			F_Content: func(ao_c *exml.TableContext) {

				exml.EncodeRowAttribute(ao_c, "Description")
				encodeTableReference(ao_c, "UID_DialogTable", "Table")

				exml.EncodeFKReference(ao_c,
					"AttestationType", "UID_AttestationType", "Type",
					exml.EncodingOptions{
						SkipEmpty: true,
						NoContent: true,
						F_Attrs: makeAttrFn(map[string]string{
							"UID_AttestationType": "UID_AttestationType",
							"name":                "Ident_AttestationType",
						}),
						F_Content: func(at_c *exml.TableContext) {
							exml.EncodeRowAttribute(at_c, "Description")
						},
					},
				)

				exml.EncodeReferenceObjectKey(ao_c,
					ao_c.GetStringVal("ObjectKeyReport"), "Report",
					exml.EncodingOptions{
						SkipEmpty: true,
						NoContent: true,
						F_Attrs: makeAttrFn(map[string]string{
							"name":        "ReportName",
							"displayName": "DisplayName",
						}),
						F_Content: func(rep_c *exml.TableContext) {
							exml.EncodeRowAttribute(rep_c, "Description")
						},
					},
				)

				// assigned approval policies
				exml.EncodeMNTable(ao_c,
					"UID_AttestationObject", "AttestationObjectHasPWODM",
					"PWODecisionMethod", "UID_PWODecisionMethod",
					"ApprovalPolicy",
					exml.EncodingOptions{
						PluralObjectName: "ApprovalPolicies",
						NoContent:        true,
						F_Attrs: makeAttrFn(map[string]string{
							"id":    "UID_PWODecisionMethod",
							"name":  "Ident_PWODecisionMethod",
							"usage": "UsageArea"}),
						F_Content: encodeApprovalPolicyContent,
					},
				)
			},
		},
	)
}

// ----- Target Systems -------------------------------

func encodeTargetSystems(config ExporterConfig, db *sqlx.DB, o io.Writer) error {

	config.dbg("UNSRoot")
	rows, err := dbx.GetAllTableRows(db, "UNSRoot")
	if err != nil {
		return err
	}

	return exml.EncodeTable("TargetSystem", db, rows, o,
		exml.EncodingOptions{
			NoContent: true,
			F_Attrs: makeAttrFn(map[string]string{
				"id":            "UID_UNSRoot",
				"name":          "Ident_UNSRoot",
				"displayName":   "DisplayName",
				"canonicalName": "CanonicalName",
				"managedBy":     "NamespaceManagedBy",
				"dn":            "DistinguishedName",
				"key":           "XObjectKey",
			}),
			F_Content: func(ts_c *exml.TableContext) {

				exml.EncodeFKReference(ts_c,
					"DPRNameSpace", "UID_DPRNameSpace", "SyncType",
					exml.EncodingOptions{
						NoContent: true,
						F_Attrs: makeAttrFn(map[string]string{
							"UID_DPRNameSpace": "UID_DPRNameSpace",
							"name":             "Ident_DPRNameSpace",
							"displayName":      "DisplayName",
						}),
						F_Content: func(ns_c *exml.TableContext) {
							exml.EncodeRowAttribute(ns_c, "Description")
						},
					},
				)

				exml.EncodeFKReference(ts_c,
					"TSBAccountDef", "UID_TSBAccountDef", "DefaultAccountDef",
					exml.EncodingOptions{
						F_Attrs: makeAttrFn(map[string]string{
							"UID_TSBAccountDef": "UID_TSBAccountDef",
							"name":              "Ident_TSBAccountDef",
						}),
						F_Content: func(ad_c *exml.TableContext) {
							exml.EncodeRowAttribute(ad_c, "Description")
						},
					},
				)

				encodeOrgReference(ts_c, "UID_AERoleOwner", "OwnerRole")

				exml.EncodeForeignTable(ts_c,
					"UNSContainer", "UID_UNSRoot", "Container",
					exml.EncodingOptions{
						NoContent: true,
						F_Attrs: makeAttrFn(map[string]string{
							"canonicalName":    "CanonicalName",
							"dn":               "DistinguishedName",
							"cn":               "cn",
							"UID_UNSContainer": "UID_UNSContainer",
						}),
						F_Content: func(c_c *exml.TableContext) {
							wc_c, _ := dbx.GetFKWC(c_c.Row, "UID_UNSContainer")
							encodeUNSContainerSummary(c_c, wc_c)
						},
					},
				)

				wc_root, _ := dbx.GetFKWC(ts_c.Row, "UID_UNSRoot")
				encodeUNSContainerSummary(ts_c, wc_root)

				wc_domain := fmt.Sprintf(
					`UID_ADSDomain = (select UID_ADSDomainParent from ADSDomain where XObjectKey = '%s')`,
					ts_c.GetStringVal("XObjectKey"),
				)
				exml.EncodeRelatedTable(ts_c, "ADSDomain", wc_domain,
					"ParentDomain",
					exml.EncodingOptions{
						F_Attrs: makeAttrFn(
							map[string]string{"id": "UID_ADSDomain"},
							[]string{"Name"},
						),
						F_Content: func(jobStart_c *exml.TableContext) {
						},
					},
				)

				wc_forest := fmt.Sprintf(
					`UID_ADSForest = (select UID_ADSForest from ADSDomain where XObjectKey = '%s')`,
					ts_c.GetStringVal("XObjectKey"),
				)
				exml.EncodeReference(ts_c, "ADSForest", wc_forest,
					"Forest",
					exml.EncodingOptions{
						F_Attrs: makeAttrFn(
							map[string]string{
								"id": "UID_ADSForest",
								"dn": "DistinguishedName",
							},
							[]string{"Name"},
						),
						F_Content: func(adsf_c *exml.TableContext) {
						},
					},
				)

			},
		},
	)

}

func encodeUNSContainerSummary(c *exml.TableContext, wc_root string) {
	io.WriteString(c.Writer, "<ObjectCounts>")
	exml.EncodeRowCount(c, "UNSContainer", wc_root, "Container")
	exml.EncodeRowCount(c, "UNSGroup", wc_root, "Group")
	exml.EncodeRowCount(c, "UNSAccount", wc_root, "Account")
	io.WriteString(c.Writer, "</ObjectCounts>")
}

func encodeSynchronizationProjects(config ExporterConfig, db *sqlx.DB, o io.Writer) error {

	config.dbg("DPRShell")
	rows, err := dbx.GetAllTableRows(db, "DPRShell")
	if err != nil {
		return err
	}

	return exml.EncodeTable("SyncProject", db, rows, o,
		exml.EncodingOptions{
			F_Attrs: makeAttrFn(map[string]string{
				"id":             "UID_DPRShell",
				"name":           "DisplayName",
				"scriptLanguage": "ScriptLanguage",
				"shadowCopyMode": "ShadowCopyMode",
			}),
			ExcludeAttrs: []string{"ShadowCopy"},
			F_Content: func(sp_c *exml.TableContext) {

				exml.EncodeRowAttribute(sp_c, "Description")
				exml.EncodeRowAttribute(sp_c, "OriginInfo")

				exml.EncodeFKReference(sp_c,
					"QBMClrType", "UID_QBMClrType", "CLRType",
					exml.EncodingOptions{
						NoContent: true,
						F_Attrs: makeAttrFn(map[string]string{
							"id":               "UID_QBMClrType",
							"name":             "FullTypeName",
							"exposedInterface": "ExposedInterface",
							"assembly":         "Assembly",
						}),
					},
				)

				exml.EncodeForeignTable(sp_c,
					"DPRSchema", "UID_DPRShell", "Schema",
					exml.EncodingOptions{
						F_Attrs: makeAttrFn(map[string]string{
							"id":              "UID_DPRSchema",
							"name":            "Name",
							"displayName":     "DisplayName",
							"systemType":      "SystemType",
							"systemSubType":   "SystemSubType",
							"SystemVersion":   "SystemVersion",
							"functionalLevel": "FunctionalLevel",
						}),
						F_Content: encodeDPRSchemaContent,
					},
				)

				exml.EncodeForeignTable(sp_c,
					"DPRSystemMap", "UID_DPRShell", "SystemMap",
					exml.EncodingOptions{
						F_Attrs: makeAttrFn(map[string]string{
							"id":           "UID_DPRSystemMap",
							"name":         "DisplayName",
							"direction":    "MappingDirection",
							"capabilities": "Capabilities",
						}),
						F_Content: func(sm_c *exml.TableContext) {

							encodeSchemaClassReference(sm_c, "UID_LeftDPRSchemaClass", "LeftSchemaClass")
							encodeSchemaClassReference(sm_c, "UID_RightDPRSchemaClass", "RightSchemaClass")

							exml.EncodeForeignTable(sm_c,
								"DPRSystemMappingRule", "UID_DPRSystemMap", "MappingRule",
								exml.EncodingOptions{
									F_Attrs: makeAttrFn(
										map[string]string{
											"id": "UID_DPRSystemMappingRule",
										},
										[]string{
											"Name", "DisplayName",
											"PropertyLeft", "PropertyRight",
											"IsKeyRule",
											"SortOrder",
										},
									),
								},
							)
						},
					},
				)

				exml.EncodeForeignTable(sp_c,
					"DPRSystemConnection", "UID_DPRShell", "SystemConnection",
					exml.EncodingOptions{
						F_Attrs: makeAttrFn(
							map[string]string{
								"id":   "UID_DPRSystemConnection",
								"name": "DefaultDisplay",
							},
						),
						ExcludeAttrs: []string{"ConnectionParameter"},
						F_Content:    encodeSystemConnectionContent,
					},
				)

				encodeVariableSetReference(sp_c, "UID_DPRSystemVariableSetDef", "DefaultVariableSet")

				exml.EncodeForeignTable(sp_c,
					"DPRSystemVariableSet", "UID_DPRShell", "VariableSet",
					exml.EncodingOptions{
						F_Attrs: makeAttrFn(
							map[string]string{"id": "UID_DPRSystemVariableSet"},
							[]string{"Name", "DisplayName"},
						),
						F_Content: func(vs_c *exml.TableContext) {

							exml.EncodeForeignTable(vs_c,
								"DPRSystemVariable", "UID_DPRSystemVariableSet", "Variable",
								exml.EncodingOptions{
									F_Attrs: makeAttrFn(
										map[string]string{"id": "UID_DPRSystemVariable"},
										[]string{"Name", "DisplayName", "IsSecret", "IsSystemVariable", "Value"},
									),
									F_Content: func(v_c *exml.TableContext) {

										if len(v_c.GetStringVal("GenerateValueScript")) > 0 {
											io.WriteString(
												v_c.Writer,
												fmt.Sprintf(
													`<GenerateValueScript language="%s">`,
													v_c.GetStringVal("ScriptLanguage"),
												),
											)
											io.WriteString(v_c.Writer, v_c.GetStringVal("GenerateValueScript"))
											io.WriteString(v_c.Writer, "</GenerateValueScript>")
										}

									},
								},
							)

						},
					},
				)

				exml.EncodeForeignTable(sp_c,
					"DPRProjectionConfig", "UID_DPRShell", "Workflow",
					exml.EncodingOptions{
						F_Attrs: makeAttrFn(
							map[string]string{
								"id":               "UID_DPRProjectionConfig",
								"direction":        "ProjectionDirection",
								"revisionHandling": "UseRevision",
							},
							[]string{"Name", "DisplayName", "ConflictResolution", "ExceptionHandling"},
						),
						F_Content: func(projconf_c *exml.TableContext) {

							exml.EncodeForeignTable(projconf_c,
								"DPRProjectionConfigStep", "UID_DPRProjectionConfig", "Step",
								exml.EncodingOptions{
									F_Attrs: makeAttrFn(
										map[string]string{
											"id":        "UID_DPRProjectionConfigStep",
											"direction": "ProjectionDirection",
										},
										[]string{
											"Name", "DisplayName",
											"IsImport", "IsDeactivated", "ExceptionHandling",
										},
									),
								},
							)

						},
					},
				)

				exml.EncodeForeignTable(sp_c,
					"DPRProjectionStartInfo", "UID_DPRShell", "StartInfo",
					exml.EncodingOptions{
						F_Attrs: makeAttrFn(
							map[string]string{
								"id":              "UID_DPRProjectionStartInfo",
								"direction":       "ProjectionDirection",
								"failureHandling": "FailureHandlingMode",
							},
							[]string{"Name", "DisplayName", "RevisionHandling", "ExceptionHandling"},
						),
						F_Content: func(startInfo_c *exml.TableContext) {

							encodeVariableSetReference(startInfo_c, "UID_DPRSystemVariableSet", "VariableSet")

							exml.EncodeFKReference(startInfo_c,
								"DPRProjectionConfig", "UID_DPRProjectionConfig", "Workflow",
								exml.EncodingOptions{
									F_Attrs: makeAttrFn(
										map[string]string{"id": "UID_DPRProjectionConfig"},
										[]string{"Name"},
									),
								},
							)

							wc_js := fmt.Sprintf(`ObjectKeyTarget = '%s'`, startInfo_c.GetStringVal("XObjectKey"))
							exml.EncodeRelatedTable(startInfo_c, "JobAutoStart", wc_js,
								"JobAutoStart",
								exml.EncodingOptions{
									F_Attrs: makeAttrFn(
										map[string]string{"id": "UID_JobAutoStart"},
										[]string{"Name"},
									),
									F_Content: func(jobStart_c *exml.TableContext) {
										exml.EncodeRowAttribute(jobStart_c, "Description")
										exml.EncodeRowAttribute(jobStart_c, "WhereClause")
										encodeScheduleReference(jobStart_c, "UID_DialogSchedule", "Schedule")

									},
								},
							)
						},
					},
				)
			},
		},
	)

}

func encodeSystemConnectionContent(c *exml.TableContext) {
	encodeSchemaReference(c, "UID_DPRSchema", "Schema")

	exml.EncodeForeignTable(c,
		"DPRRootObjConnectionInfo", "UID_DPRSystemConnection", "RootObjConnectionInfo",
		exml.EncodingOptions{
			F_Content: func(rci_c *exml.TableContext) {

				exml.EncodeReferenceObjectKey(rci_c,
					rci_c.GetStringVal("ObjectKeyRoot"),
					"RootObject",
					exml.EncodingOptions{
						NoContent: true,
						F_Attrs:   makeAttrFn(map[string]string{"key": "XObjectKey"}),
					},
				)

				encodeVariableSetReference(rci_c, "UID_DPRSystemVariableSet", "VariableSet")

				exml.EncodeFKReference(rci_c,
					"QBMServer", "UID_QBMServer", "Server",
					exml.EncodingOptions{
						NoContent: true,
						F_Attrs: makeAttrFn(
							map[string]string{
								"id":    "UID_QBMServer",
								"name":  "Ident_Server",
								"FQDN":  "FQDN",
								"queue": "QueueName",
							},
						),
					},
				)

			},
		},
	)
}

func encodeVariableSetReference(c *exml.TableContext, refColumn string, xmlName string) {
	exml.EncodeCRReference(c,
		"DPRSystemVariableSet", refColumn, "UID_DPRSystemVariableSet", xmlName,
		exml.EncodingOptions{
			NoContent: true,
			F_Attrs: makeAttrFn(
				map[string]string{"id": "UID_DPRSystemVariableSet"},
				[]string{"Name", "DisplayName"},
			),
		},
	)

}

func encodeSchemaReference(c *exml.TableContext, refColumn string, xmlName string) {

	exml.EncodeCRReference(c,
		"DPRSchema", refColumn, "UID_DPRSchema",
		xmlName,
		exml.EncodingOptions{
			NoContent: true,
			F_Attrs: makeAttrFn(
				map[string]string{
					"id": "UID_DPRSchema",
				},
				[]string{"Name", "SystemType", "SystemId", "SystemDisplay"},
			),
		},
	)
}

func encodeSchemaClassReference(c *exml.TableContext, refColumn string, xmlName string) {

	exml.EncodeCRReference(c,
		"DPRSchemaClass", refColumn, "UID_DPRSchemaClass",
		xmlName,
		exml.EncodingOptions{
			F_Attrs: makeAttrFn(
				map[string]string{
					"id": "UID_DPRSchemaClass",
				},
				[]string{"Name", "DisplayName", "SystemType", "SystemSubType"},
			),
			F_Content: func(sc_c *exml.TableContext) {
				exml.EncodeFKReference(sc_c,
					"DPRSchemaType", "UID_DPRSchemaType", "SchemaType",
					exml.EncodingOptions{
						F_Attrs: makeAttrFn(
							map[string]string{
								"id": "UID_DPRSchemaType",
							},
							[]string{"Name", "DisplayName", "MetaData"},
						),
						F_Content: func(st_c *exml.TableContext) {
							encodeSchemaReference(st_c, "UID_DPRSchema", "Schema")
						},
					},
				)
			},
		},
	)
}

func encodeDPRSchemaContent(c *exml.TableContext) {

	exml.EncodeForeignTable(c,
		"DPRSchemaType", "UID_DPRSchema", "SchemaType",
		exml.EncodingOptions{
			F_Attrs: makeAttrFn(
				map[string]string{
					"id": "UID_DPRSchemaType",
				},
				[]string{"Name", "DisplayName", "MetaData"},
			),
			F_Content: func(st_c *exml.TableContext) {

				exml.EncodeForeignTable(st_c,
					"DPRSchemaClass", "UID_DPRSchemaType", "SchemaClass",
					exml.EncodingOptions{
						PluralObjectName: "SchemaClasses",
						F_Attrs: makeAttrFn(
							map[string]string{
								"id": "UID_DPRSchemaClass",
							},
							[]string{"Name", "DisplayName"},
						),
						ExcludeAttrs: []string{"Filter"},
						F_Content: func(sc_c *exml.TableContext) {
							exml.EncodeRawAttribute(sc_c, "Filter")
						},
					},
				)

				exml.EncodeForeignTable(st_c,
					"DPRSchemaProperty", "UID_DPRSchemaType", "SchemaProperty",
					exml.EncodingOptions{
						PluralObjectName: "SchemaProperties",
						F_Attrs: makeAttrFn(
							map[string]string{
								"id": "UID_DPRSchemaProperty",
							},
							[]string{"Name", "DisplayName", "DataType", "IsVirtual"},
						),
					},
				)

			},
		},
	)

}

// ----- compliance ---------------------------

func stdRuleAttrs(c *exml.TableContext) ([]xml.Attr, error) {
	attrs := map[string]string{
		"id":            "UID_ComplianceRule",
		"name":          "Ident_ComplianceRule",
		"versionMajor":  "VersionMajor",
		"versionMinor":  "VersionMinor",
		"versionPatch":  "VersionPatch",
		"isWorkingCopy": "IsWorkingCopy",
		"IsInActive":    "IsInActive",
		"ruleNumber":    "RuleNumber",
	}
	maps.Copy(attrs, oneim.MAP_Metadata)
	return exml.MakeXMLAttrs(c.Row, attrs)
}

func encodeComplianceRules(config ExporterConfig, db *sqlx.DB, o io.Writer) error {

	config.dbg("ComplianceRule")
	rows, err := dbx.GetTableRows(db, "ComplianceRule", "IsWorkingCopy = 0")
	if err != nil {
		return err
	}

	return exml.EncodeTable("ComplianceRule", db, rows, o,
		exml.EncodingOptions{
			F_Attrs:      stdRuleAttrs,
			ExcludeAttrs: []string{"WhereClause", "WhereClausePerson", "WhereClausePersonAddOn"},
			F_Content: func(cr_c *exml.TableContext) {

				exml.EncodeRowAttribute(cr_c, "Description")
				exml.EncodeRowAttribute(cr_c, "RiskDescription")
				exml.EncodeRowAttribute(cr_c, "RiskObjectives")
				exml.EncodeRowAttribute(cr_c, "RiskOrgMitigationCtrl")
				exml.EncodeRowAttribute(cr_c, "")
				exml.EncodeRowAttribute(cr_c, "")
				exml.EncodeRowAttribute(cr_c, "")

				exml.EncodeRowAttribute(cr_c, "WhereClause")
				exml.EncodeRowAttribute(cr_c, "WhereClausePerson")

				encodeEmailTemplateRef(cr_c, "UID_DialogRichMailNewViolation", "MailTemplateNewViolation")

				encodeScheduleReference(cr_c, "UID_DialogScheduleCheck", "CheckSchedule")
				encodeScheduleReference(cr_c, "UID_DialogScheduleFill", "FillSchedule")

				encodeOrgReference(cr_c, "UID_OrgRuler", "OwnerRole")
				encodeOrgReference(cr_c, "UID_OrgAttestator", "Attestor")
				encodeOrgReference(cr_c, "UID_OrgResponsible", "ExceptionApproverRole")
				encodeOrgReference(cr_c, "UID_NonCompliance", "ViolatorsRole")

				encodePersonReference(cr_c, "UID_PersonLastAudit", "LastAuditor")

				exml.EncodeCRReference(cr_c,
					"ComplianceRule", "UID_ComplianceRuleWork", "UID_ComplianceRule", "WorkingCopy",
					exml.EncodingOptions{
						NoContent: true,
						F_Attrs:   stdRuleAttrs,
					},
				)

				wc := fmt.Sprintf(`UID_NonCompliance = '%s'`, cr_c.GetStringVal("UID_NonCompliance"))
				exml.EncodeMatchingRows(cr_c.DBContext, "PersonInNonCompliance", wc,
					"Violation",
					cr_c.Writer,
					exml.EncodingOptions{
						SkipEmpty: true,
						NoContent: true,
						F_Attrs: makeAttrFn(
							nil,
							[]string{
								"IsDecisionMade",
								"IsExceptionGranted",
								"DecisionDate",
								"ExceptionValidUntil",
							},
						),
						F_Content: func(v_c *exml.TableContext) {
							encodePersonReference(v_c, "UID_Person", "Violator")
							encodePersonReference(v_c, "UID_PersonDecisionMade", "Approver")
							exml.EncodeRowAttribute(v_c, "DecisionReason")
						},
					},
				)

			},
		},
	)
}

func encodeSchema(config ExporterConfig, db *sqlx.DB, o io.Writer) error {

	config.dbg("DialogTable")
	rows, err := dbx.GetTableRows(db, "DialogTable", "1=1")
	if err != nil {
		return err
	}

	return exml.EncodeTable("Table", db, rows, o,
		exml.EncodingOptions{
			MaxWorkers: config.MaxThreads,
			NoContent:  true,
			F_Attrs: makeAttrFn(
				map[string]string{"name": "TableName", "id": "UID_DialogTable"},
				[]string{
					"DisplayName",
					"TableType", "UsageType",
					"SizeMB", "CountRows",
					"IsResident",
					"DeleteDelayDays",
					"IsAssignmentWithEvent",
				},
			),
			F_Content: func(t_c *exml.TableContext) {

				exml.EncodeRowAttribute(t_c, "ViewWhereClause")
				exml.EncodeRowAttribute(t_c, "SelectScript")
				exml.EncodeRowAttribute(t_c, "InsertValues")
				exml.EncodeRowAttribute(t_c, "OnLoadedScript")
				exml.EncodeRowAttribute(t_c, "OnSavingScript")
				exml.EncodeRowAttribute(t_c, "OnSavedScript")
				exml.EncodeRowAttribute(t_c, "OnDiscardingScript")
				exml.EncodeRowAttribute(t_c, "OnDiscardedScript")

				encodeObjectPatches(t_c)

				exml.EncodeForeignTable(t_c,
					"JobChain", "UID_DialogTable", "Process",
					exml.EncodingOptions{
						NoContent:        true,
						PluralObjectName: "Processes",
						F_Attrs: makeAttrFn(
							map[string]string{"id": "UID_JobChain"},
							[]string{
								"Name",
								"NoGenerate", "IsDeactivatedByPreProcessor",
								"ProcessTracking",
								"LimitationCount", "LimitationWarning",
							},
						),
						F_Content: func(jc_c *exml.TableContext) {
							exml.EncodeRowAttribute(jc_c, "Description")
							encodeObjectPatches(jc_c)
						},
					},
				)

				exml.EncodeForeignTable(t_c,
					"DialogColumn", "UID_DialogTable", "Column",
					exml.EncodingOptions{
						ExcludeAttrs: []string{"Template", "FormatScript", "Commentary"},
						F_Attrs: makeAttrFn(
							map[string]string{"name": "ColumnName", "id": "UID_DialogColumn"},
							[]string{
								"DataType", "SchemaDataType", "SchemaDataLen",
								"Caption",
								"IndexWeight",
								"IsOverwritingTemplate",
								"IsToWatch", "IsToWatchDelete",
							},
						),
						F_Content: func(c_c *exml.TableContext) {
							exml.EncodeRowAttribute(c_c, "Commentary")
							exml.EncodeRowAttribute(c_c, "Template")
							exml.EncodeRowAttribute(c_c, "FormatScript")

							exml.EncodeForeignTable(c_c,
								"QBMColumnLimitedValue", "UID_DialogColumn", "LimitedValue",
								exml.EncodingOptions{
									SkipEmpty: true,
									NoContent: true,
									F_Attrs: makeAttrFn(
										map[string]string{"id": "UID_QBMColumnLimitedValue"},
										[]string{
											"KeyValue", "KeyDisplay",
											"OrderNumber",
											"IsInActive",
										},
									),
									F_Content: func(lv_c *exml.TableContext) {
									},
								},
							)

							encodeObjectPatches(c_c)
						},
					},
				)
			},
		},
	)

}
func encodeProcesses(config ExporterConfig, db *sqlx.DB, o io.Writer) error {

	config.dbg("Process")
	rows, err := dbx.GetTableRows(db, "JobChain", "1=1")
	if err != nil {
		return err
	}

	return exml.EncodeTable("Process", db, rows, o,
		exml.EncodingOptions{
			MaxWorkers:       config.MaxThreads,
			PluralObjectName: "Processes",
			NoContent:        true,
			F_Attrs: makeAttrFn(
				map[string]string{"id": "UID_JobChain"},
				[]string{
					"Name",
					"NoGenerate", "IsDeactivatedByPreProcessor",
					"ProcessTracking",
					"LimitationCount", "LimitationWarning",
				},
			),
			F_Content: func(c *exml.TableContext) {

				exml.EncodeRowAttribute(c, "Description")
				exml.EncodeRowAttribute(c, "GenCondition")
				exml.EncodeRowAttribute(c, "PreCode")
				exml.EncodeRowAttribute(c, "ProcessDisplay")
				encodeTableReference(c, "UID_DialogTable", "Table")
				encodeJobReference(c, "UID_Job", "UID_Job", "InitialStep")

				encodeObjectPatches(c)

				exml.EncodeForeignTable(c,
					"Job", "UID_JobChain", "Job",
					exml.EncodingOptions{
						ExcludeAttrs: []string{
							"PreCode", "GenCondition",
							"Description",
							"ServerDetectScript",
							"PriorityDefinition",
						},
						F_Attrs: makeAttrFn(
							map[string]string{"id": "UID_Job"},
							[]string{
								"Name",
								"Priority",
								"IsToFreezeOnError", "ErrorNotify", "IgnoreErrors", "IsErrorLogToJournal",
								"DeferOnError", "MinutesToDefer", "Retries",
								"SplitOnly",
								"IsForHistory",
							},
						),
						F_Content: encodeJobContent,
					},
				)

				exml.EncodeForeignTable(c,
					"JobEventGen", "UID_JobChain", "JobEventGen",
					exml.EncodingOptions{
						NoContent: true,
						F_Attrs: makeAttrFn(
							map[string]string{"id": "UID_JobEventGen"},
							[]string{"OrderNr"},
						),
						F_Content: func(jeg_c *exml.TableContext) {

							exml.EncodeFKReference(jeg_c,
								"QBMEvent", "UID_QBMEvent", "Event",
								exml.EncodingOptions{
									NoContent: true,
									F_Attrs: makeAttrFn(
										map[string]string{"id": "UID_QBMEvent", "name": "EventName"},
										[]string{"DisplayName"},
									),
									F_Content: func(ev_c *exml.TableContext) {
										encodeTableReference(ev_c, "UID_DialogTable", "Table")
									},
								},
							)

							wc := fmt.Sprintf(`UID_QBMEvent = '%s'`, jeg_c.GetStringVal("UID_QBMEvent"))
							exml.EncodeRelatedTable(jeg_c, "JobAutoStart", wc,
								"JobAutoStart",
								exml.EncodingOptions{
									NoContent: true,
									F_Attrs: makeAttrFn(
										map[string]string{"id": "UID_JobAutoStart"},
										[]string{"Name"},
									),
									F_Content: func(jas_c *exml.TableContext) {
										exml.EncodeRowAttribute(jas_c, "Description")
										exml.EncodeRowAttribute(jas_c, "WhereClause")
										encodeScheduleReference(jas_c, "UID_DialogSchedule", "Schedule")
									},
								},
							)
						},
					},
				)
			},
		},
	)
}

func encodeJobContent(c *exml.TableContext) {
	exml.EncodeRowAttribute(c, "Description")
	exml.EncodeRowAttribute(c, "PreCode")
	exml.EncodeRowAttribute(c, "GenCondition")
	exml.EncodeRowAttribute(c, "ServerDetectScript")
	exml.EncodeRowAttribute(c, "PriorityDefinition")

	encodeJobReferenceS(c, "UID_ErrorJob", "NextStepError")
	encodeJobReferenceS(c, "UID_SuccessJob", "NextStepSuccess")

	encodeObjectPatches(c)

	exml.EncodeForeignTable(c,
		"JobRunParameter", "UID_Job", "JobRunParameter",
		exml.EncodingOptions{
			ExcludeAttrs: []string{"ValueTemplate"},
			F_Attrs: makeAttrFn(
				map[string]string{"id": "UID_JobRunParameter"},
				[]string{
					"Name",
					"IsCrypted",
					"IsHidden",
				},
			),
			F_Content: func(jrp_c *exml.TableContext) {
				exml.EncodeRowAttribute(jrp_c, "ValueTemplate")
				encodeObjectPatches(jrp_c)
				exml.EncodeFKReference(jrp_c,
					"JobParameter", "UID_JobParameter", "Parameter",
					exml.EncodingOptions{
						NoContent: true,
						F_Attrs: makeAttrFn(
							map[string]string{"id": "UID_JobParameter"},
							[]string{
								"Name",
								"IsCrypted",
								"IsHidden",
								"Type",
								"IsOptional",
							},
						),
						F_Content: func(jparam_c *exml.TableContext) {
							exml.EncodeRowAttribute(jparam_c, "Description")
							exml.EncodeRowAttribute(jparam_c, "ValueTemplateDefault")
							exml.EncodeRowAttribute(jparam_c, "ValueTemplateExample")
						},
					},
				)
			},
		},
	)

	exml.EncodeFKReference(c,
		"JobTask", "UID_JobTask", "JobTask",
		exml.EncodingOptions{
			NoContent: true,
			F_Attrs: makeAttrFn(
				map[string]string{"id": "UID_JobTask", "name": "TaskName"},
				[]string{
					"ExecutionType", "RunningOS",
				},
			),
			F_Content: func(jt_c *exml.TableContext) {
				exml.EncodeRowAttribute(jt_c, "Description")
				exml.EncodeFKReference(jt_c,
					"JobComponent", "UID_JobComponent", "Component",
					exml.EncodingOptions{
						NoContent: true,
						F_Attrs: makeAttrFn(
							map[string]string{"id": "UID_JobComponent", "name": "DisplayName"},
							[]string{"ComponentAssembly", "ComponentClass"},
						),
						F_Content: func(comp_c *exml.TableContext) {
							exml.EncodeRowAttribute(comp_c, "Description")
						},
					},
				)
			},
		},
	)

	exml.EncodeFKReference(c,
		"QBMServerTag", "UID_QBMServerTag", "ServerTag",
		exml.EncodingOptions{
			NoContent: true,
			F_Attrs: makeAttrFn(
				map[string]string{"id": "UID_QBMServerTag", "name": "Ident_QBMServerTag"},
			),
			F_Content: func(tag_c *exml.TableContext) {
				exml.EncodeRowAttribute(tag_c, "Description")
			},
		},
	)
}

func encodeScripts(config ExporterConfig, db *sqlx.DB, o io.Writer) error {

	config.dbg("DialogScript")
	rows, err := dbx.GetTableRows(db, "DialogScript", "1=1")
	if err != nil {
		return err
	}

	return exml.EncodeTable("Script", db, rows, o,
		exml.EncodingOptions{
			NoContent: true,
			F_Attrs: makeAttrFn(
				map[string]string{"name": "ScriptName", "id": "UID_DialogScript"},
				[]string{"IsLocked"},
			),
			F_Content: func(s_c *exml.TableContext) {
				exml.EncodeRowAttribute(s_c, "Description")
				exml.EncodeRowAttribute(s_c, "ScriptCode")
			},
		},
	)
}

func encodeMailTemplates(config ExporterConfig, db *sqlx.DB, o io.Writer) error {

	config.dbg("DialogRichMail")
	rows, err := dbx.GetTableRows(db, "DialogRichMail", "1=1")
	if err != nil {
		return err
	}

	return exml.EncodeTable("MailTemplate", db, rows, o,
		exml.EncodingOptions{
			F_Attrs: makeAttrFn(
				map[string]string{"name": "Ident_DialogRichMail", "id": "UID_DialogRichMail"},
				[]string{"TargetFormat", "Importance", "Sensitivity"},
			),
			F_Content: func(rm_c *exml.TableContext) {
				exml.EncodeRowAttribute(rm_c, "Description")
				encodeTableReference(rm_c, "UID_DialogTableBaseObject", "BaseTable")
				encodeObjectPatches(rm_c)

				exml.EncodeForeignTable(rm_c, "DialogRichMailBody", "UID_DialogRichMail", "MailBody",
					exml.EncodingOptions{
						NoContent:        true,
						PluralObjectName: "MailBodies",
						F_Attrs: makeAttrFn(
							map[string]string{"subject": "RichMailSubject", "id": "UID_DialogRichMailBody"},
						),
						F_Content: func(rmb_c *exml.TableContext) {
							exml.EncodeRowAttribute(rmb_c, "RichMailBody")
							encodeObjectPatches(rmb_c)
							exml.EncodeFKReference(rmb_c,
								"QBMCulture", "UID_DialogCulture", "Culture",
								exml.EncodingOptions{
									NoContent: true,
									F_Attrs: makeAttrFn(map[string]string{
										"id":          "UID_DialogCulture",
										"name":        "Ident_DialogCulture",
										"displayName": "DisplayName",
										"nativeName":  "NativeName",
									}),
								},
							)
						},
					},
				)

			},
		},
	)
}

func encodeLimitedSQL(config ExporterConfig, db *sqlx.DB, o io.Writer) error {

	config.dbg("QBMLimitedSQL")
	rows, err := dbx.GetTableRows(db, "QBMLimitedSQL", "1=1")
	if err != nil {
		return err
	}

	return exml.EncodeTable("LimitedSQLScript", db, rows, o,
		exml.EncodingOptions{
			F_Attrs: makeAttrFn(
				map[string]string{
					"name": "Ident_QBMLimitedSQL",
					"id":   "UID_QBMLimitedSQL",
					"type": "TypeOfLimitedSQL",
				},
			),
			F_Content: func(lsql_c *exml.TableContext) {
				exml.EncodeRowAttribute(lsql_c, "Description")
				exml.EncodeRowAttribute(lsql_c, "SQLContent")
			},
		},
	)
}

func encodeChangeLabels(config ExporterConfig, db *sqlx.DB, o io.Writer) error {

	config.dbg("DialogTag")
	rows, err := dbx.GetTableRows(db, "DialogTag", "1=1")
	if err != nil {
		return err
	}

	return exml.EncodeTable("ChangeLabel", db, rows, o,
		exml.EncodingOptions{
			NoContent: true,
			F_Attrs:   stdTagAttrs,
			F_Content: func(cl_c *exml.TableContext) {
				exml.EncodeRowAttribute(cl_c, "Description")
				exml.EncodeRowAttribute(cl_c, "Commentary")
				exml.EncodeCRReference(cl_c,
					"DialogTag", "UID_DialogTagParent", "UID_DialogTag", "Parent",
					exml.EncodingOptions{
						NoContent: true,
						F_Attrs:   stdTagAttrs,
					},
				)
				exml.EncodeForeignTable(cl_c,
					"DialogTaggedItem", "UID_DialogTag", "TaggedItem",
					exml.EncodingOptions{
						NoContent: true,
						F_Attrs: makeAttrFn(
							map[string]string{"id": "UID_TaggedItem"},
							[]string{"SortOrder", "IsDelete"},
						),
						F_Content: func(ti_c *exml.TableContext) {
							encodeObjectKeyReference(ti_c, "ObjectKey", "Object",
								[]string{"Name", "ScriptName", "ColumnName", "TableName", "FileName", "RelationID", "ConfigParm"},
							)
						},
					},
				)

				exml.EncodeForeignTable(cl_c,
					"QBMTaggedChange", "UID_DialogTag", "TaggedChange",
					exml.EncodingOptions{
						NoContent: true,
						F_Attrs: makeAttrFn(
							map[string]string{"id": "UID_QBMTaggedChange"},
							[]string{"SortOrder"},
						),
						F_Content: func(tc_c *exml.TableContext) {
							encodeObjectKeyReference(tc_c, "ObjectKey", "Object",
								[]string{"Name", "ScriptName", "ColumnName", "TableName", "FileName", "RelationID", "ConfigParm"},
							)
							// ChangeContent is likely to be non-conformant
							//exml.EncodeRawAttribute(ti_c, "ChangeContent")
						},
					},
				)
			},
		},
	)
}

func stdTagAttrs(c *exml.TableContext) ([]xml.Attr, error) {
	f := makeAttrFn(
		map[string]string{"name": "Ident_DialogTag", "id": "UID_DialogTag", "type": "TagType"},
		[]string{"IsClosed"},
	)
	return f(c)
}
