(define-module (scripts lib task))

(use-modules (scripts lib html))

(define (task/-render-list tasks)
   (define normalized-tasks (if (list? tasks) tasks '()))
   (define (task/-render-list-item task)
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
                     ,(if (null? normalized-tasks)
                        '(li "No tasks")
                        (map-in-order task/-render-list-item
                                    normalized-tasks)))))))

(define (task/normalize-definition id task-definition)
   (let ([tasks (assoc-ref task-definition 'tasks)]
         [title (assoc-ref task-definition 'title)])
      (cond
         ;; Standard shape: '([title . ...] [tasks . (...)]).
         [tasks `([title . ,(or title id)]
                  [tasks . ,tasks])]
         ;; Day-grouped shape: '(([day . ...] [tasks . (...)] ) ...).
         [(and (list? task-definition)
               (not (null? task-definition))
               (list? (car task-definition))
               (assoc-ref (car task-definition) 'tasks))
          (let* ([day-entry (car task-definition)]
                 [day (assoc-ref day-entry 'day)]
                 [day-tasks (assoc-ref day-entry 'tasks)]
                 [normalized-title (if day
                                      (format #f "~a (~a)" id day)
                                      id)])
             `([title . ,normalized-title]
               [tasks . ,(if (list? day-tasks) day-tasks '())]))]
         [else `([title . ,id]
                 [tasks . ()])])))

(define (task/load-by-id dir id)
   (load (format #f "~a/~a.scm" dir id)))

(define-public (task/render-list task-dir id)
   (let* ([raw-definition (task/load-by-id task-dir id)]
          [task-definition (task/normalize-definition id raw-definition)]
          [title (assoc-ref task-definition 'title)]
          [tasks (assoc-ref task-definition 'tasks)])
         `(section
            (h2 (@ (id ,id))
                (a (@ (href ,(format #f "#~a" id))) ,title))
            ,(task/-render-list tasks))))
