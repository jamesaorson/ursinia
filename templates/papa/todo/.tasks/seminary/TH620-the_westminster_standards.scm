(use-modules (scripts lib class))

(define todo
  (list
    (class/render-assignment
      "Listen, outline, and take notes on: Westminster Standards 1-24 (video) (Dr. John Gerstner, 12h)"
      "https://learn.ligonier.org/series/westminster-confession-of-faith"
      "...")
    (class/render-assignment
      "Listen, outline, and take notes on: Theology of the WCF 1-19 (Dr. Morton Smith, 17h)"
      "https://www.sermonaudio.com/series/35866"
      "...")
    (class/render-assignment
      "Listen, outline, and take notes on: Westminster Standards 1-14 (Dr. Sinclair Ferguson, 16h)"
      "https://www.monergism.com/westminster-standards-14-part-mp3-lecture-series"
      "...")
    (class/render-assignment
      "Listen, outline, and take notes on: The American Amendments to the Westminster Confession (Dr. Peter Lillback, 1h6m)"
      "http://media1.wts.edu/media/audio/wa045-copyright.mp3"
      "...")
    (class/render-assignment
      "Read and summarize: The 1788 American Revision of the Westminster Standards (Lee Irons, 15pp)"
      "https://www.upper-register.com/papers/1788_revision.pdf"
      "...")
    (class/render-assignment
      "Read and summarize: The Utility and Importance of Creeds and Confessions (Samuel Miller, 134pp)"
      "https://archive.org/details/utilityimportanc00milluoft"
      "...")
    (class/render-assignment
      "Read and summarize: The Presbyterian Standards (Francis Beattie, 442pp)"
      "https://archive.org/details/presbyterianstan00beat"
      "...")
    (class/render-assignment
      "Read and summarize: A Commentary on the Confession of Faith (A.A. Hodge, 576pp)"
      "https://archive.org/details/commentaryonconf1901hodg"
      "...")
    (class/render-assignment
      "Write: 30 page paper serving as a personal commentary on the Westminster Confession of Faith"
      "https://example.com"
      "...")
    (class/render-assignment
      "Memorize: Westminster Shorter Catechism"
      "https://www.opc.org/sc.html"
      "...")
    (class/render-assignment
      "Exam: Complete the Westminster Shorter Catechism Exam"
      "https://example.com"
      "...")
  ))

(define completed
  (reverse
    (list
)))

`([title . "TH620 - The Westminster Standards"]
  [tasks . [
    ,@(class/render completed todo)]])