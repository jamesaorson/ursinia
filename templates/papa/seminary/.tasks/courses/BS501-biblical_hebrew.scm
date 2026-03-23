(use-modules (scripts lib course))

(define todo
  (list
    (course/render-assignment
      "[No artifact] Read: Tips for Better Note-Taking for Greek and Hebrew Courses"
      "https://drive.google.com/file/d/1AAdDtDhEXYwx5C2RbeuOtO7smbEwPOrJ/view"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: Hebrew Grammar I 1-24 (Dr. William Barrick, 24h)"
      "https://biblicalelearning.org/hebrewindex-html/"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: Hebrew Grammar II 1-26 (Dr. William Barrick, 26h)"
      "https://biblicalelearning.org/hebrewindex-html/"
      #f)
    (course/render-assignment
      "View and take notes: Learn Biblical Hebrew 1-40 (8h)"
      "https://dailydoseofhebrew.com/learn/"
      #f)
    (course/render-assignment
      "View and take notes on new material, insights, or learning strategies: Elementary Hebrew 1-147 (Dr. Andrew Bartelt, 17.5h)"
      "https://scholar.csl.edu/hebrew/"
      #f)
    (course/render-assignment
      "Read in conjunction with Barrick lectures: A Grammar for Biblical Hebrew (Dr. William Barrick and Irvin Busenitz, 213pp)"
      "https://drbarrick.org/files/studynotes/Other/B_B_Hebrew_Grammar_2005.pdf"
      #f)
    (course/render-assignment
      "Complete in conjunction with Barrick lectures: Workbook for A Grammar for Biblical Hebrew (Barrick and Busenitz)"
      "https://drbarrick.org/files/studynotes/Other/B_B_Hebrew_Grammar_Wkbk_Full.pdf"
      #f)
    (course/render-assignment
      "[No artifact] Memorize: All 100 numbered vocabulary terms in the Hebrew Vocabulary List"
      "https://drive.google.com/file/d/1a7PJzCyOrZA9i54nd_g0PIbyjP5aWSR3/view"
      #f)
    (course/render-assignment
      "Exam: Hebrew Vocabulary Exam (100 numbered words)"
      "https://example.com"
      #f)
  ))

(define completed
  (reverse
    (list
)))

`([title . "BS501 - Biblical Hebrew"]
  [tasks . [
    ,@(course/render completed todo)]])