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

`([title . "PT505 - Evangelism and Missions"]
  [tasks . [
    ,@(course/render completed todo)]])
