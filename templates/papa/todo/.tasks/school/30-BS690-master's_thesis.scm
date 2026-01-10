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

`([title . "BS690 - Master's Thesis"]
  [tasks . [
    ,@(class/render completed todo)]])
