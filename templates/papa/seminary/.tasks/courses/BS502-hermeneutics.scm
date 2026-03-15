(use-modules (scripts lib course))

(define todo
  (list
    (course/render-assignment
      "Listen, outline, and take notes: General Heremeneutics (Dr. Moises Silva, 5h)"
      "https://students.wts.edu/resources/media.html?paramType=search&keywords=hermeneutics&speaker=92&ScrBook=&ScrChap=&ScrVerse=&ScrVerseEnd=&year=&srch=search"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: General Heremeneutics (Dr. Vern Poythress, 45h)"
      "https://students.wts.edu/resources/media.html?paramType=search&keywords=hermeneutics&speaker=7&ScrBook=&ScrChap=&ScrVerse=&ScrVerseEnd=&year=&srch=search"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: Lecture Diagrams (Refer to these diagrams as you listen to Poythress lectures, 50h)"
      "https://drive.google.com/file/d/1Msw__XoQWMA6tXmEyF_TdjfnRuPLwBcN/view"
      "...")
    (course/render-assignment
      "Read and provide chapter summaries: General Heremeneutics (Dr. Moises Silva, 5h)"
      ""
      "...")
    (course/render-assignment
      "Read and provide chapter summaries: General Heremeneutics (Dr. Moises Silva, 5h)"
      ""
      "...")
  ))

(define completed
  (reverse
    (list )))

`([title . "BS502 - Hermeneutics"]
  [tasks . [
    ,@(course/render completed todo)]])
