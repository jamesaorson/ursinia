(use-modules (scripts lib html))

(define %year% 2024)
(define %month% "December")
(define %month-lower% (string-downcase %month%))

(define (task-list title tasks)
   `(section
      (h2 ,title)
      (ol ,(map-in-order (lambda (item)
                              (let* ([day (assoc-ref item 'day)]
                                    [tasks (assoc-ref item 'tasks)]
                                    [id-suffix (format #f "~a-~2,'0d-~d" %month-lower% day %year%)])
                                 `(li (div (h3 (a (@ (id ,id-suffix)
                                                      (href ,(format #f "#~a" id-suffix)))
                                                   ,(format #f "~a ~d, ~d" %month% day %year%)))
                                             (ul
                                             ,(map-in-order (lambda (task)
                                                                  (let ([content (assoc-ref task 'content)]
                                                                        [done? (assoc-ref task 'done?)])
                                                                     `(li (span (input (@ (type "checkbox"))) ,(format #f " ~a" content)))))
                                                            tasks))))))
                           tasks))))

(render-template "Ursinia - Papa - Todo"
                 `((header
                     (div (@ (id "header"))
                          (span (@ (id "header-back"))
                                (a (@ (id "header-back-link")
                                      (href "https://papa.ursinia.net"))
                                   #\↤ " " (code "papa")))))
                   (main
                     ,(task-list "Day to Day" (load ".tasks/daily.scm"))
                     ,(task-list "Week to Week" (load ".tasks/weekly.scm"))
                     ,(task-list "Month to Month" (load ".tasks/monthly.scm"))
                     ,(task-list "Year to Year" (load ".tasks/annual.scm"))
                     ,(task-list "Ongoing" (load ".tasks/ongoing.scm"))
                     ,(task-list "School/Master's Program in Computer Science" (load ".tasks/school.scm")))))
