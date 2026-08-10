;; Copyright (C) 2026

(define-module (scripts lib bible)
  #:use-module (scripts lib md)
  #:use-module (ice-9 rdelim)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-9)
  #:use-module (srfi srfi-13)
  #:export (book?
            book-order
            book-display-name
            book-kjv-abbrev
            book-slug
            bible-books
            book-by-display-name
            book-by-kjv-abbrev
            verse?
            make-verse
            verse-book
            verse-chapter
            verse-number
            verse-text
            verse-anchor-id
            version?
            version-id
            version-title
            version-source-path
            version-output-path
            version-header-line-count
            version-attribution-line-count
            bible-versions
            version-by-id
            parse-bible-file))

;;; ---------------------------------------------------------------------------
;;; Books
;;;
;;; The display name is the single canonical name set shared by every version,
;;; so a given verse resolves to the same anchor id no matter which version's
;;; page it appears on (KJV "Psa" and "SSol" become "Psalm" and "Song of
;;; Solomon", matching the Berean Standard Bible's own names).
;;; ---------------------------------------------------------------------------

(define-record-type <book>
  (make-book order display-name kjv-abbrev)
  book?
  (order book-order)
  (display-name book-display-name)
  (kjv-abbrev book-kjv-abbrev))

(define %book-table
  ;; (display-name . kjv-abbreviation), in canonical order.
  '(("Genesis" . "Ge")
    ("Exodus" . "Exo")
    ("Leviticus" . "Lev")
    ("Numbers" . "Num")
    ("Deuteronomy" . "Deu")
    ("Joshua" . "Josh")
    ("Judges" . "Jdgs")
    ("Ruth" . "Ruth")
    ("1 Samuel" . "1Sm")
    ("2 Samuel" . "2Sm")
    ("1 Kings" . "1Ki")
    ("2 Kings" . "2Ki")
    ("1 Chronicles" . "1Chr")
    ("2 Chronicles" . "2Chr")
    ("Ezra" . "Ezra")
    ("Nehemiah" . "Neh")
    ("Esther" . "Est")
    ("Job" . "Job")
    ("Psalm" . "Psa")
    ("Proverbs" . "Prv")
    ("Ecclesiastes" . "Eccl")
    ("Song of Solomon" . "SSol")
    ("Isaiah" . "Isa")
    ("Jeremiah" . "Jer")
    ("Lamentations" . "Lam")
    ("Ezekiel" . "Eze")
    ("Daniel" . "Dan")
    ("Hosea" . "Hos")
    ("Joel" . "Joel")
    ("Amos" . "Amos")
    ("Obadiah" . "Obad")
    ("Jonah" . "Jonah")
    ("Micah" . "Mic")
    ("Nahum" . "Nahum")
    ("Habakkuk" . "Hab")
    ("Zephaniah" . "Zep")
    ("Haggai" . "Hag")
    ("Zechariah" . "Zec")
    ("Malachi" . "Mal")
    ("Matthew" . "Mat")
    ("Mark" . "Mark")
    ("Luke" . "Luke")
    ("John" . "John")
    ("Acts" . "Acts")
    ("Romans" . "Rom")
    ("1 Corinthians" . "1Cor")
    ("2 Corinthians" . "2Cor")
    ("Galatians" . "Gal")
    ("Ephesians" . "Eph")
    ("Philippians" . "Phi")
    ("Colossians" . "Col")
    ("1 Thessalonians" . "1Th")
    ("2 Thessalonians" . "2Th")
    ("1 Timothy" . "1Tim")
    ("2 Timothy" . "2Tim")
    ("Titus" . "Titus")
    ("Philemon" . "Phmn")
    ("Hebrews" . "Heb")
    ("James" . "Jas")
    ("1 Peter" . "1Pet")
    ("2 Peter" . "2Pet")
    ("1 John" . "1Jn")
    ("2 John" . "2Jn")
    ("3 John" . "3Jn")
    ("Jude" . "Jude")
    ("Revelation" . "Rev")))

(define bible-books
  (map (lambda (entry order) (make-book order (car entry) (cdr entry)))
       %book-table
       (iota (length %book-table) 1)))

(define (book-slug book)
  "Return the URL slug for BOOK, e.g. \"1 Samuel\" -> \"1-samuel\".
Derived with the same rule the markdown renderer uses for heading ids, so a
chapter heading and its verses share a consistent anchor namespace."
  (text->id (book-display-name book)))

(define (book-by-display-name name)
  "Look up a book by its canonical display name, or #f."
  (find (lambda (book) (string=? (book-display-name book) name)) bible-books))

(define (book-by-kjv-abbrev abbrev)
  "Look up a book by its KJV source abbreviation, or #f."
  (find (lambda (book) (string=? (book-kjv-abbrev book) abbrev)) bible-books))

;;; ---------------------------------------------------------------------------
;;; Verses
;;; ---------------------------------------------------------------------------

(define-record-type <verse>
  (make-verse book chapter number text)
  verse?
  (book verse-book)
  (chapter verse-chapter)
  (number verse-number)
  (text verse-text))

(define (verse-anchor-id verse)
  "Return the anchor id for VERSE, e.g. \"1-samuel-3-10\"."
  (string-append (book-slug (verse-book verse))
                 "-" (number->string (verse-chapter verse))
                 "-" (number->string (verse-number verse))))

;;; ---------------------------------------------------------------------------
;;; Versions
;;; ---------------------------------------------------------------------------

