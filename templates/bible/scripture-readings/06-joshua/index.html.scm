(use-modules (scripts lib html)
             (scripts lib dirs))

(define script-dir (dirname (car (command-line))))
(define book-dir-name (basename script-dir))
(define book-display-name (dir-name->display-name book-dir-name))
(define url-prefix (string-append "/bible/scripture-readings/" book-dir-name))

(define md-files (list-md-files script-dir))

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
