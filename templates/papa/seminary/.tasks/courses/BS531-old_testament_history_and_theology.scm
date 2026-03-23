(use-modules (scripts lib course))

(define todo
  (list
    (course/render-assignment
      "Listen, outline, and take notes: Old Testament Survey 1-56 (Dr. Jack B. Scott, 45h)"
      "https://www.sermonaudio.com/series/35860"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: Old Testament History and Theology 1-13 (Dr. Dan Kim, 18h)"
      "https://resources.covenantseminary.edu/programs/old-testament-history-theology"
      #f)
    (course/render-assignment
      "Read and summarize: Is the Old Testament Reliable? (Brian Edwards)"
      "https://answersingenesis.org/is-the-bible-true/is-the-old-testament-reliable/"
      #f)
    (course/render-assignment
      "Read and summarize: A Scientific Investigation of the Old Testament (Robert Dick Wilson, 200pp)"
      "https://www.bbfchurch.net/SiteData/bbf/A-Scientific-Investigation-of-the-OT-Robert-Dick-Wilson.pdf"
      #f)
    (course/render-assignment
      "Read and summarize: Is the Higher Criticism Scholarly? (Robert Dick Wilson, 74pp)"
      "https://archive.org/details/ishighercriticis00wils"
      #f)
    (course/render-assignment
      "Read and summarize: Does Archaeology Support the Bible? (Clifford Wilson, The New Answers Book, ch. 25)"
      "https://answersingenesis.org/archaeology/does-archaeology-support-the-bible/"
      #f)
    (course/render-assignment
      "Read and summarize: Dead Sea Scrolls: Timeless Treasures from Qumran (Jeremy Lyon)"
      "https://kidsanswers.org/kids-feedback-dead-sea-scrolls/" ; NOTE: This seems wrong...
      #f)
    (course/render-assignment
      "Read and provide chapter summaries: The Church During the Old Testament Dispensation (C.C. Jones, 558pp)"
      "https://archive.org/details/historyofchurcho00jone/page/n8/mode/1up"
      #f)
    (course/render-assignment
      "Read and provide chapter summaries: The Typology of Scripture, Vol. 1 (Patrick Fairbairn)"
      "https://archive.org/details/typologyofscript01fairiala"
      #f)
    (course/render-assignment
      "Read and provide chapter summaries: The Typology of Scripture, Vol. 2 (Patrick Fairbairn)"
      "https://archive.org/details/typologyofscript02fairiala"
      #f)
    (course/render-assignment
      "Write: Introduction for each Old Testament book"
      "https://example.com"
      #f)
    (course/render-assignment
      "Write: 20-page paper on a subject of interest presented in the course material"
      "https://example.com"
      #f)
  ))

(define completed
  (reverse
    (list )))

`([title . "BS531 - Old Testament History and Theology"]
  [tasks . [
    ,@(course/render completed todo)]])
