(use-modules (scripts lib course))

(define todo
  (list
    (course/render-assignment
      "Listen, outline, and take notes: New Testament Survey 1-25 (Jack B. Scott, 26h)"
      "https://www.sermonaudio.com/series/15288"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: New Testament Theology 1-14 (Dr. Frank Thielman, 14h)"
      "https://www.biblicaltraining.org/learn/institute/nt575-new-testament-theology"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: New Testament Textual Criticism (9 lectures) (Dr. Moises Silva, 8h)"
      "https://drive.google.com/file/d/1aZ-GqcpJip92yvwKQpP4iv8r3bxQ7Oru/view"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: The NT Text: The Superiority of the Majority Text (Brian Schwertley, 1h)"
      "https://www.sermonaudio.com/sermons/431115281"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: Kept Pure in All Ages Conference Lecture 1 (Dr. Jeff Riddle, 1h)"
      "https://www.youtube.com/watch?v=_pNbw6N3MjU"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: Kept Pure in All Ages Conference Lecture 2 (Dr. Jeff Riddle, 1h)"
      "https://www.youtube.com/watch?v=Lg-sDGCl6m0"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: Kept Pure in All Ages Conference Lecture 3 (Dr. Jeff Riddle, 0.5h)"
      "https://www.youtube.com/watch?v=JbpPfMCLnxE"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: Kept Pure in All Ages Conference Lecture 4 (Dr. Jeff Riddle, 0.5h)"
      "https://www.youtube.com/watch?v=BcA2ipWx_tw"
      #f)
    (course/render-assignment
      "View and provide short summaries: The Basics of New Testament Textual Criticism 1-15 (Dr. Daniel Wallace, 2h)"
      "https://itunes.apple.com/us/itunes-u/basics-new-testament-textual/id446655163?mt=10"
      #f)
    (course/render-assignment
      "Read and provide chapter summaries: The Literature and History of New Testament Times (J. Gresham Machen, 288pp)"
      "https://archive.org/details/literaturehistor00mach/page/n7/mode/1up"
      #f)
    (course/render-assignment
      "Read and provide chapter summaries: The Progress of Doctrine in the New Testament (Thomas Bernard, 235pp)"
      "https://archive.org/details/progressofdoctri00bern/page/n8/mode/1up"
      #f)
    (course/render-assignment
      "Read and provide chapter summaries: Exegetical Study of the New Testament (Patrick Fairbairn, 542pp)"
      "https://archive.org/details/hermeneutical00fairrich"
      #f)
    (course/render-assignment
      "Read and provide chapter summaries: Has God Indeed Said? The Preservation of the Text of the New Testament (Phillip Kayser and Wilbur Pickering, 30pp)"
      "https://leanpub.com/read/has-god-indeed-said"
      #f)
    (course/render-assignment
      "Read and provide chapter summaries: The Identity of the New Testament Text (Wilbur Pickering, 200pp)"
      "https://drive.google.com/file/d/12O3G4AGtwyup5dMWwfjwdWIQbyC_Hpcn/view"
      #f)
    (course/render-assignment
      "Read and provide chapter summaries: The Higher Criticism (Francis Beattie, 68pp)"
      "https://ia601306.us.archive.org/11/items/highercriticismo00beat/highercriticismo00beat.pdf"
      #f)
    (course/render-assignment
      "Write: Introduction for each New Testament book"
      "https://example.com"
      #f)
    (course/render-assignment
      "Write: 20-page paper on a subject of interest presented in the course material"
      "https://example.com"
      #f)
    (course/render-assignment
      "Helpful resource: A Textual Key to the New Testament"
      "https://drive.google.com/file/d/1M_w6z7phkxUM5TJKrKBFVLqGIm_dCZ1X/view"
      #f)
  ))

(define completed
  (reverse
    (list )))

`([title . "BS541 - New Testament History and Theology"]
  [tasks . [
    ,@(course/render completed todo)]])
