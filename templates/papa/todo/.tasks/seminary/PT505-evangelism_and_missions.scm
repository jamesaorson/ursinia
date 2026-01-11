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

`([title . "PT505 - Evangelism and Missions"]
  [tasks . [
    ,@(class/render completed todo)]])
