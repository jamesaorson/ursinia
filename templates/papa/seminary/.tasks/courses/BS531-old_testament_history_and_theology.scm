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

`([title . "BS531 - Old Testament History and Theology"]
  [tasks . [
    ,@(course/render completed todo)]])
