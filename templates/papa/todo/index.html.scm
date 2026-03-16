(use-modules (scripts lib html)
             (scripts lib task))

(define (render-list id)
   (task/render-list (format #f "~a/.tasks" (dirname (current-filename))) id))

(render-template "Ursinia - Papa - Todo" "papa"
                 `((header
                     (div (@ (id "header"))
                          (span (@ (id "header-back"))
                                (a (@ (id "header-back-link")
                                      (href ".."))
                                   #\↤ " " (code "papa")))))
                   (main (@ (style "padding-bottom: 1rem;"))
                     (div (@ (style "float: left"))
                        ,(render-list "daily/03-15-2026")
                        ,(render-list "weekly"))
                     (div (@ (style "float: right"))
                        ,(render-list "monthly")
                        ,(render-list "annual")
                        ,(render-list "ongoing")))))
