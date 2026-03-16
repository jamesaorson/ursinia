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
                        (h2 "Artifact-Free Courses")
                        ,(render-list "courses/artifact-free/PRE500-preparatory_studies")
                        (h2 "Next...")
                        ,(render-list "courses/next/PRE500-preparatory_studies"))
                     ; (div (@ (style "float: right"))
                     ;    ,(render-list "courses/AP605-survey_of_world_religions_and_cults"))
                        )))
