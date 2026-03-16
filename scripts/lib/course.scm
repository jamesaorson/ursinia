(define-module (scripts lib course))

(define-public (course/render-section section-data done?)
  (let ([section (car section-data)]
        [date (cadr section-data)])
      `([content . (span (a (@ (href "https://gatech.instructure.com"))
                            ,section)
                         ,(if date (format #f " (Due: ~a)" date) '()))]
        [done? . ,done?])))

(define-public (course/render completed todo)
  `(,@(map-in-order (lambda (section)
                           (course/render-section section #t))
                    completed)
    ,@(map-in-order (lambda (section)
                           (course/render-section section #f))
                    todo)))

(define-public (course/render-assignment title href date)
  `[(span (a (@ (href ,href)) ,title)) ,date])
