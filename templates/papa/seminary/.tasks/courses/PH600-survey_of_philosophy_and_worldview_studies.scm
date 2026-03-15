(use-modules (scripts lib course))

(define todo
  (list
    (course/render-assignment
      "Assignment name"
      "https://example.com/assignment-link"
      "...")
  ))

(define completed
  (reverse
    (list )))

`([title . "PH600 - Survey of Philosophy and Worldview Studies"]
  [tasks . [
    ,@(course/render completed todo)]])
