(use-modules (scripts lib class))

(define todo
  (list
  (class/render-assignment "PLACEHOLDER" "https://gatech.instructure.com/courses/453100/quizzes/667769?module_item_id=4958756" "??? ##, 2025")
  )
)

(define completed
  (list
  )
)

`([title . "Fall 2025 - Intro to Grad Algorithms (Class only grades exams and the quizzes. Everything else is optional.)"]
  [tasks . [
    ,@(class/render completed todo)]])
