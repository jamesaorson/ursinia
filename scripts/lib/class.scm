(define-module (scripts lib class))

(define-public (class/render-section section-data done?)
  (let ([section (car section-data)]
        [date (cadr section-data)])
      `([content . (span (a (@ (href "https://gatech.instructure.com"))
                            ,section)
                         ,(format #f " (Due: ~a)" date))]
        [done? . ,done?])))

(define-public (class/render completed todo)
  `(,@(map-in-order (lambda (section)
                           (class/render-section section #t))
                    completed)
    ,@(map-in-order (lambda (section)
                           (class/render-section section #f))
                    todo)))

(define-public (class/render-assignment title href date)
  `[(span (a (@ (href ,href)) ,title)) ,date])
  