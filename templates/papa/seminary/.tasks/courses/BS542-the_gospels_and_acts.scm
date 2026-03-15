(use-modules (scripts lib course))

(define todo
  (list
    (course/render-assignment
      "Read: Matthew, Mark, Luke, John, Acts"
      "https://example.com"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: The Gospels 1-10 (IIIM, 17h)"
      "https://reformedseminary.org/course.asp/vs/gos"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: The Gospels 1-40 (Dr. Robert Cara, 25h)"
      "https://drive.google.com/file/d/1LgyqUPu72GtbkqyzJOPnpFTz3oSpdYeC/view"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: The Book of Acts 1-63 (Dr. R.C. Sproul, 25h)"
      "https://learn.ligonier.org/series/book-of-acts"
      "...")
    (course/render-assignment
      "Read and provide chapter summaries: How to Study the New Testament: The Gospels and Acts of the Apostles (Henry Alford, 377pp)"
      "https://archive.org/details/howtostudynewte00alfogoog"
      "...")
    (course/render-assignment
      "Read and provide chapter summaries: The Teaching of Jesus Concerning the Kingdom of God and the Church (Geerhardus Vos, 190pp)"
      "https://archive.org/details/theteachingofjes00vosuoft"
      "...")
    (course/render-assignment
      "Write: Two 15-page papers on subjects of interest presented in the course material"
      "https://example.com"
      "...")
  ))

(define completed
  (reverse
    (list )))

`([title . "BS542 - The Gospels and Acts"]
  [tasks . [
    ,@(course/render completed todo)]])
