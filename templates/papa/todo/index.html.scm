(use-modules (scripts lib html))

(define %year% 2025)
(define %month% "March")
(define %month-lower% (string-downcase %month%))

(define (load-tasks-by-id id)
   (load (format #f ".tasks/~a.scm" id)))

(define (-task-list tasks)
   (define (-task-list-item task)
      (let ([content (assoc-ref task 'content)]
            [done? (assoc-ref task 'done?)])
         `(li (span (@ (style "font-family: monospace;"))
                    (input (@ ,@(if done? 
                                 `((type "checkbox")
                                    (checked ,(bool->string done?)))
                                 `((type "checkbox")))))
                                 ,content))))
   `(ul (@ (style "list-style-type: none;"))
        (li (div (ul (@ (style "list-style-type: none;"))
                     ,(if (null? tasks)
                        '(li "No tasks")
                        (map-in-order -task-list-item
                                    tasks)))))))

(define (task-list id)
   (let* ([task-definition (load-tasks-by-id id)]
          [title (assoc-ref task-definition 'title)]
          [tasks (assoc-ref task-definition 'tasks)])
         `(section
            (h2 (@ (id ,id))
                (a (@ (href ,(format #f "#~a" id))) ,title))
            ,(-task-list tasks))))

(define daily-task-list
   (let* ([id "daily"]
          [task-definitions (load-tasks-by-id id)])
   `(section
      (h2 (@ (id ,id))
          (a (@ (href ,(format #f "#~a" id))) "Day to Day"))
      (ol (@ (style "list-style-type: none;"))
          ,(if (null? task-definitions)
              '(li "No tasks defined.")
              (map-in-order (lambda (task-definition)
                              (let* ([day (assoc-ref task-definition 'day)]
                                     [tasks (assoc-ref task-definition 'tasks)]
                                     [id-suffix (format #f "~a-~2,'0d-~d" %month-lower% day %year%)])
                                    `(li (div (h3 (a (@ (id ,id-suffix)
                                                      (href ,(format #f "#~a" id-suffix)))
                                                   ,(format #f "~a ~d, ~d" %month% day %year%)))
                                              ,(-task-list tasks)))))
                         task-definitions))))))

(render-template "Ursinia - Papa - Todo"
                 `((header
                     (div (@ (id "header"))
                          (span (@ (id "header-back"))
                                (a (@ (id "header-back-link")
                                      (href "/papa"))
                                   #\↤ " " (code "papa")))))
                   (main (@ (style "padding-bottom: 1rem;"))
                     (div (@ (style "float: left"))
                        ,daily-task-list
                        ,(task-list "weekly"))
                     (div (@ (style "float: right"))
                        ,(task-list "school/geopolitics-of-cybersecurity")
                        ,(task-list "school/intro-to-os")
                        ,(task-list "monthly")
                        ,(task-list "annual")
                        ,(task-list "ongoing")))))
