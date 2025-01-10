(define (-render-video module-number module-url video-number done?)
  `([content . (span (a (@ (href ,module-url))
                         "Module " ,module-number) " - Video " ,video-number)]
     [done? . ,done?]))

(define (-render-assignment module-number module-url assignment done?)
  (let ([name (car assignment)]
        [date (cadr assignment)]
        [href (caddr assignment)])
       `([content . (span (a (@ (href ,module-url))
                             "Module " ,module-number)
                          "/"
                          (a (@ (href ,href))
                             ,name)
                          ,(format #f " (Due: ~a)" date))]
         [done? . ,done?])))

(define (-render-module module-number module-url completed-videos todo-videos completed-assignments todo-assignments)
  `(,@(map-in-order (lambda (video)
                            (-render-video module-number module-url video #t))
                    completed-videos)
    ,@(map-in-order (lambda (video)
                            (-render-video module-number module-url video #f))
                    todo-videos)
    ,@(map-in-order (lambda (assignment)
                      (-render-assignment module-number module-url assignment #t))
                    completed-assignments)
    ,@(map-in-order (lambda (assignment)
                      (-render-assignment module-number module-url assignment #f))
                    todo-assignments)))

(define (module-1)
  (-render-module
    1
    "https://gatech.instructure.com/courses/442358/pages/module-1-instructor-video-content?module_item_id=4505530"
    `(1 2 3 4 5 6 7 8)
    `()
    `()
    `(["Assignment 1 - Perusall Readings"
       "February 2, 2025"
       "https://gatech.instructure.com/courses/442358/assignments/1888008?module_item_id=4505534"]
      ["Discussion 1"
       "February 2, 2025"
       "https://gatech.instructure.com/courses/442358/discussion_topics/1953103?module_item_id=4505536"]
      ["Assignment 2 - Group Project - Case Overview 1 - Part 1"
       "February 2, 2025"
       "https://gatech.instructure.com/courses/442358/assignments/1888010?module_item_id=4505538"])))

`([title . "Geopolitics of Cybersecurity: Spring 2025"]
  [tasks . [
    ,@(module-1)
]])
