;; Copyright (C) 2026
;;
;; Build the Greek Source Bible database (schema and data dictionary:
;; gsb/schema.sql) from the text files under gsb/. The database is what every
;; GSB page is rendered from (scripts/gsb-site.scm) and what readers download.
;; Invoked through ./scripts/gsb-db.sh (make gsb/db).

(use-modules (scripts lib gsb-db)
             (ice-9 format))

(fluid-set! %default-port-encoding "UTF-8")

(define %default-out "wwwroot/bible/versions/gsb/data/gsb.sqlite")

(define (usage port)
  (format port "Usage: ./scripts/gsb-db.sh [OUT]       build the database (default ~a)~%" %default-out)
  (format port "       ./scripts/gsb-db.sh doctor    check that sqlite3 is new enough~%~%")
  (format port "Reads gsb/books.tsv, gsb/greek/, gsb/lexicon/, gsb/translation/, gsb/reports/,~%")
  (format port "gsb/sources/*/README.md and gsb/sources/swete/ (verse tables, page files, logs).~%")
  (format port "Normally run as `make gsb/db` (part of `make gsb/site` and `make render`).~%"))

(define (check-sqlite3)
  (let ((problem (sqlite3-problem)))
    (when problem
      (format (current-error-port) "gsb-db: ~a~%" problem)
      (exit 1))))

(define (main args)
  (match-args (cdr args)))

(define (match-args args)
  (cond
   ((or (member "-h" args) (member "--help" args)) (usage (current-output-port)) (exit 0))
   ((equal? args '("doctor")) (check-sqlite3) (format #t "sqlite3: ok (JSON and FTS5 available)~%"))
   ((> (length args) 1) (usage (current-error-port)) (exit 2))
   ((not (file-exists? "gsb/books.tsv"))
    (format (current-error-port) "gsb-db: gsb/books.tsv not found; run from the repo root (make gsb/db)~%")
    (exit 1))
   (else
    (check-sqlite3)
    (let ((out (if (null? args) %default-out (car args))))
      (build-database! out)
      (format #t "GSB: ~a~%" out)))))

(main (command-line))
