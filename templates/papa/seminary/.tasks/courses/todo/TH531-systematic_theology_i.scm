(use-modules (scripts lib course))

(define todo
  (list
    (course/render-assignment
      "Listen, outline, and take notes: Systematic Theology I (Dr. Douglas Kelly, 27h)"
      "https://drive.google.com/file/d/1W0ubQMjJlWZx5mwNkaE_hSYF2QHJ6Y0I/view"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: School of Theology 1-25 (Dr. Derek Thomas, 23h)"
      "https://www.sermonaudio.com/series/12348"
      "...")
    (course/render-assignment
      "Read and summarize: The Indispensableness of Systematic Theology to the Preacher (BB Warfield, 9pp)"
      "https://drive.google.com/file/d/18es2Xs863Fnxplb8EykmY5BjJ5XaKNy2/view"
      "...")
    (course/render-assignment
      "Read and provide chapter summaries: A Compendious View of Natural and Revealed Religion (John Brown of Haddington, pp. 1-191)"
      "https://archive.org/details/compendiousviewo00bro"
      "...")
    (course/render-assignment
      "Read and provide chapter summaries: Systematic Theology Vol. 1 (Charles Hodge, 648pp)"
      "https://archive.org/details/systematictheolo01hodg/page/n7/mode/2up"
      "...")
    (course/render-assignment
      "Read and provide chapter summaries: Systematic Theology Vol. 2, pp. 1-122 (Charles Hodge, 122pp)"
      "https://archive.org/details/systematicth02hodg"
      "...")
    (course/render-assignment
      "Read and provide chapter summaries: Dogmatic Theology Vol. 1 (W.G.T. Shedd, 546pp)"
      "https://archive.org/details/dogmatictheology01sheduoft"
      "...")
    (course/render-assignment
      "Read and provide chapter summaries: Dogmatic Theology Vol. 2, pp. 3-147 (W.G.T. Shedd, 144pp)"
      "https://archive.org/details/dogmatictheology02sheduoft"
      "...")
    (course/render-assignment
      "Read and provide chapter summaries: Systematic Theology Lec. 1-26 (R.L. Dabney, 305pp)"
      "https://archive.org/details/syllabusnotesofc00dabn/page/n5/mode/2up"
      "...")
    (course/render-assignment
      "Write: 30 page paper comparing Brown, Hodge, Shedd, and Dabney"
      "https://example.com"
      "...")
  ))

(define completed
  (reverse
    (list )))

`([title . "TH531 - Systematic Theology I"]
  [tasks . [
    ,@(course/render completed todo)]])