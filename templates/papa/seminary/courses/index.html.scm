(use-modules (scripts lib html)
             (scripts lib task)
             (ice-9 ftw))

(define task-dir (format #f "~a/../.tasks" (dirname (current-filename))))

(define (render-list id)
   (task/render-list task-dir id))

(render-template "Ursinia - Papa - Seminary Courses" "papa"
                 `((header
                     (div (@ (id "header"))
                          (span (@ (id "header-back"))
                                (a (@ (id "header-back-link")
                                      (href ".."))
                                   #\↤ " " (code "seminary")))))
                   (main (@ (style "padding-bottom: 1rem;"))
                     (div (@ (style "float: left"))
                        (h2 "All Courses")
                        ,(let ([files (scandir (format #f "~a/courses" task-dir)
                                               (lambda (entry) (string-suffix? ".scm" entry)))])
                          (map-in-order (lambda (file)
                            (render-list (format #f "courses/~a" (string-drop-right file 4))))
                            files))
                     ))))
