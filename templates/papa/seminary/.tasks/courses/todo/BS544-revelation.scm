(use-modules (scripts lib course))

(define todo
  (list
    (course/render-assignment
      "Read: Revelation"
      "https://example.com"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: Revelation 1-24 (Dr. Sinclair Ferguson, 14h)"
      "https://www.sermonaudio.com/series/12450"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: Revelation 1-33 (David Silversides, 21h) - Messages in the Silversides Revelation series are not in proper order on the site and need to be rearranged"
      "https://www.sermonaudio.com/series/45497"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: Postmillennialism and Revelation 20 (David Silversides, 1h9m)"
      "https://www.sermonaudio.com/sermons/9130414633"
      "...")
    (course/render-assignment
      "Read and provide chapter summaries: How to Study the New Testament: The Epistles II, pp. 278-315 (Henry Alford, 37pp)"
      "https://archive.org/details/howtostudynewtes00alfo"
      "...")
    (course/render-assignment
      "Read and provide chapter summaries: Exposition of Thomas Goodwin on the Book of Revelation (Thomas Goodwin, 168pp)"
      "https://archive.org/details/theexpositionoft00gooduoft"
      "...")
    (course/render-assignment
      "Read and provide chapter summaries: John's Revelation Unveiled (Francis Nigel Lee, 329pp)"
      "https://drive.google.com/file/d/1MhL8p8Jtr8AcIf06dc_3DG93bqUzpw63/view"
      "...")
    (course/render-assignment
      "Read and provide chapter summaries: Jerusalem, Rome, Revelation - John's Apocalypse Written Before 70 A.D. (Francis Nigel Lee, 90pp)"
      "https://drive.google.com/file/d/1bioamehd1HoOm4eEToAA73m-Vtf7H72-/view"
      "...")
    (course/render-assignment
      "Write: 20-page paper presenting your view of Revelation's purpose and scope"
      "https://example.com"
      "...")
  ))

(define completed
  (reverse
    (list )))

`([title . "BS544 - Revelation"]
  [tasks . [
    ,@(course/render completed todo)]])
