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
    `()
    `()
    `(["Assignment 1 - Perusall Readings"
       "February 2, 2025"
       "https://gatech.instructure.com/courses/442358/assignments/1888008?module_item_id=4505534"]
      ["Group Project - Join a group"
       "February 2, 2025"
       "https://gatech.instructure.com/groups/460332"]
      ["Discussion 1 - Initial post"
       "January 18, 2025"
       "https://docs.google.com/document/d/1jIpXJOfysjIkS8WeP2FK1dFt_ihotMUmUobew8N4Dys/edit?usp=sharing"]
      ["Discussion 1 - Discuss with peers"
       "February 2, 2025"
       "https://gatech.instructure.com/courses/442358/discussion_topics/1953103?module_item_id=4505536"]
      ["Assignment 2 - Group Project, Part 1: Case Overview - Provide a set of comparisons and an outline"
       "January 28, 2025"
       "https://gatech.instructure.com/courses/442358/assignments/1888010?module_item_id=4505538"]
      ["Assignment 2 - Group Project, Part 1: Case Overview"
       "February 2, 2025"
       "https://gatech.instructure.com/courses/442358/assignments/1888010?module_item_id=4505538"]
    )
    `()))

(define (module-2)
  (-render-module
    2
    "https://gatech.instructure.com/courses/442358/pages/module-2-instructor-video-content?module_item_id=4505552"
    `()
    `()
    `(["Assignment 3 - Perusall Readings"
       "March 2, 2025"
       "https://gatech.instructure.com/courses/442358/assignments/1888012?module_item_id=4505558"]
    )
    `(["Discussion 2 - Initial post"
       "February 20, 2025"
       "https://gatech.instructure.com/courses/442358/discussion_topics/1953101?module_item_id=4505556"]
      ["Discussion 2 - Discuss with peers"
       "March 2, 2025"
       "https://gatech.instructure.com/courses/442358/discussion_topics/1953101?module_item_id=4505556"]
      ["Assignment 4 - Group Project, Part 2: Bibliography and Timeline"
       "March 2, 2025"
       "https://gatech.instructure.com/courses/442358/assignments/1888014?module_item_id=4505540"]
    )))

`([title . "Geopolitics of Cybersecurity: Spring 2025"]
  [tasks . [
    ,@(module-1)
    ,@(module-2)
]])
