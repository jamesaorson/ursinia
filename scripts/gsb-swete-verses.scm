;; Copyright (C) 2026
;;
;; Turn one book's Swete page files (gsb/sources/swete/pages/<book>/*.txt, one
;; printed line per text line) into a verse table (chapter<TAB>verse<TAB>text)
;; in the common numbering. A preview tool: `./scripts/gsb-swete.sh merge`
;; builds the committed tables (done pages only). Invoked through
;; ./scripts/gsb-swete-verses.sh. Page format: gsb/sources/swete/README.md.

(use-modules (scripts lib swete)
             (ice-9 ftw)
             (ice-9 match)
             (ice-9 format)
             (ice-9 textual-ports)
             (srfi srfi-1)
             (srfi srfi-13))

(define %program "gsb-swete-verses")

(define (usage port)
  (format port "Usage: ./scripts/gsb-swete-verses.sh PAGE-DIR [OUT.tsv]~%~%")
  (format port "Join the page files in PAGE-DIR (sorted by name) into one row per verse,~%")
  (format port "chapter<TAB>verse<TAB>text, in the common numbering: Swete's {N} gives his~%")
  (format port "chapter:N, a {=c:v} marker (his parenthesized margin number) overrides it.~%")
  (format port "Without OUT.tsv the table goes to stdout; with it, OUT.tsv is written only if~%")
  (format port "it changes. Every page in the directory is used, done or not, so a gap in~%")
  (format port "the pages glues text across it; ./scripts/gsb-swete.sh merge does not.~%~%")
  (format port "Examples:~%")
  (format port "  ./scripts/gsb-swete-verses.sh gsb/sources/swete/pages/gen | less~%")
  (format port "  ./scripts/gsb-swete-verses.sh gsb/sources/swete/pages/dan-th /tmp/dan-th.tsv~%"))

(define (die fmt . args)
  (format (current-error-port) "~a: ~?~%" %program fmt args)
  (exit 1))

(define (pages dir)
  (unless (and (file-exists? dir) (eq? 'directory (stat:type (stat dir))))
    (die "no page directory ~a~%  transcribe pages there first (see .claude/skills/gsb-transcribe/SKILL.md)" dir))
  (match (sort (filter (lambda (f) (string-suffix? ".txt" f)) (or (scandir dir) '())) string<?)
    (() (die "~a has no *.txt page files~%  transcribe pages there first" dir))
    (names (map (lambda (f)
                  (cons (or (string->number (string-take-right (basename f ".txt") 4)) 0)
                        (parse-page (call-with-input-file (string-append dir "/" f) get-string-all))))
                names))))

(define (render rows)
  (string-append
   "chapter\tverse\ttext\n"
   (string-concatenate (map (lambda (r) (format #f "~a\t~a\t~a~%" (first r) (second r) (third r))) rows))))

(define (main args)
  (match (cdr args)
    ((or () ("-h") ("--help"))
     (usage (if (null? (cdr args)) (current-error-port) (current-output-port)))
     (exit (if (null? (cdr args)) 2 0)))
    ((dir . out)
     (when (> (length out) 1) (usage (current-error-port)) (exit 2))
     (call-with-values (lambda () (book-verses (pages dir)))
       (lambda (rows problems)
         (for-each (match-lambda ((leaf line sev msg) (format (current-error-port) "~a: leaf ~a line ~a: ~a~%" %program leaf line msg)))
                   problems)
         (unless (null? problems) (die "fix the page files above, then rerun"))
         (let ((text (render rows)))
           (match out
             (() (display text))
             ((path)
              (unless (and (file-exists? path) (string=? text (call-with-input-file path get-string-all)))
                (call-with-output-file path (lambda (p) (display text p)))
                (format (current-error-port) "~a: wrote ~a~%" %program path))))))))))

(main (command-line))
