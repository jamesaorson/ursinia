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

`([title . "PT600 - Pastoral Theology"]
  [tasks . [
    ,@(course/render completed todo)]])
