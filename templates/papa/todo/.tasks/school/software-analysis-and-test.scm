(use-modules (scripts lib class))

(define todo
  (list
    (class/render-assignment
      "Lab 2: Dataflow"
      "https://gatech.instructure.com/courses/464202/assignments/2048034"
      "September 22, 2025")
    (class/render-assignment
      "Exam Policies Acknowledgment"
      "https://gatech.instructure.com/courses/464202/quizzes/662991"
      "September 29, 2025")
    (class/render-assignment
      "Course Exam"
      "https://gatech.instructure.com/courses/464202/quizzes/662955"
      "September 29, 2025")
    (class/render-assignment
      "Lesson 7: Constraint Based Analysis"
      "https://edstem.org/us/courses/77984/lessons/136210/slides/767698"
      "September 29 - October 5, 2025")
    (class/render-assignment
      "Lesson 7: Constraint Based Analysis - Quiz"
      "https://gatech.instructure.com/courses/464202/quizzes/662981"
      "September 29 - October 5, 2025")
    (class/render-assignment
      "Mid-Course Survey"
      "https://gatech.instructure.com/courses/464202/quizzes/662985"
      "October 6, 2025")
    (class/render-assignment
      "Lab 3: Datalog"
      "https://gatech.instructure.com/courses/464202/assignments/2048036"
      "October 13, 2025")
    (class/render-assignment
      "Lesson 8: Type Systems"
      "https://edstem.org/us/courses/77984/lessons/136211/slides/767732"
      "October 13 - October 19, 2025")
    (class/render-assignment
      "Lesson 8: Type Systems - Quiz"
      "https://gatech.instructure.com/courses/464202/quizzes/662953"
      "October 13 - October 19, 2025")
    (class/render-assignment
      "Lab 4: Type Systems"
      "https://gatech.instructure.com/courses/464202/assignments/2048038"
      "October 27, 2025")
    (class/render-assignment
      "Lesson 9: Statistical Debugging"
      "https://edstem.org/us/courses/77984/lessons/136212/slides/767795"
      "October 27 - November 2, 2025")
    (class/render-assignment
      "Lesson 9: Statistical Debugging - Quiz"
      "https://gatech.instructure.com/courses/464202/quizzes/662989"
      "October 27 - November 2, 2025")
    (class/render-assignment
      "Lab 5: Cooperative Bug Isolation"
      "https://gatech.instructure.com/courses/464202/assignments/2048040"
      "November 10, 2025")
    (class/render-assignment
      "Lesson 10: Delta Debugging"
      "https://edstem.org/us/courses/77984/lessons/136213/slides/767854"
      "November 10 - November 16, 2025")
    (class/render-assignment
      "Lesson 10: Delta Debugging - Quiz"
      "https://gatech.instructure.com/courses/464202/quizzes/662987"
      "November 10 - November 16, 2025")
    (class/render-assignment
      "Lab 6: Delta Debugging"
      "https://gatech.instructure.com/courses/464202/assignments/2048042"
      "November 24, 2025")
    (class/render-assignment
      "Lesson 11: Dynamic Symbolic Execution"
      "https://edstem.org/us/courses/77984/lessons/136214/slides/767897"
      "November 24 - November 30, 2025")
    (class/render-assignment
      "Lesson 11: Dynamic Symbolic Execution - Quiz"
      "https://gatech.instructure.com/courses/464202/quizzes/662973"
      "November 24 - November 30, 2025")
    (class/render-assignment
      "Lab 7: KLEE"
      "https://gatech.instructure.com/courses/464202/assignments/2048044"
      "December 8, 2025")
    (class/render-assignment
      "End-of-Course Survey"
      "https://gatech.instructure.com/courses/464202/quizzes/662983"
      "December 8, 2025")
    (class/render-assignment
      "All quizzes"
      "https://gatech.instructure.com/courses/464202/quizzes"
      "December 8, 2025")
  )
)

(define completed
  (reverse
    (list
      (class/render-assignment
        "Lesson 6: Pointer Analysis - Quiz"
        "https://gatech.instructure.com/courses/464202/quizzes/662975"
        "September 15 - September 21, 2025")
      (class/render-assignment
        "Lesson 6: Pointer Analysis"
        "https://edstem.org/us/courses/77984/lessons/136209/slides/767654"
        "September 15 - September 21, 2025")
      (class/render-assignment
        "Lab 1: Fuzzing"
        "https://gatech.instructure.com/courses/464202/assignments/2048032"
        "September 8, 2025")
      (class/render-assignment
        "Lesson 5: Dataflow Analysis - Quiz"
        "https://gatech.instructure.com/courses/464202/quizzes/662961"
        "September 1 - September 7, 2025")
      (class/render-assignment
        "Lesson 4: Automated Test Generation - Quiz"
        "https://gatech.instructure.com/courses/464202/quizzes/662979"
        "September 1 - September 7, 2025")
      (class/render-assignment
        "Lesson 4: Automated Test Generation"
        "https://edstem.org/us/courses/77984/lessons/136207/slides/767547"
        "September 1 - September 7, 2025")
      (class/render-assignment
        "Lesson 3: Random Testing - Quiz"
        "https://gatech.instructure.com/courses/464202/quizzes/662971"
        "August 25 - August 31, 2025")
      (class/render-assignment
        "Lesson 3: Random Testing"
        "https://edstem.org/us/courses/77984/lessons/136206/slides/767516"
        "August 25 - August 31, 2025")
      (class/render-assignment
        "Lesson 2: Introduction to Software Testing - Quiz"
        "https://gatech.instructure.com/courses/464202/quizzes/662977"
        "August 25 - August 31, 2025")
      (class/render-assignment
        "Lesson 2: Introduction to Software Testing"
        "https://edstem.org/us/courses/77984/lessons/136205/slides/767476"
        "August 25 - August 31, 2025")
      (class/render-assignment
        "Lab 0: LLVM Intro"
        "https://gatech.instructure.com/courses/464202/assignments/2048030"
        "August 25, 2025")
      (class/render-assignment
        "Lesson 1.5: Soundness and Completeness"
        "https://edstem.org/us/courses/77984/lessons/136204/slides/767465"
        "August 18 - August 24, 2025")
      (class/render-assignment
        "Lesson 1: Introduction to Software Analysis - Quiz"
        "https://gatech.instructure.com/courses/464202/quizzes/662993"
        "August 18 - August 24, 2025")
      (class/render-assignment
        "Lesson 1: Introduction to Software Analysis"
        "https://edstem.org/us/courses/77984/lessons/136203/slides/767436"
        "August 18 - August 24, 2025")
      (class/render-assignment
        "Lesson 0: Course Introduction"
        "https://edstem.org/us/courses/77984/lessons/136202/slides/767416"
        "August 18 - August 24, 2025")
      (class/render-assignment
        "Syllabus Quiz"
        "https://gatech.instructure.com/courses/464202/quizzes/662959"
        "August 25, 2025")
      (class/render-assignment
        "Start of Course Survey"
        "https://gatech.instructure.com/courses/464202/quizzes/662969"
        "August 25, 2025")
    )
  )
)

`([title . "Fall 2025 - Software Analysis and Test (Everything is open starting August 25, 2025)"]
  [tasks . [
    ,@(class/render completed todo)]])
