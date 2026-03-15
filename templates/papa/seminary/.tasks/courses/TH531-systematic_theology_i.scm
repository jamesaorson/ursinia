(use-modules (scripts lib course))

(define todo
  (list
    (course/render-assignment
      "Lecture Notes: Systematic Theology I (Dr. Douglas Kelly)"
      "https://drive.google.com/file/d/1W0ubQMjJlWZx5mwNkaE_hSYF2QHJ6Y0I/view"
      "Listen, outline, and take notes on all lectures (27 hours).")
    (course/render-assignment
      "Lecture Notes: School of Theology 1-25 (Dr. Derek Thomas)"
      "https://www.sermonaudio.com/series/12348"
      "Listen, outline, and take notes on all lectures (23 hours).")
    (course/render-assignment
      "Read: The Indispensableness of Systematic Theology to the Preacher (BB Warfield)"
      "https://drive.google.com/file/d/18es2Xs863Fnxplb8EykmY5BjJ5XaKNy2/view"
      "Read and take notes (9 pages).")
    (course/render-assignment
      "Read & Summarize: A Compendious View of Natural and Revealed Religion (John Brown of Haddington)"
      "https://archive.org/details/compendiousviewo00bro"
      "Read pp. 1-191 and provide chapter summaries.")
    (course/render-assignment
      "Read & Summarize: Systematic Theology Vol. 1 (Charles Hodge)"
      "https://archive.org/details/systematictheolo01hodg/page/n7/mode/2up"
      "Read and summarize (648 pages).")
    (course/render-assignment
      "Read & Summarize: Systematic Theology Vol. 2, pp. 1-122 (Charles Hodge)"
      "https://archive.org/details/systematicth02hodg"
      "Read and summarize (122 pages).")
    (course/render-assignment
      "Read & Summarize: Dogmatic Theology Vol. 1 (W.G.T. Shedd)"
      "https://archive.org/details/dogmatictheology01sheduoft"
      "Read and summarize (546 pages).")
    (course/render-assignment
      "Read & Summarize: Dogmatic Theology Vol. 2, pp. 3-147 (W.G.T. Shedd)"
      "https://archive.org/details/dogmatictheology02sheduoft"
      "Read and summarize (144 pages).")
    (course/render-assignment
      "Read & Summarize: Systematic Theology Lec. 1-26 (R.L. Dabney)"
      "https://archive.org/details/syllabusnotesofc00dabn/page/n5/mode/2up"
      "Read and summarize (305 pages).")
    (course/render-assignment
      "30 Page Paper: Compare Brown, Hodge, Shedd, Dabney"
      "https://example.com"
      "Write a 30 page paper comparing and contrasting the views of Brown, Hodge, Shedd, and Dabney on the course topics.")
  ))

(define completed
  (reverse
    (list )))

`([title . "TH531 - Systematic Theology I"]
  [tasks . [
    ,@(course/render completed todo)]])