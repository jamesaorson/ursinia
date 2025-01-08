(define (-render-section section done?)
  `([content . (span (a (@ (href "https://gatech.instructure.com/courses/431938/modules"))
                        ,section))]
    [done? . ,done?]))

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
        `[
          "P1L1: Course Overview"
        ]
        `[
          "P1L2: Introduction to Operating Systems"
          "P2L1: Processes and Process Management"
          "P2L2: Threads and Concurrency"
          "P2L3: Threads Case Study: PThreads"
          "Problem Set 1"
          "P2L4: Thread Design Considerations"
          "P2L5: Thread Performance Considerations"
          "Sample Midterm Exam Questions"
          "P3L1: Scheduling"
          "P3L2: Memory Management"
          "P3L3: Inter-Process Communication"
          "P3L4: Synchronization Constructs"
          "P3L5: I/O Management"
          "P3L6: Virtualization"
          "P4L1: Remote Procedure Calls"
          "P4L2: Distributed File Systems"
          "P4L3: Distributed Shared Memory"
          "P4L4: Datacenter Technologies"
          "Sample Final Questions"
        ])]])
