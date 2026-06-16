(use-modules (scripts lib html)
             (ice-9 ftw)
             (ice-9 rdelim)
             (srfi srfi-13))

(define script-path (car (command-line)))
(define script-dir (dirname script-path))
(define book-dir-name (basename script-dir))

(define (string-numeric? s)
  (string-every char-numeric? s))

(define (dir-name->display-name name)
  (let* ((dash-pos (string-index name #\-))
         (rest (if (and dash-pos (string-numeric? (substring name 0 dash-pos)))
                   (substring name (+ dash-pos 1))
                   name))
         (parts (string-split rest #\-))
         (words (map (lambda (p) (if (string-numeric? p) p (string-capitalize p))) parts)))
    (string-join words " ")))

(define book-display-name (dir-name->display-name book-dir-name))
(define url-prefix (string-append "/bible/scripture-readings/" book-dir-name))

(define (read-frontmatter-title path)
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

(define (list-md-files dir)
  (filter (lambda (name)
            (and (string-suffix? ".md" name)
                 (not (member name '("README.md" "AGENTS.md" "CLAUDE.md")))))
          (or (scandir dir) '())))

(define md-files (sort (list-md-files script-dir) string<?))

(define (md-file->link-item filename)
  (let* ((stem (substring filename 0 (- (string-length filename) 3)))
         (url (string-append url-prefix "/" stem))
         (title (or (read-frontmatter-title (string-append script-dir "/" filename)) stem)))
    `(li (a (@ (href ,url)) ,title))))

(render-template (string-append "Ursinia - Bible - " book-display-name) "bible"
                 `((header
                     (div (@ (id "header"))
                          (span (@ (id "header-back"))
                                (a (@ (id "header-back-link")
                                      (href "/bible/scripture-readings"))
                                   #\↤ " " (code "scripture-readings")))))
                   (h1
                     (a (@ (id "title")
                           (href "#title")
                           (class "list-item-internal-link"))
                        ,book-display-name))
                   (div
                     (ul ,@(map md-file->link-item md-files)))))
