(use-modules (scripts lib class))

(define todo
  (list
    (class/render-assignment
      "Participation/Syllabus Quiz"
      "https://gatech.instructure.com/courses/461328/assignments/2123556"
      "August 30 - September 8, 2025")
    (class/render-assignment
      "Assignment 3: Basic Java Coding and JUnit"
      "https://gatech.instructure.com/courses/461328/assignments/2123562"
      "August 30 - September 8, 2025")
    (class/render-assignment
      "Assignment 4: Simple Android App"
      "https://gatech.instructure.com/courses/461328/assignments/2123566"
      "September 6 - September 15, 2025")
    (class/render-assignment
      "Assignment 5: Software Design"
      "https://gatech.instructure.com/courses/461328/assignments/2123568"
      "September 13 - September 22, 2025")
    (class/render-assignment
      "Group Project: Deliverable 0"
      "https://gatech.instructure.com/courses/461328/assignments/2123576"
      "September 13 - September 22, 2025")
    (class/render-assignment
      "Group Project: Deliverable 1"
      "https://gatech.instructure.com/courses/461328/assignments/2123578"
      "September 20 - September 29, 2025")
    (class/render-assignment
      "Group Project: Weekly Report 1"
      "https://gatech.instructure.com/courses/461328/assignments/2123590"
      "September 20 - September 29, 2025")
    (class/render-assignment
      "Group Project: Deliverable 2"
      "https://gatech.instructure.com/courses/461328/assignments/2123580"
      "September 27 - October 6, 2025")
    (class/render-assignment
      "Group Project: Weekly Report 2"
      "https://gatech.instructure.com/courses/461328/assignments/2123592"
      "September 27 - October 6, 2025")
    (class/render-assignment
      "Group Project: Deliverable 3"
      "https://gatech.instructure.com/courses/461328/assignments/2123582"
      "October 4 - October 13, 2025")
    (class/render-assignment
      "Group Project: Weekly Report 3"
      "https://gatech.instructure.com/courses/461328/assignments/2123594"
      "October 4 - October 13, 2025")
    (class/render-assignment
      "Group Project: Deliverable 4"
      "https://gatech.instructure.com/courses/461328/assignments/2123584"
      "October 11 - October 20, 2025")
    (class/render-assignment
      "Group Project: Weekly Report 4"
      "https://gatech.instructure.com/courses/461328/assignments/2123596"
      "October 11 - October 20, 2025")
    (class/render-assignment
      "Assignment 6: White-Box testing"
      "https://gatech.instructure.com/courses/461328/assignments/2123570"
      "October 18 - October 27, 2025")
    (class/render-assignment
      "Group Project: Individual Assessments, Collaboration"
      "https://gatech.instructure.com/courses/461328/assignments/2123586"
      "October 18 - October 27, 2025")
    (class/render-assignment
      "Individual Project: Deliverable 1"
      "https://gatech.instructure.com/courses/461328/assignments/2123600"
      "October 25 - November 3, 2025")
    (class/render-assignment
      "Individual Project: Deliverable 2"
      "https://gatech.instructure.com/courses/461328/assignments/2123602"
      "November 1 - November 10, 2025")
    (class/render-assignment
      "Individual Project: Deliverable 3"
      "https://gatech.instructure.com/courses/461328/assignments/2123604"
      "November 8 - November 17, 2025")
    (class/render-assignment
      "Individual Project: Deliverable 4"
      "https://gatech.instructure.com/courses/461328/assignments/2123606"
      "November 15 - November 24, 2025")
  )
)

(define completed
  (reverse
    (list
      (class/render-assignment
        "Assignment 2: Git Usage"
        "https://gatech.instructure.com/courses/461328/assignments/2123560"
        "August 23 - September 1, 2025")
      (class/render-assignment
        "Assignment 1: Team Matching"
        "https://gatech.instructure.com/courses/461328/assignments/2123554"
        "August 18 - August 25, 2025")
    )
  )
)

`([title . "Fall 2025 - Software Development Process (Class only has graded assignments. No exams or quizzes.)"]
  [tasks . [
    ,@(class/render completed todo)]])
