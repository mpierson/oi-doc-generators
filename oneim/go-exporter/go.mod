go 1.25

module pso.oneidentity.com/oneim-exporter

replace pso.oneidentity.com/ois => ./ois

replace pso.oneidentity.com/oneim => ./oneim

replace pso.oneidentity.com/oneim/dbx => ./oneim/dbx

replace pso.oneidentity.com/oneim/exml => ./oneim/exml

require (
	github.com/jmoiron/sqlx v1.4.0
	github.com/microsoft/go-mssqldb v1.8.2
	pso.oneidentity.com/oneim v0.0.0-00010101000000-000000000000
)

require (
	github.com/DataDog/zstd v1.5.7 // indirect
	github.com/beorn7/perks v1.0.1 // indirect
	github.com/buger/jsonparser v1.1.1 // indirect
	github.com/cespare/xxhash/v2 v2.3.0 // indirect
	github.com/chaisql/chai v0.17.0 // indirect
	github.com/cockroachdb/crlib v0.0.0-20250718215705-7ff5051265b9 // indirect
	github.com/cockroachdb/errors v1.12.0 // indirect
	github.com/cockroachdb/fifo v0.0.0-20240816210425-c5d0cb0b6fc0 // indirect
	github.com/cockroachdb/logtags v0.0.0-20241215232642-bb51bb14a506 // indirect
	github.com/cockroachdb/pebble/v2 v2.0.7 // indirect
	github.com/cockroachdb/redact v1.1.6 // indirect
	github.com/cockroachdb/swiss v0.0.0-20250624142022-d6e517c1d961 // indirect
	github.com/cockroachdb/tokenbucket v0.0.0-20250429170803-42689b6311bb // indirect
	github.com/dromara/carbon/v2 v2.6.11 // indirect
	github.com/getsentry/sentry-go v0.35.1 // indirect
	github.com/gogo/protobuf v1.3.2 // indirect
	github.com/golang-sql/civil v0.0.0-20220223132316-b832511892a9 // indirect
	github.com/golang-sql/sqlexp v0.1.0 // indirect
	github.com/golang/snappy v1.0.0 // indirect
	github.com/google/uuid v1.6.0 // indirect
	github.com/klauspost/compress v1.18.0 // indirect
	github.com/kr/pretty v0.3.1 // indirect
	github.com/kr/text v0.2.0 // indirect
	github.com/munnerz/goautoneg v0.0.0-20191010083416-a7dc8b61c822 // indirect
	github.com/pkg/errors v0.9.1 // indirect
	github.com/prometheus/client_golang v1.23.0 // indirect
	github.com/prometheus/client_model v0.6.2 // indirect
	github.com/prometheus/common v0.65.0 // indirect
	github.com/prometheus/procfs v0.17.0 // indirect
	github.com/rogpeppe/go-internal v1.14.1 // indirect
	golang.org/x/crypto v0.43.0 // indirect
	golang.org/x/exp v0.0.0-20250813145105-42675adae3e6 // indirect
	golang.org/x/net v0.46.0 // indirect
	golang.org/x/sys v0.37.0 // indirect
	golang.org/x/text v0.30.0 // indirect
	google.golang.org/protobuf v1.36.7 // indirect
	pso.oneidentity.com/ois v0.0.0-00010101000000-000000000000 // indirect
)
