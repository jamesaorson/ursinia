(use-modules (scripts lib course))

(define todo
  (list
    (course/render-assignment
      "Listen, outline, and take notes: Systematic Theology III (Dr. Douglas Kelly, 16h)"
      "https://drive.google.com/file/d/1W0ubQMjJlWZx5mwNkaE_hSYF2QHJ6Y0I/view"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: School of Theology 68-78 (Dr. Derek Thomas, 8h)"
      "https://www.sermonaudio.com/series/12348"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: Lectures on the Church 1-15 (Dr. Edmund Clowney, 15.5h)"
      "https://drive.google.com/file/d/1epoiKUYepfBR83rGFkXJA8gV2Upsb5xT/view"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: Church and State 1-7 (R.C. Sproul, 2.5h)"
      "https://learn.ligonier.org/series/church-and-state"
      "...")
    (course/render-assignment
      "Read and provide chapter summaries: A Compendious View of Natural and Revealed Religion, pp. 517-576 (John Brown of Haddington, 59pp)"
      "https://archive.org/details/compendiousviewo00bro"
      "...")
    (course/render-assignment
      "Read and provide chapter summaries: Systematic Theology Vol. 3, pp. 466-712 (Charles Hodge, 246pp)"
      "https://archive.org/details/systematictheolo03hodg/page/n5/mode/2up"
      "...")
    (course/render-assignment
      "Read and provide chapter summaries: Systematic Theology Lec. 60-68 (R.L. Dabney, 104pp)"
      "https://archive.org/details/syllabusnotesofc00dabn/page/n5/mode/2up"
      "...")
    (course/render-assignment
      "Read and provide chapter summaries: Which is the Apostolic Church? (Thomas Witherow, 140pp)"
      "https://archive.org/details/whichisapostolic00with"
      "...")
    (course/render-assignment
      "Read and provide chapter summaries: The Church of Christ Vol. 1 (James Bannerman, 1,000pp)"
      "https://archive.org/details/churchofchristtr01bann"
      "...")
    (course/render-assignment
      "Read and provide chapter summaries: The Church of Christ Vol. 2 (James Bannerman, 1,000pp)"
      "https://archive.org/details/churchofchristtr02bann"
      "...")
    (course/render-assignment
      "Read and provide chapter summaries: Infant Baptism (Samuel Miller, 158pp)"
      "https://archive.org/details/infantbaptismscr00mi"
      "...")
    (course/render-assignment
      "Write: 30 page paper comparing Brown, Hodge, and Dabney"
      "https://example.com"
      "...")
  ))

(define completed
  (reverse
    (list
)))

`([title . "TH533 - Systematic Theology III"]
  [tasks . [
    ,@(course/render completed todo)]])