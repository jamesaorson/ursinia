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
                        ,(render-list "courses/BS534-old_testament_wisdom_books"))
                     ; (div (@ (style "float: right"))
                     ;    ,(render-list "courses/AP605-survey_of_world_religions_and_cults"))
                        )))
