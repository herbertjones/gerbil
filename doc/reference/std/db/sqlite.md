# SQLite driver

::: tip usage
```scheme
(import :std/db/dbi
        :std/db/sqlite)
```
:::

Have a look at [the sqlite-test.ss file](https://github.com/mighty-gerbils/gerbil/blob/master/src/std/db/sqlite-test.ss) to see more of how it is used with the `:std/db/dbi`.

## sqlite-open
This is used typically with the wrapper [sql-connect](/reference/std/db/dbi.html#sql-connect).

```scheme
(sqlite-open file
             (flags (fxior SQLITE_OPEN_READWRITE SQLITE_OPEN_CREATE)))
  => sqlite-connection
```

## Larger Example

::: tip example
```scheme
#!/usr/bin/env gxi
(import (only-in :std/db/dbi
                 sql-connect
                 sql-eval
                 sql-eval-query)
        (only-in :std/db/sqlite sqlite-open))
(export main)

;; The current database version.  When changes occur, increment and add a way to
;; upgrade in initialize-database.
(defconst database-version 1)

;; Global database connection.  Setup in main.
(def db #f)

(def (main . args)
  (set! db (sql-connect sqlite-open (path-expand "/tmp/test.sqlite")))
  (initialize-database)
  (displayln (get-database-version)))

;; Get the current database version.  Returns 0 if not initialized.
(def (get-database-version)
  => :fixnum
  (if (not (table-exists? "meta"))
    0
    (let (version (get-meta "database-version"))
      (if version
        (string->number version)
        0))))

;; Check if table exists by name.
(def (table-exists? table-name)
  => :boolean
  (let (query #<<EOQ
SELECT
    name
FROM
    sqlite_master
WHERE
    type='table'
  AND
    name=?
EOQ
       )
    (not (null-list? (sql-eval-query db query table-name)))))

;; Create the "meta" table.
(def (create-meta-table)
  => :void
  (let (query #<<EOQ
CREATE TABLE meta (
  property TEXT PRIMARY KEY,
  value TEXT,
  updated TEXT
)
EOQ
       )
    (sql-eval db query)
    (set-meta "database-version" database-version)))

;; Set a property in the meta table
(def (set-meta property value)
  (let (query #<<EOQ
INSERT OR REPLACE INTO
    meta
(
   property,
   value,
   updated
)
VALUES (?,?,datetime("now"))
EOQ
       )
    (sql-eval db query property value)))

;; Get a property in the meta table.  Returns a string or #f if not found.
(def (get-meta property)
  (let* ((query #<<EOQ
SELECT
  value
FROM
  meta
WHERE
  property=?
EOQ
         )
         (result (sql-eval-query db query property)))
    (if (null-list? result)
      #f
      (car result))))

(def (initialize-database)
  (let (initial-version (get-database-version))
    (cond ((eqv? initial-version database-version) ;; Already current
           #t)
          ((eqv? initial-version 0) ;; Initial setup
           (create-meta-table))
          (else ;; Upgrades
           ;; In the future when there is a version 2...
           (when (eqv? (get-database-version) 1)
             (set-meta "database-version" 2))))))

```
:::
