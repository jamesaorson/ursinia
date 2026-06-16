(use-modules (scripts lib html)
             (scripts lib dirs))

(define script-dir (dirname (car (command-line))))

(define subdirs (list-subdirs script-dir))

(render-template "Ursinia - Bible - Scripture Readings" "bible"
                 `((header
                     (div (@ (id "header"))
                          (span (@ (id "header-back"))
                                (a (@ (id "header-back-link")
                                      (href "/bible"))
                                   #\↤ " " (code "bible")))))
                   (h1
                     (a (@ (id "title")
                           (href "#title")
                           (class "list-item-internal-link"))
                        "Scripture Readings"))
                   (div
                     (ul ,@(map (lambda (dir)
                                  `(li (a (@ (href ,(string-append "/bible/scripture-readings/" dir)))
                                          ,(dir-name->display-name dir))))
                                subdirs)))))

