(use-modules (scripts lib class))

(define todo
  (list
    (class/render-assignment
      "Listen, outline, and take notes on: Systematic Theology II (Dr. Douglas Kelly, 25h)"
      "https://drive.google.com/file/d/1W0ubQMjJlWZx5mwNkaE_hSYF2QHJ6Y0I/view"
      "...")
    (class/render-assignment
      "Listen, outline, and take notes on: School of Theology 26-67; 79-96 (Dr. Derek Thomas, 47.5h)"
      "https://www.sermonaudio.com/series/12348"
      "...")
    (class/render-assignment
      "Listen, outline, and take notes on: Predestination 1-10 (Dr. R.C. Sproul, 3.5h)"
      "https://learn.ligonier.org/series/predestination"
      "...")
    (class/render-assignment
      "Listen, outline, and take notes on: Justification by Faith Alone 1-15 (Dr. R.C. Sproul, 5.5h)"
      "https://learn.ligonier.org/series/justification_by_faith_alone"
      "...")
    (class/render-assignment
      "Listen, outline, and take notes on: The New Perspective on Paul 1-3 (Dr. D.A. Carson, 3h)"
      "https://drive.google.com/drive/folders/1HxSmQZfvUk-pDK9cXq8YKa5o61YepCjC"
      "...")
    (class/render-assignment
      "Listen, outline, and take notes on: Postmillennialism and Revelation 20 (David Silversides, 1h9m)"
      "https://www.sermonaudio.com/sermons/9130414633"
      "...")
    (class/render-assignment
      "Read and summarize: A Compendious View of Natural and Revealed Religion, pp. 192-517 (John Brown of Haddington, 325pp)"
      "https://archive.org/details/compendiousviewo00bro"
      "...")
    (class/render-assignment
      "Read and summarize: Systematic Theology Vol. 2, pp. 123-732 (Charles Hodge, 609pp)"
      "https://archive.org/details/systematicth02hodg"
      "...")
    (class/render-assignment
      "Read and summarize: Systematic Theology Vol. 3, pp. 1-465, 713-880 (Charles Hodge, 632pp)"
      "https://archive.org/details/systematictheolo03hodg/page/n5/mode/2up"
      "...")
    (class/render-assignment
      "Read and summarize: Dogmatic Theology Vol. 2, pp. 148-754 (W.G.T. Shedd, 606pp)"
      "https://archive.org/details/dogmatictheology02sheduoft"
      "...")
    (class/render-assignment
      "Read and summarize: Systematic Theology Lec. 27-59; 69-72 (R.L. Dabney, 452pp)"
      "https://archive.org/details/syllabusnotesofc00dabn/page/n5/mode/2up"
      "...")
    (class/render-assignment
      "Read and summarize: What’s Wrong with Wright: Examining the New Perspective on Paul (Phil Johnson)"
      "https://learn.ligonier.org/articles/whats-wrong-wright-examining-new-perspective-paul"
      "...")
    (class/render-assignment
      "Write: 30 page paper comparing Brown, Hodge, Shedd, and Dabney"
      "https://example.com"
      "...")
  ))

(define completed
  (reverse
    (list
)))

`([title . "TH532 - Systematic Theology II"]
  [tasks . [
    ,@(class/render completed todo)]])