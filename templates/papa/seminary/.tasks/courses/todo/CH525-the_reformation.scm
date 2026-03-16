(use-modules (scripts lib course))

(define todo
  (list
    (course/render-assignment
      "Listen, outline, and take notes: The Reformation 1-33 (Dr. Carl Trueman, 30h)"
      "https://itunes.apple.com/us/itunes-u/the-reformation/id924126015?mt=10"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: Reformation Church History 1-27 (Dr. Peter Lillback, 18h)"
      "https://students.wts.edu/resources/media.html?paramType=search&keywords=Reformation+Church+History&speaker=14&ScrBook=&ScrChap=&ScrVerse=&ScrVerseEnd=&year=2001&srch=search" ; NOTE: 404
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: Learning from the Reformers (Dr. John Blanchard, 48m)"
      "https://www.sermonaudio.com/sermons/12508315405"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: The Making of the Protestant Reformation 1-2 (R.C. Sproul, 42m)"
      "https://learn.ligonier.org/series/making-of-the-protestant-reformation"
      #f)
    (course/render-assignment
      "Read and provide chapter summaries: The Reformers and the Theology of the Reformation (William Cunningham, 642pp)"
      "https://archive.org/details/reformerstheolog00cunn"
      #f)
    (course/render-assignment
      "Write: 30-page paper on a subject of interest presented in the course materials"
      "https://example.com"
      #f)
  ))

(define completed
  (reverse
    (list )))

`([title . "CH525 - The Reformation"]
  [tasks . [
    ,@(course/render completed todo)]])
