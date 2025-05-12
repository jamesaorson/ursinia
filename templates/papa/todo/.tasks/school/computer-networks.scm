(define (-render-section section-data done?)
  (let ([section (car section-data)]
        [date (cadr section-data)])
      `([content . (span (a (@ (href "https://gatech.instructure.com"))
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

`([title . "Summer 2025 - Computer Networks"]
  [tasks . [
    ,@(-render
        `(
          ,(-render-assignment "Lesson 1 Quiz: Introduction, History, and Internet Architecture" "https://gatech.instructure.com/courses/453100/quizzes/667769?module_item_id=4958756" "May 25, 2025")
        )
        `(
          ,(-render-assignment "Lesson 1 Project: Spanning Tree Protocol for Network Switches" "https://gatech.instructure.com/courses/453100/modules/items/4958760" "May 25, 2025")
          ,(-render-assignment "Lesson 2 Quiz: Transport and Applications Layers" "https://gatech.instructure.com/courses/453100/quizzes/667823?module_item_id=4958814" "May 25, 2025")
          ,(-render-assignment "Lesson 3 Quiz: Intradomain Routing" "https://gatech.instructure.com/courses/453100/quizzes/667805?module_item_id=4958856" "May 25, 2025")
          ,(-render-assignment "Lesson 4 Quiz: AS Relationships and Interdomain Routing" "https://gatech.instructure.com/courses/453100/quizzes/667719?module_item_id=4958898" "June 1, 2025")
          ,(-render-assignment "Project: Distance Vector" "https://gatech.instructure.com/courses/453100/modules/items/4958900" "June 8, 2025")
          ,(-render-assignment "Lesson 5 Quiz: Router Design and Algorithms (Part 1)" "https://gatech.instructure.com/courses/453100/quizzes/667815?module_item_id=4958936" "June 8, 2025")
          ,(-render-assignment "Lesson 6 Quiz: Router Design and Algorithms (Part 2)" "https://gatech.instructure.com/courses/453100/quizzes/667763?module_item_id=4958962" "June 8, 2025")
          ,(-render-assignment "Exam 1" "https://gatech.instructure.com/courses/453100/quizzes/667817?module_item_id=4958964" "June 15, 2025")
          ,(-render-assignment "Lesson 7 Quiz: SDN (Part 1)" "https://gatech.instructure.com/courses/453100/quizzes/667793?module_item_id=4958996" "June 22, 2025")
          ,(-render-assignment "Lesson 8 Quiz: SDN (Part 2)" "https://gatech.instructure.com/courses/453100/quizzes/667705?module_item_id=4959042" "June 22, 2025")
          ,(-render-assignment "Project: SDN Firewall" "https://gatech.instructure.com/courses/453100/assignments/2063430?module_item_id=4958998" "June 29, 2025")
          ,(-render-assignment "Lesson 9 Quiz: Internet Security" "https://gatech.instructure.com/courses/453100/quizzes/667725?module_item_id=4959096" "June 29, 2025")
          ,(-render-assignment "Lesson 10 Quiz: Internet Surveillance and Censorship" "https://gatech.instructure.com/courses/453100/quizzes/667715?module_item_id=4959132" "July 6, 2025")
          ,(-render-assignment "Lesson 11 Quiz: Applications Part 1: Video" "https://gatech.instructure.com/courses/453100/quizzes/667803?module_item_id=4959210" "July 13, 2025")
          ,(-render-assignment "Project: BGP Measurements" "https://gatech.instructure.com/courses/453100/assignments/2063422?module_item_id=4959212" "July 19, 2025")
          ,(-render-assignment "Extra Credit: Internet-Wide Events" "https://gatech.instructure.com/courses/453100/modules/items/4959214" "July 19, 2025")
          ,(-render-assignment "Lesson 12 Quiz: Applications Part 2: CDNs" "https://gatech.instructure.com/courses/453100/quizzes/667753?module_item_id=4959250" "July 20, 2025")
          ,(-render-assignment "Exam 2" "https://gatech.instructure.com/courses/453100/quizzes/667759?module_item_id=4959252" "July 27, 2025")
          ,(-render-assignment "Project: BGP Hijacking" "???" "???, 2025")
          ,(-render-assignment "Lesson 13" "https://gatech.instructure.com/courses/453100/quizzes/667759" "???, 2025")
        ))]])
