(use-modules (scripts lib course))

(define todo
  (list
    (course/render-assignment
      "Listen, outline, and take notes: Church History Lectures 1-39 (Dr. John Gerstner, 17h)"
      "https://learn.ligonier.org/series/handout-church-history"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: History of Christianity I (Dr. Don Fortson, 21.5h)"
      "https://reformedaudio.org/history-christianity-donald-fortson-iii/"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: History of Christianity II (Dr. Don Fortson, 27h)"
      "https://reformedaudio.org/history-christianity-ii-donald-fortson-iii/"
      "...")
    (course/render-assignment
      "Read and summarize: Uses and Results of Church History (R.L. Dabney, 20pp)"
      "https://archive.org/details/DiscussionsOfRobertLewisDabneyVol.2EvangelicalAndTheological/page/n397/mode/1up?q=call+to+the+ministry"
      "...")
    (course/render-assignment
      "Read and provide chapter summaries: History of the Christian Church (W.M. Blackburn, 748pp)"
      "https://archive.org/details/historyofchrist00blac"
      "...")
    (course/render-assignment
      "Write: 30-page paper on a historical topic presented in the course materials"
      "https://example.com"
      "...")
  ))

(define completed
  (reverse
    (list )))

`([title . "CH520 - History of the Church"]
  [tasks . [
    ,@(course/render completed todo)]])
