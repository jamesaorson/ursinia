(use-modules (scripts lib course))

(define todo
  (list
    (course/render-assignment
      "Listen, outline, and take notes: General Hermeneutics (Dr. Moises Silva, 5h)"
      "https://students.wts.edu/resources/media.html?paramType=search&keywords=hermeneutics&speaker=92&ScrBook=&ScrChap=&ScrVerse=&ScrVerseEnd=&year=&srch=search"
      #f)
    (course/render-assignment 
      "Listen, outline, and take notes: General Hermeneutics (Dr. Vern Poythress, 45h)"
      "https://students.wts.edu/resources/media.html?paramType=search&keywords=hermeneutics&speaker=7&ScrBook=&ScrChap=&ScrVerse=&ScrVerseEnd=&year=&srch=search"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: Lecture Diagrams (Refer to these diagrams as you listen to Poythress lectures, 50h)"
      "https://drive.google.com/file/d/1Msw__XoQWMA6tXmEyF_TdjfnRuPLwBcN/view"
      #f)
    (course/render-assignment
      "Read and provide chapter summaries: Principles of Biblical Interpretation (Louis Berkhof, 166pp)"
      "https://archive.org/details/biblicalhermeneu00terr"
      #f)
    (course/render-assignment
      "Read and provide chapter summaries: Biblical Hermeneutics (Milton Terry, 802pp)"
      "https://media.sabda.org/alkitab-2/PDF%20Books/00050%20Berkhof%20Principles%20of%20Biblical%20Interpretation..pdf"
      #f)
    (course/render-assignment
      "Write: 5-page paper outlining a proper method of biblical interpretation"
      "https://example.com"
      #f)
    (course/render-assignment
      "Write: five 5-page exegetical papers, each demonstrating a proper hermeneutical approach to a passage chosen from each of the following biblical genres - narrative, poetic, prophetic, epistles, apocalyptic"
      "https://example.com"
      #f)
  ))

(define completed
  (reverse
    (list )))

`([title . "BS502 - Hermeneutics"]
  [tasks . [
    ,@(course/render completed todo)]])
