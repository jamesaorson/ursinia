(use-modules (scripts lib course))

(define todo
  (list
    (course/render-assignment
      "Read and summarize: On the Necessity of a Knowledge of the Original Languages of the Scriptures (Charles Hodge, 18pp)"
      "https://archive.org/details/onnecessityofkno06hodg"
      #f)
    (course/render-assignment
      "[No artifact] Read: Tips for Better Note-Taking for Greek and Hebrew Courses"
      "https://drive.google.com/file/d/1AAdDtDhEXYwx5C2RbeuOtO7smbEwPOrJ/view"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: Greek Grammar I 1-10 (Tom Stegall, 12h)"
      "https://drive.google.com/drive/folders/1xktSMPDPhkVKLfKm2kfn9sKOe2upfR8_"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: Greek Grammar II 1-11 (Tom Stegall, 11h)"
      "https://drive.google.com/drive/folders/1AubMEpkxmyqV_cuU9-Uet5cRkSxF5kx6"
      #f)
    (course/render-assignment
      "View and take notes: Learn Biblical Greek 1-26 (Dr. Robert Plummer, 8h)"
      "https://dailydoseofgreek.com/learn-biblical-greek/"
      #f)
    (course/render-assignment
      "View and take notes on new material, insights, or learning strategies: New Testament Greek (Videos 1-28, Ted Hildebrandt, 14h)"
      "https://www.youtube.com/playlist?list=PLnNXzYjQerJirDk_oEM9r4ZHB39WjKzgV"
      #f)
    (course/render-assignment
      "Read in conjunction with Hildebrandt lectures: Mastering New Testament Greek (Ted Hildebrandt, 521pp)"
      "https://drive.google.com/file/d/1EnjYFVedw8j0Hq-odqOHNYNwUQaslxxD/view"
      #f)
    (course/render-assignment
      "Complete in conjunction with Hildebrandt lectures: Mastering New Testament Greek Workbook (Ted Hildebrandt)"
      "https://drive.google.com/file/d/11NulUniMXb0MShPmumMGdDq-IRm5thhT/view"
      #f)
    (course/render-assignment
      "View and take notes: Elementary Greek 1-161 (Dr. James Voelz, 28h)"
      "https://scholar.csl.edu/greek/"
      #f)
    (course/render-assignment
      "[No artifact] Memorize: 311 Most Frequently Used Words in the Greek New Testament"
      "https://drive.google.com/file/d/1o_zxrXrBhlCPvBkI15XwGgK_sXyYnqXk/view"
      #f)
    (course/render-assignment
      "Exam: Greek Vocabulary Exam (311 Most Frequently Used Words)"
      "https://example.com"
      #f)
  ))

(define completed
  (reverse
    (list
)))

`([title . "BS500 - Biblical Greek"]
  [tasks . [
    ,@(course/render completed todo)]])