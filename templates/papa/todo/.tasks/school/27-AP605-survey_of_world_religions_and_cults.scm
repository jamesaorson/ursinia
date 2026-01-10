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

`([title . "AP605 - Survey of World Religions and Cults"]
  [tasks . [
    ,@(class/render completed todo)]])
