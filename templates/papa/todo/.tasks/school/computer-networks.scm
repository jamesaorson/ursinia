(define (-render-section section-data done?)
  (let ([section (car section-data)]
        [date (cadr section-data)])
      `([content . (span (a (@ (href "https://gatech.instructure.com"))
                            ,section)
                         ,(format #f " (Due: ~a)" date))]
        [done? . ,done?])))

(define (-render completed todo)
  `(,@(map-in-order (lambda (section)
                           (-render-section section #t))
                    completed)
    ,@(map-in-order (lambda (section)
                           (-render-section section #f))
                    todo)))

(define (-render-assignment title href date)
  `[(span (a (@ (href ,href)) ,title)) ,date])

`([title . "Summer 2025 - Computer Networks"]
  [tasks . [
    ,@(-render
        `(
        )
        `(
          ,(-render-assignment "???" "https://gatech.instructure.com/" "??? ???, 2025")
        ))]])
