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

`([title . "CH520 - History of the Church"]
  [tasks . [
    ,@(class/render completed todo)]])
