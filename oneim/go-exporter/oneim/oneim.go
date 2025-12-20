package oneim

import (
    "regexp"
)


// attributes with create/update metadata
var ATTR_Metadata = []string{ "XDateInserted", "XUserInserted", "XDateUpdated", "XUserUpdated" }
// for use in f_attr, to include metadata as element attrs in xml 
var MAP_Metadata = makeMetaMap()
func makeMetaMap() map[string]string {
    m := make(map[string]string, len(ATTR_Metadata))
    for _, e := range ATTR_Metadata { m[e] = e }
    return m
}

// deconstruct object key (many-to-many tables not yet supported)
func GetKeyParts(objectKey string) (t string, ids []string) {

    // table name
	re_t := regexp.MustCompile(`<Key><T>([A-Za-z-]+)</T>`)
    if ! re_t.MatchString(objectKey) {
        return "", nil
    }
    t = re_t.FindStringSubmatch(objectKey)[1]


    // primary keys
	re_p := regexp.MustCompile(`<P>([A-Za-z0-9-]+)</P>`)
    if ! re_p.MatchString(objectKey) {
        return "", nil
    }

    match_p := re_p.FindAllStringSubmatch(objectKey, -1)

    // extract keys from matches -- each match element includes: [0] = matched string, [1] = subgroup in match
    ids = make([]string, len(match_p), len(match_p))
    for i, e := range match_p {
        ids[i] = e[1]
    }


    return t, ids
}



