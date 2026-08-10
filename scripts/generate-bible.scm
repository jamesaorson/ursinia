;; Copyright (C) 2026
;;
;; Generate one amalgamated markdown file per Bible version from the plain-text
;; sources in assets/bible/data/versions/. Output is deterministic: a run that
;; would not change a file leaves it untouched, so `make render` does not
;; re-render several megabytes of markdown for nothing.
;;
;; Invoked through ./scripts/generate-bible, which anchors the working directory
;; to the repo root so the relative paths in (scripts lib bible) resolve.

(use-modules (scripts lib bible)
             (ice-9 format)
             (ice-9 getopt-long)
             (ice-9 textual-ports)
             (srfi srfi-1)
             (srfi srfi-13))

(define %program "generate-bible")

(define (usage port)
  (format port "Usage: ./scripts/~a [OPTIONS] [VERSION ...]~%" %program)
  (format port "~%")
  (format port "Generate an amalgamated markdown file for each Bible version from its~%")
  (format port "plain-text source. With no VERSION arguments, every version is generated.~%")
  (format port "~%")
  (format port "Options:~%")
  (format port "  -h, --help         Show this help~%")
  (format port "  -v, --version ID   Generate only version ID (repeatable)~%")
  (format port "  -c, --check        Report whether output is up to date; write nothing.~%")
  (format port "                     Exits non-zero if any file would change.~%")
  (format port "~%")
  (format port "Versions:~%")
  (for-each (lambda (version)
              (format port "  ~a~va~a~%"
                      (version-id version)
                      (max 1 (- 8 (string-length (version-id version)))) " "
                      (version-title version)))
            bible-versions)
  (format port "~%")
  (format port "Examples:~%")
  (format port "  make bible                 Generate every version~%")
  (format port "  make bible/check           Verify committed output is up to date~%")
  (format port "  ./scripts/~a bsb~%" %program))

(define (die message)
  (format (current-error-port) "~a: ~a~%" %program message)
  (exit 1))

(define (mkdir-p path)
  "Create PATH and any missing parent directories."
  (unless (or (string-null? path) (string=? path "/") (file-exists? path))
    (mkdir-p (dirname path))
    (mkdir path)))

;;; ---------------------------------------------------------------------------
;;; Markdown rendering
;;; ---------------------------------------------------------------------------

;; Some sources keep a placeholder row for verses their editors judge to be later
;; additions -- the reference is present, the text is empty (16 such rows in the
;; BSB, none in the KJV). Keeping the slot preserves both the surrounding verse
;; numbering and cross-version anchor parity, so a link to the reference still
;; resolves on either version's page.
(define %omitted-verse-note "*Not found in the earliest manuscripts.*")

;; The verse number is itself a link to the verse's own anchor: it renders as an
;; ordinary link, so it is visibly clickable and a reader can lift a shareable
;; URL straight out of the address bar. The id stays on the paragraph so the
;; whole verse remains the scroll target.
(define (write-verse port verse)
  (let* ((text (verse-text verse))
         (body (if (string-null? text) %omitted-verse-note text))
         (anchor (verse-anchor-id verse)))
    (format port "**[~a](#~a)** ~a {#~a}~%~%"
            (verse-number verse)
            anchor
            body
            anchor)))

(define (render-version-markdown version headers verses)
  "Render VERSES as a single markdown document string."
  (call-with-output-string
    (lambda (port)
      (format port "---~%")
      (format port "title: ~a~%" (version-title version))
      ;; The renderer links bare scripture references in prose. On the scripture
      ;; itself that would be self-referential, so opt this page out.
      (format port "scripture-links: false~%")
      (format port "---~%~%")
      (for-each (lambda (line) (format port "~a~%~%" line))
                (take headers
                      (min (version-attribution-line-count version)
                           (length headers))))
      (let loop ((rest verses) (book #f) (chapter #f))
        (unless (null? rest)
          (let* ((verse (car rest))
                 (verse-book* (verse-book verse))
                 (verse-chapter* (verse-chapter verse))
                 (new-book? (not (eq? book verse-book*)))
                 (new-chapter? (or new-book? (not (eqv? chapter verse-chapter*)))))
            (when new-book?
              (format port "## ~a~%~%" (book-display-name verse-book*)))
            (when new-chapter?
              (format port "### ~a ~a~%~%"
                      (book-display-name verse-book*)
                      verse-chapter*))
            (write-verse port verse)
            (loop (cdr rest) verse-book* verse-chapter*)))))))

;;; ---------------------------------------------------------------------------
;;; Generation
;;; ---------------------------------------------------------------------------

(define (read-existing path)
  (and (file-exists? path)
       (call-with-input-file path get-string-all)))

(define (generate-version version check?)
  "Generate VERSION. Returns 'wrote, 'unchanged, or 'stale (check mode only)."
  (call-with-values
      (lambda () (parse-bible-file version))
    (lambda (headers verses)
      (let* ((markdown (render-version-markdown version headers verses))
             (path (version-output-path version))
             (existing (read-existing path))
             (up-to-date? (and existing (string=? existing markdown))))
        (cond
         (up-to-date?
          (format #t "  ~a: unchanged (~a verses)~%" (version-id version) (length verses))
          'unchanged)
         (check?
          (format #t "  ~a: OUT OF DATE (~a)~%"
                  (version-id version)
                  (if existing "content differs" "not generated yet"))
          'stale)
         (else
          (mkdir-p (dirname path))
          (call-with-output-file path
            (lambda (port) (display markdown port)))
          (format #t "  ~a: wrote ~a (~a verses, ~a bytes)~%"
                  (version-id version) path (length verses) (string-length markdown))
          'wrote))))))

(define (resolve-versions ids)
  "Turn a list of version id strings into version records, or die."
  (if (null? ids)
      bible-versions
      (map (lambda (id)
             (or (version-by-id id)
                 (die (format #f "unknown version ~s~%  known versions: ~a~%  run with --help for usage"
                              id
                              (string-join (map version-id bible-versions) ", ")))))
           ids)))

(define %option-spec
  '((help (single-char #\h) (value #f))
    (version (single-char #\v) (value #t))
    (check (single-char #\c) (value #f))))

(define (main args)
  (let* ((options (getopt-long args %option-spec))
         (help? (option-ref options 'help #f))
         (check? (option-ref options 'check #f))
         (positional (option-ref options '() '()))
         (flagged (filter-map (lambda (entry)
                                (and (eq? (car entry) 'version) (cdr entry)))
                              options))
         (ids (delete-duplicates (append flagged positional))))
    (when help?
      (usage (current-output-port))
      (exit 0))
    (let* ((versions (resolve-versions ids))
           (_ (format #t "~a: ~a version(s)~%"
                      (if check? "Checking" "Generating")
                      (length versions)))
           (results (map (lambda (version) (generate-version version check?)) versions)))
      (if (any (lambda (result) (eq? result 'stale)) results)
          (begin
            (format (current-error-port)
                    "~a: generated markdown is out of date -- run `make bible` to regenerate~%"
                    %program)
            (exit 1))
          (exit 0)))))

(main (command-line))
