(use-modules (scripts lib course))

(define todo
  (list
    (course/render-assignment
      "Read: Romans - Jude"
      "https://example.com"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: Life and Letters of Paul 1-35 (Dr. Hans Bayer, 23h)"
      "https://resources.covenantseminary.edu/programs/life-letters-paul"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: Pauline Epistles 1-35 (Dr. Robert Cara, 25.5h)"
      "https://www.subsplash.com/reformtheosem/learn-about-rts/ms/+tj7t9pd?" ; NOTE: 404
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: Hebrews to Revelation 1-20, 31-36 (Dr. Dan Doriani, 20.5h)"
      "https://drive.google.com/file/d/1ZDAH6bh4FbCRrx_vTV1GUPfxIqGZpZEp/view"
      "...")
    (course/render-assignment
      "Read and provide chapter summaries: How to Study the New Testament: The Epistles I (Henry Alford, 304pp)"
      "https://archive.org/details/howtostudynewt00alfo"
      "...")
    (course/render-assignment
      "Read and provide chapter summaries: How to Study the New Testament: The Epistles II, pp. 1-277 (Henry Alford, 277pp)"
      "https://archive.org/details/howtostudynewtes00alfo/"
      "...")
    (course/render-assignment
      "Write: Two 15-page papers on subjects of interest presented in the course material"
      "https://example.com"
      "...")
  ))

(define completed
  (reverse
    (list )))

`([title . "BS543 - New Testament Epistles"]
  [tasks . [
    ,@(course/render completed todo)]])
