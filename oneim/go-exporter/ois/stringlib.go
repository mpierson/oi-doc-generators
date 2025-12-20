package ois

import (
	"log"
	"strings"
)

// return map of key-value pairs from string - key=val;key=val;...
// s1 - pair separator
// s2 - key-value separator
func DecodeMap(s string, sep1 string, sep2 string) map[string]string {

	if len(s) == 0 {
		log.Println("empty map string")
		return nil
	}

	// parse into pairs
	pairs := strings.Split(s, sep1)
	// TODO: any weird cases to handle here?

	// container for key-value pairs
	var m map[string]string
	m = make(map[string]string, len(pairs))

	// decode each pair
	for _, v := range pairs {

		if !strings.Contains(v, sep2) {
			log.Println("unexpected content in k-v pair: " + v)
			return nil
		}

		// Cut returns values around first instance of sep2
		key, val, ok := strings.Cut(v, sep2)
		if ok {
			m[key] = val
		}
	}

	return m
}
