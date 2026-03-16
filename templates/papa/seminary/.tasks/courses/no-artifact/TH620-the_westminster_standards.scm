(use-modules (scripts lib course))

(define todo
  (list
    (course/render-assignment
      "Memorize: Westminster Shorter Catechism"
      "https://www.opc.org/sc.html"
      #f)
  ))

(define completed
  (reverse
    (list
)))

`([title . "TH620 - The Westminster Standards"]
  [tasks . [
    ,@(course/render completed todo)]])