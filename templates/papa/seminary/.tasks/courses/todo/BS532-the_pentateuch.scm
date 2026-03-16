(use-modules (scripts lib course))

(define todo
  (list
    (course/render-assignment
      "Read: Genesis, Exodus, Leviticus, Numbers, and Deuteronomy"
      "https://example.com"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: The Pentateuch 1-29 (Dr. Richard Pratt, 17h)"
      "https://drive.google.com/drive/folders/16luovu94A0pTAZLSTz1dqmwOnVC6qeQR"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: Genesis - Joshua 1-26 (Dr. Richard Belcher, 23h)"
      "https://www.subsplash.com/reformtheosem/learn-about-rts/li/+b6c9958?" ; NOTE: 404
      #f)
    (course/render-assignment
      "Read and provide chapter summaries: Introduction to the Pentateuch Vol I (pp. 1-367) (Donald MacDonald)"
      "https://archive.org/details/introductiontope01macd"
      #f)
    (course/render-assignment
      "Read and provide chapter summaries: Introduction to the Pentateuch Vol II (pp. 1-478) (Donald MacDonald)"
      "https://archive.org/details/introductiontope02macd/page/n5/mode/1up"
      #f)
    (course/render-assignment
      "Read and summarize: Other \"Interpretations of Genesis\" (Jason Lisle and Tim Chaffey)"
      "https://answersingenesis.org/genesis/other-interpretations-of-genesis/"
      #f)
    (course/render-assignment
      "Read and summarize: Problems with Other Interpretations (Jason Lisle and Tim Chaffey)"
      "https://answersingenesis.org/genesis/problems-with-other-interpretations/"
      #f)
    (course/render-assignment
      "Read and summarize: Are there Gaps in the Genesis Genealogies? (Jason Lisle and Tim Chaffey)"
      "https://answersingenesis.org/bible-timeline/genealogy/are-there-gaps-in-the-genesis-genealogies/"
      #f)
    (course/render-assignment
      "Write: Two 15-page papers on subjects of interest pertaining to the Pentateuch"
      "https://example.com"
      #f)
  ))

(define completed
  (reverse
    (list )))

`([title . "BS532 - The Pentateuch"]
  [tasks . [
    ,@(course/render completed todo)]])
