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

`([title . "PH600 - Survey of Philosophy and Worldview Studies"]
  [tasks . [
    ,@(class/render completed todo)]])
