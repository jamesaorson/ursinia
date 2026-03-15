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

`([title . "AP605 - Survey of World Religions and Cults"]
  [tasks . [
    ,@(course/render completed todo)]])
