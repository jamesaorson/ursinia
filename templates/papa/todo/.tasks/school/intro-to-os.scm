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

(define (-render-assignment title href date)
  `[(span (a (@ (href ,href)) ,title)) ,date])

`([title . "Spring 2025 - Intro to Operating Systems"]
  [tasks . [
    ,@(-render
        `(
          ,(-render-assignment "P1L1: Course Overview" "https://gatech.instructure.com/courses/431938/assignments/1959414" "January 10, 2025")
          ,(-render-assignment "P1L2: Introduction to Operating Systems" "https://gatech.instructure.com/courses/431938/assignments/1959414" "January 10, 2025")
          ,(-render-assignment "P2L1: Processes and Process Management" "https://gatech.instructure.com/courses/431938/pages/p2l1-processes-and-process-management?module_item_id=4686676" "January 13, 2025")
          ["[Project 0] Setup lab environment" "January 13, 2025"]
          ,(-render-assignment "[Project 1/Warmup] echo" "https://gatech.instructure.com/courses/431938/assignments/1959414" "January 19, 2025")
          ,(-render-assignment "[Project 1/Warmup] transfer file" "https://gatech.instructure.com/courses/431938/assignments/1959416" "January 19, 2025")
          ,(-render-assignment "P2L2: Threads and Concurrency" "https://gatech.instructure.com/courses/431938/pages/p2l2-threads-and-concurrency-playlist" "January 13, 2025")
          ,(-render-assignment "P2L3: Threads Case Study: PThreads" "https://gatech.instructure.com/courses/431938/pages/p2l3-threads-case-study-pthreads-playlist" "January 13, 2025")
          ,(-render-assignment "[Project 1/Part 1] gfclient" "https://gatech.instructure.com/courses/431938/assignments/1959418" "January 26, 2025")
          ,(-render-assignment "[Project 1/Part 1] gfserver" "https://gatech.instructure.com/courses/431938/assignments/1959420" "January 26, 2025")
          ,(-render-assignment "P2L4: Thread Design Considerations" "https://gatech.instructure.com/courses/431938/pages/p2l4-thread-design-considerations-playlist" "February 10, 2025")
          ,(-render-assignment "[Project 1/Part 2] multi-threaded gfclient" "https://gatech.instructure.com/courses/431938/assignments/1959418" "February 9, 2025")
          ,(-render-assignment "[Project 1/Part 2] multi-threaded gfserver" "https://gatech.instructure.com/courses/431938/assignments/1959420" "February 9, 2025")
          ,(-render-assignment "P2L5: Thread Performance Considerations" "https://gatech.instructure.com/courses/431938/pages/p2l5-thread-performance-considerations-playlist" "February 17, 2025")
          ,(-render-assignment "[Project 1/README]" "https://gatech.instructure.com/courses/431938/assignments/1959412" "February 9, 2025")
          ,(-render-assignment "P3L1: Scheduling" "https://gatech.instructure.com/courses/431938/pages/p3l1-scheduling-playlist" "February 24, 2025")
          ["[Midterm] Sample Questions" "February 20, 2025"]
          ["[Midterm] Exam" "February 20-24, 2025"]
        )
        `(
          ,(-render-assignment "P3L2: Memory Management" "https://gatech.instructure.com/courses/431938/pages/p3l2-memory-management-playlist" "March 3, 2025")
          ,(-render-assignment "P3L3: Inter-Process Communication" "https://gatech.instructure.com/courses/431938/pages/p3l3-inter-process-communication-playlist" "March 3, 2025")
          ,(-render-assignment "P3L4: Synchronization Constructs" "https://gatech.instructure.com/courses/431938/pages/p3l4-synchronization-constructs-playlist" "March 10, 2025")
          ,(-render-assignment "P3L5: I/O Management" "https://gatech.instructure.com/courses/431938/pages/p3l5-i-slash-o-management-playlist" "March 17, 2025")
          ["[Project 3] there is no project 2" "March 24, 2025"]
          ,(-render-assignment "P3L6: Virtualization" "https://gatech.instructure.com/courses/431938/pages/p3l6-virtualization-playlist" "March 31, 2025")
          ,(-render-assignment "P4L1: Remote Procedure Calls" "https://gatech.instructure.com/courses/431938/pages/p4l1-remote-procedure-calls-playlist" "April 7, 2025")
          ,(-render-assignment "P4L2: Distributed File Systems" "https://gatech.instructure.com/courses/431938/pages/p4l2-distributed-file-systems-playlist" "April 14, 2025")
          ,(-render-assignment "P4L3: Distributed Shared Memory" "https://gatech.instructure.com/courses/431938/pages/p4l3-distributed-shared-memory-playlist" "April 20, 2025")
          ["[Project 4]" "April 20, 2025"]
          ,(-render-assignment "P4L4: Datacenter Technologies" "https://gatech.instructure.com/courses/431938/pages/p4l4-datacenter-technologies-playlist" "April 24, 2025")
          ["[Final] Sample Questions" "April 24, 2025"]
          ["[Final] Exam" "April 24-29, 2025"]
        ))]])
