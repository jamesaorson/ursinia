(use-modules (scripts lib course))

(define todo
  (list
    (course/render-assignment
      "Read: Joshua - Esther"
      "https://example.com"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: Old Testament History 1-37 (Dr. Phil Long, 24h)"
      "https://resources.covenantseminary.edu/programs/old-testament-history?categoryId=106866&permalink=old-testament-history-lecture-1a"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: Joshua (Lec. 27) (Dr. Richard Belcher, 1h)"
      "https://www.subsplash.com/reformtheosem/learn-about-rts/li/+b6c9958?" ; NOTE: 404
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: Judges - Esther 1-22 (Dr. Richard Belcher, 20h)"
      "https://www.subsplash.com/reformtheosem/learn-about-rts/li/+79eb036?" ; NOTE: 404
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: The Life of David (Dr. R.C. Sproul, 5.5h)"
      "https://learn.ligonier.org/series/life-of-david"
      #f)
    (course/render-assignment
      "Read and provide chapter summaries: A History of the Israelitish Nation, Parts III-IV (pp. 175-422) (Archibald Alexander, 247pp)"
      "https://archive.org/details/historyofisraeli00alex"
      #f)
    (course/render-assignment
      "Read and provide chapter summaries: The Kings of Israel and Judah (George Rawlinson, 264pp)"
      "https://archive.org/details/cu31924029279423"
      #f)
    (course/render-assignment
      "Write: Two 15-page papers on subjects of interest presented in the course material"
      "https://example.com"
      #f)
  ))

(define completed
  (reverse
    (list )))

`([title . "BS533 - Old Testament Historical Books"]
  [tasks . [
    ,@(course/render completed todo)]])