(define-record-type <version>
  (make-version id title source-path output-path header-line-count attribution-line-count)
  version?
  (id version-id)
  (title version-title)
  (source-path version-source-path)
  (output-path version-output-path)
  ;; Leading lines of the source that are not verses, and how many of those are
  ;; attribution prose worth reproducing on the rendered page. The BSB's third
  ;; header line is a tab-separated column header, not attribution.
  (header-line-count version-header-line-count)
  (attribution-line-count version-attribution-line-count))

(define bible-versions
  (list
   (make-version "bsb"
                 "Berean Standard Bible"
                 "assets/bible/data/versions/bsb.txt"
                 "templates/bible/versions/bsb/text/index.md"
                 3
                 2)
   (make-version "kjv"
                 "King James Version"
                 "assets/bible/data/versions/kjv.txt"
                 "templates/bible/versions/kjv/text/index.md"
                 1
                 1)))

(define (version-by-id id)
  "Look up a version by its short id (\"bsb\", \"kjv\"), or #f."
  (find (lambda (version) (string=? (version-id version) id)) bible-versions))

;;; ---------------------------------------------------------------------------
;;; Parsing
;;; ---------------------------------------------------------------------------

(define (parse-error path line-number line message)
  (error (format #f "~a:~a: ~a~%  line: ~s" path line-number message line)))

(define (parse-reference path line-number line reference)
  "Split a \"<book><sep><chapter>:<verse>\" REFERENCE into (book-name chapter verse).
Handles both \"Genesis 1:1\" and \"Ge1:1\" by scanning back from the colon over
the chapter digits, which leaves the book name as whatever precedes them."
  (let ((colon (string-index reference #\:)))
    (unless colon
      (parse-error path line-number line "verse reference has no ':' separator"))
    (let loop ((chapter-start colon))
      (cond
       ((and (> chapter-start 0)
             (char-numeric? (string-ref reference (- chapter-start 1))))
        (loop (- chapter-start 1)))
       ((= chapter-start colon)
        (parse-error path line-number line "verse reference has no chapter number"))
       (else
        (let ((book-name (string-trim-right (substring reference 0 chapter-start)))
              (chapter (string->number (substring reference chapter-start colon)))
              (verse (string->number (substring reference (+ colon 1)))))
          (when (string-null? book-name)
            (parse-error path line-number line "verse reference has no book name"))
          (unless (and chapter verse)
            (parse-error path line-number line "verse reference has a non-numeric chapter or verse"))
          (list book-name chapter verse)))))))

(define (parse-bsb-line path line-number line)
  "Parse a tab-separated BSB line: \"Genesis 1:1\\tIn the beginning...\"."
  (let ((tab (string-index line #\tab)))
    (unless tab
      (parse-error path line-number line "expected a tab between reference and verse text"))
    (let* ((reference (string-trim-both (substring line 0 tab)))
           (text (string-trim-both (substring line (+ tab 1))))
           (parts (parse-reference path line-number line reference))
           (book (book-by-display-name (car parts))))
      (unless book
        (parse-error path line-number line
                     (format #f "unrecognized book name ~s" (car parts))))
      (make-verse book (cadr parts) (caddr parts) text))))

(define (parse-kjv-line path line-number line)
  "Parse a space-separated KJV line: \"Ge1:1 In the beginning...\"."
  (let ((space (string-index line #\space)))
    (unless space
      (parse-error path line-number line "expected a space between reference and verse text"))
    (let* ((reference (substring line 0 space))
           (text (string-trim-both (substring line (+ space 1))))
           (parts (parse-reference path line-number line reference))
           (book (book-by-kjv-abbrev (car parts))))
      (unless book
        (parse-error path line-number line
                     (format #f "unrecognized book abbreviation ~s" (car parts))))
      (make-verse book (cadr parts) (caddr parts) text))))

(define (line-parser-for version path)
  (cond
   ((string=? (version-id version) "bsb") parse-bsb-line)
   ((string=? (version-id version) "kjv") parse-kjv-line)
   (else (error (format #f "no line parser for version ~s (~a)"
                        (version-id version) path)))))

(define %markdown-active-chars
  ;; Characters the markdown renderer would reinterpret. It has no backslash
  ;; escape, so there is no safe way to emit these -- fail loudly instead of
  ;; silently producing mangled output if a source text ever grows one.
  (string->char-set "*_[]`{}"))

(define (check-verse-text path line-number line verse)
  (when (string-index (verse-text verse) %markdown-active-chars)
    (parse-error path line-number line
                 "verse text contains a markdown-active character (*_[]`{}) which the renderer cannot escape"))
  verse)

(define (parse-bible-file version)
  "Read VERSION's source file and return two values: the list of header lines
\(source attribution, preserved verbatim) and the list of parsed verses.
Every non-header line must parse; anything unrecognized raises an error naming
the file, line number, and offending line."
  (let ((path (version-source-path version)))
    (unless (file-exists? path)
      (error (format #f "missing Bible source text: ~a~%  expected the plain-text version file to be present in the repository"
                     path)))
    (let ((parse-line (line-parser-for version path))
          (header-count (version-header-line-count version)))
      (call-with-input-file path
        (lambda (port)
          (let loop ((line-number 1) (headers '()) (verses '()))
            (let ((line (read-line port)))
              (cond
               ((eof-object? line)
                (values (reverse headers) (reverse verses)))
               ((<= line-number header-count)
                (loop (+ line-number 1)
                      (cons (string-trim-both line) headers)
                      verses))
               ((string-null? (string-trim-both line))
                (loop (+ line-number 1) headers verses))
               (else
                (loop (+ line-number 1)
                      headers
                      (cons (check-verse-text path line-number line
                                              (parse-line path line-number line))
                            verses)))))))))))
