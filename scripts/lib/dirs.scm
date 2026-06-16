(define-module (scripts lib dirs)
  #:use-module (ice-9 ftw)
  #:use-module (ice-9 rdelim)
  #:use-module (srfi srfi-13)
  #:export (dir-name->display-name
            list-subdirs
            list-md-files
            read-frontmatter-title))

(define (string-numeric? s)
  (string-every char-numeric? s))

(define (dir-name->display-name name)
  "Convert a directory name like '08-ruth' or '47-2-corinthians' to a display
name like 'Ruth' or '2 Corinthians', stripping a leading numeric catalog prefix."
  (let* ((dash-pos (string-index name #\-))
         (rest (if (and dash-pos (string-numeric? (substring name 0 dash-pos)))
                   (substring name (+ dash-pos 1))
                   name))
         (parts (string-split rest #\-))
         (words (map (lambda (p) (if (string-numeric? p) p (string-capitalize p))) parts)))
    (string-join words " ")))

(define (list-subdirs dir)
  "Return a sorted list of subdirectory names inside DIR, excluding . and .."
  (sort
   (filter (lambda (name)
             (and (not (string=? name "."))
                  (not (string=? name ".."))
                  (eq? 'directory (stat:type (stat (string-append dir "/" name))))))
           (or (scandir dir) '()))
   string<?))

(define %ignored-md-files '("README.md" "AGENTS.md" "CLAUDE.md"))

(define (list-md-files dir)
  "Return a sorted list of .md filenames in DIR, excluding README/AGENTS/CLAUDE."
  (sort
   (filter (lambda (name)
             (and (string-suffix? ".md" name)
                  (not (member name %ignored-md-files))))
           (or (scandir dir) '()))
   string<?))

(define (read-frontmatter-title path)
  "Read the 'title:' value from YAML frontmatter in the file at PATH.
Returns a string, or #f if no frontmatter or no title key is found."
  (call-with-input-file path
    (lambda (port)
      (let ((first-line (string-trim-right (read-line port))))
        (if (string=? first-line "---")
            (let loop ()
              (let ((line (read-line port)))
                (cond
                 ((eof-object? line) #f)
                 ((string=? (string-trim-right line) "---") #f)
                 ((string-prefix? "title:" line)
                  (string-trim (substring line 6)))
                 (else (loop)))))
            #f)))))
