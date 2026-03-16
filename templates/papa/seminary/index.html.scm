(use-modules (scripts lib html)
             (scripts lib task))

(define (render-list id)
   (task/render-list (format #f "~a/.tasks" (dirname (current-filename))) id))

(render-template "Ursinia - Papa - Seminary" "papa"
                 `((header
                     (div (@ (id "header"))
                          (span (@ (id "header-back"))
                                (a (@ (id "header-back-link")
                                      (href ".."))
                                   #\↤ " " (code "papa")))))
                   (main (@ (style "padding-bottom: 1rem;"))
                     (div (@ (style "float: left"))
                        (h2 "Courses with no artifacts...")
                        ,(render-list "courses/no-artifact/BS500-biblical_greek")
                        ,(render-list "courses/no-artifact/BS501-biblical_hebrew")
                        ,(render-list "courses/no-artifact/TH620-the_westminster_standards")
                     ))))
