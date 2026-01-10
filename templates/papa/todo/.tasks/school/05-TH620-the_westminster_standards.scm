(use-modules (scripts lib class))

(define todo
  (list
    (class/render-assignment
      "Assignment name"
      "https://example.com/assignment-link"
      "...")
  ))

(define completed
  (reverse
    (list )))

`([title . "TH620 - The Westminster Standards"]
  [tasks . [
    ,@(class/render completed todo)]])
