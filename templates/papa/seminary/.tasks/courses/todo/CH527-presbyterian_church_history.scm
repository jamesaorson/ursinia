(use-modules (scripts lib course))

(define todo
  (list
    (course/render-assignment
      "Listen, outline, and take notes: American Presbyterianism 1-19 (Dr. Don Fortson, 15h)"
      "https://drive.google.com/file/d/14JPX5PTmxQ2TnKIbl3N_k2MbWvJq7ISY/view"
      "...")
    (course/render-assignment
      "Read and provide chapter summaries: History of the Presbyterian Churches of the World (R.C. Reed, 428pp)"
      "https://archive.org/details/historyofpresbyt1915reed/page/n5/mode/2up"
      "...")
    (course/render-assignment
      "Read and provide chapter summaries: History of Presbyterianism in All Ages (Robert Kerr, 312pp)"
      "https://archive.org/details/peopleshistoryof00kerr"
      "...")
    (course/render-assignment
      "Write: 20-page paper on a subject of interest presented in the course materials"
      "https://example.com"
      "...")
  ))

(define completed
  (reverse
    (list )))

`([title . "CH527 - Presbyterian Church History"]
  [tasks . [
    ,@(course/render completed todo)]])
