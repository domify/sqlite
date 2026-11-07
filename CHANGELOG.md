# Unreleased

A second engine, libturso, on the same driver classes:

* `import sqlite/turso` registers the `turso:` scheme (`TursoDriver`,
  `TursoConnection`). It links a libturso built with its C symbols renamed
  `turso_*`, so `sqlite3:` and `turso:` connections work in one program.
* The classes are generic over the C binding (`SQLite3ConnectionOf(L)` and so
  on); `SQLite3Connection`, `SQLite3Driver` and the rest are aliases for the
  libsqlite3 ones. The binding is written once, as the `sqlite_lib` macro.
* On libturso, `regexp` is not registered (REGEXP is built in), an empty `Bytes`
  binds through `bind_blob`, `mutexed?` is false and `dump` returns an error.
* `SQLite3Connection::Options` is now `SQLite3Options`; `sqlite_filename(uri)`
  is the file a URI names.
* Requires db v0.3.1.

Ported to ris's memory rules, on the redesigned db:

* A connection belongs to the block and the task that opened it:
  `Db::Db.open(uri) { |db| ... }`. There is no pool, and `max_pool_size` and the
  other pool options do nothing. A task that wants its own connection opens one;
  `busy_timeout` makes them wait for each other's writes.
* There is no statement cache: each call prepares its statement and finalizes it.
* `SQLite3Connection#open` and `SQLite3Statement#prepare` do the IO after the
  object is built, in place of `SQLite3Connection.open` and
  `SQLite3Statement.prepare`. `SQLite3ConnectionBuilder` is gone.
* `SQLite3Error` is a flat struct with a message of at most 240 bytes.
  `ConnectionRefused` carries SQLite's message but no longer a cause.
* A `BLOB` column reads as a `String` of its bytes, also through `read(String)`
  (`bytesize`, `byte_at`, `each_byte` read them). `read(Bytes)` is gone.
* `REGEXP` compiles and matches in one task, so no `Regex` is copied across it.

Reset cached exec statements on success and failure so failed COMMIT cannot retain table locks.

SQLite3Connection#transaction_state reads sqlite3_get_autocommit: Idle or InTransaction. SQLite
does not expose a separate failed transaction state. Statements reject empty SQL and trailing SQL
before execution. Every execution clears cached bindings and requires exactly the parameter count
reported by SQLite; missing parameters return DBError rather than NULL or a previous value.

## v0.1.0

The first release of iyi-sqlite: crystal-sqlite3 0.24.0 ported to iyi, in
iyi, on iyi-db 0.1.1, with no Crystal code left.

* `sqlite3:` URIs open a file or `:memory:`; `busy_timeout`, `cache_size`,
  `foreign_keys`, `journal_mode`, `synchronous` and `wal_autocheckpoint` in
  the query run as PRAGMAs when a connection opens.
* Prepared statements with `?` arguments, transactions and savepoints,
  `last_insert_id` and `rows_affected`, `SQLite3Connection#dump` through the
  backup API, and a `regexp` function behind `REGEXP`.
* Every integer type, `Float32`, `Bool` and `Time` (as UTC text) read and
  bound as crystal-sqlite3 reads and binds them.

### What iyi's rules changed

* Errors are values: `SQLite3Error` (crystal-sqlite3's `SQLite3::Exception`)
  is a `DBError` with SQLite's `code`, and a connection that cannot be opened
  answers `ConnectionRefused` with it as the cause.
* The driver classes are `SQLite3Driver`, `SQLite3Connection`,
  `SQLite3Statement`, `SQLite3ResultSet` in `sqlite/core`, with the C binding
  private beside them.
* `Time` is written and read by `format_time` and `parse_time`; `Time.local`
  values are gone with the zones.
* An integer column a narrower type cannot hold answers
  `ColumnTypeMismatchError` where crystal-sqlite3 raised `OverflowError`.

### Fixed on the way

* Strings and blobs are bound `SQLITE_TRANSIENT`, so SQLite holds its own
  copy; crystal-sqlite3 bound them `SQLITE_STATIC` and kept references.
* An empty `Bytes` argument binds an empty blob, not `NULL`.
* `REGEXP` with a pattern `Regex` refuses answers an SQL error, and with a
  `NULL` operand answers `NULL`; crystal-sqlite3 raised through SQLite's
  frames and read a null pointer.
* A text column is read to its byte count, so a NUL inside it is kept.
* A handle `sqlite3_open_v2` allocated for a file it could not open is
  closed, and a failed `dump` finishes its backup.

crystal-sqlite3's history before the port is in its
[CHANGELOG](https://github.com/crystal-lang/crystal-sqlite3/blob/master/CHANGELOG.md).
