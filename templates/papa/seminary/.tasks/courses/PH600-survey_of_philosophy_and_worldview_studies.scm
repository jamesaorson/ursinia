(use-modules (scripts lib course))

(define todo
  (list
    (course/render-assignment
      "Listen, outline, and take notes: Worldview Series 1-7 (Stephen Gambill, 6.5h)"
      "https://www.sermonaudio.com/series/50392"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: Modern-isms (3 lectures) (The Christian Institute, 4h)"
      "https://www.christian.org.uk/resources/series/modern-isms/"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: Pluralism (The Christian Institute, 1h)"
      "https://www.christian.org.uk/pluralism/"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: The Consequences of Ideas 1-35 (Dr. R.C. Sproul, 15h)"
      "https://www.sermonaudio.com/series/21236"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: History of Philosophy and Christian Thought 1-36 (Dr. Ronald Nash, 28h)"
      "https://drive.google.com/drive/folders/1mp3TQdFaHBIqgXB9VnMoF1IOnq1F7nEn"
      #f)
    (course/render-assignment
      "Read and provide chapter summaries: Introduction to Worldviews (Probe Ministries, 301pp)"
      "https://drive.google.com/file/d/1TgxwD80oD6NUJvd8PoxerFhVEr6bdwNB/view"
      #f)
    (course/render-assignment
      "Read and provide chapter summaries: Redeeming Philosophy (Dr. Vern Poythress, 306pp)"
      "https://www.frame-poythress.org/wp-content/uploads/2014/11/BPhilFinal2014.pdf"
      #f)
    (course/render-assignment
      "Write: 30-page paper on a topic of interest presented in the course materials"
      "https://example.com"
      #f)
  ))

(define completed
  (reverse
    (list )))

`([title . "PH600 - Survey of Philosophy and Worldview Studies"]
  [tasks . [
    ,@(course/render completed todo)]])
