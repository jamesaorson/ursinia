(define (-render-video module-number module-url video-number done?)
  `([content . (span (a (@ (href ,module-url))
                         "Module " ,module-number) " - Video " ,video-number)]
     [done? . ,done?]))

(define (-render-module module-number module-url completed todo)
  `(,@(map-in-order (lambda (video)
                            (-render-video module-number module-url video #t))
                    completed)
    ,@(map-in-order (lambda (video)
                            (-render-video module-number module-url video #f))
                    todo)))

(define (module-1)
  (-render-module
    1
    "https://gatech.instructure.com/courses/442358/pages/module-1-instructor-video-content?module_item_id=4505530"
    `(1 2 3 4 5 6 7)
    `(8)))

`([title . "Geopolitics of Cybersecurity: Spring 2025"]
  [tasks . [
    ,@(module-1)
]])
