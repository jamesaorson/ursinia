(define (-render-section section-data done?)
  (let ([section (car section-data)]
        [date (cadr section-data)])
      `([content . (span (a (@ (href "https://gatech.instructure.com/courses/431938/modules"))
                            ,section)
                         ,(format #f " (Due: ~a)" date))]
        [done? . ,done?])))

(define (-render completed todo)
  `(,@(map-in-order (lambda (section)
                           (-render-section section #t))
                    completed)
    ,@(map-in-order (lambda (section)
                           (-render-section section #f))
                    todo)))

`([title . "Spring 2025 - Intro to Operating Systems"]
  [tasks . [
    ,@(-render
        `(
          ["P1L1: Course Overview" "January 10, 2025"]
          ["P1L2: Introduction to Operating Systems" "January 10, 2025"]
          ["P2L1: Processes and Process Management" "January 13, 2025"]
          ["[Project 0] Setup lab environment" "January 13, 2025"]
        )
        `(
          ["P2L2: Threads and Concurrency" "January 13, 2025"]
          ["P2L3: Threads Case Study: PThreads" "January 13, 2025"]
          [(span "[Project 1/Warmup] " (a (@ (href "https://gatech.instructure.com/courses/431938/assignments/1959414")) "echo")) "January 19, 2025"]
          [(span "[Project 1/Warmup] " (a (@ (href "https://gatech.instructure.com/courses/431938/assignments/1959416")) "transfer file")) "January 19, 2025"]
          [(span "[Project 1/Part 1] " (a (@ (href "https://gatech.instructure.com/courses/431938/assignments/1959418")) "gfclient")) "January 26, 2025"]
          [(span "[Project 1/Part 1] " (a (@ (href "https://gatech.instructure.com/courses/431938/assignments/1959420")) "gfserver")) "January 26, 2025"]
          [(span "[Project 1/Part 2] " (a (@ (href "https://gatech.instructure.com/courses/431938/assignments/1959422")) "multi-threaded gfclient")) "February 9, 2025"]
          [(span "[Project 1/Part 2] " (a (@ (href "https://gatech.instructure.com/courses/431938/assignments/1959424")) "multi-threaded gfserver")) "February 9, 2025"]
          [(span (a (@ (href "https://gatech.instructure.com/courses/431938/assignments/1959412")) "[Project 1/README]")) "February 9, 2025"]
          ["P2L4: Thread Design Considerations" "February 10, 2025"]
          ["P2L5: Thread Performance Considerations" "February 17, 2025"]
          ["[Midterm] Sample Questions" "February 20, 2025"]
          ["[Midterm] Exam" "February 20-24, 2025"]
          ["P3L1: Scheduling" "February 24, 2025"]
          ["P3L2: Memory Management" "March 3, 2025"]
          ["P3L3: Inter-Process Communication" "March 3, 2025"]
          ["P3L4: Synchronization Constructs" "March 10, 2025"]
          ["P3L5: I/O Management" "March 17, 2025"]
          ["[Project 3] there is no project 2" "March 24, 2025"]
          ["P3L6: Virtualization" "March 31, 2025"]
          ["P4L1: Remote Procedure Calls" "April 7, 2025"]
          ["P4L2: Distributed File Systems" "April 14, 2025"]
          ["P4L3: Distributed Shared Memory" "April 20, 2025"]
          ["[Project 4]" "April 20, 2025"]
          ["P4L4: Datacenter Technologies" "April 24, 2025"]
          ["[Final] Sample Questions" "April 24, 2025"]
          ["[Final] Exam" "April 24-29, 2025"]
        ))]])
