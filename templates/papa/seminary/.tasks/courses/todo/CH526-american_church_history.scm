(use-modules (scripts lib course))

(define todo
  (list
    (course/render-assignment
      "Listen, outline, and take notes: History of Christianity in America (Dr. John Hannah, 17h)"
      "https://learn.artosacademy.org/courses/the-history-of-christianity-in-america/" ; NOTE: 404
      "...")
    (course/render-assignment
      "Read and provide chapter summaries: A History of American Christianity (Leonard Woolsey Bacon, 458pp)"
      "https://archive.org/details/historyofamerica00baco"
      "...")
    (course/render-assignment
      "Read and provide chapter summaries: Short History of the Church in the United States (John Hurst, 143pp)"
      "https://archive.org/details/shorthistorychu00hursgoog"
      "...")
    (course/render-assignment
      "Write: 20-page paper on a subject of interest presented in the course material"
      "https://example.com"
      "...")
  ))

(define completed
  (reverse
    (list )))

`([title . "CH526 - American Church History"]
  [tasks . [
    ,@(course/render completed todo)]])
