(use-modules (scripts lib course))

(define todo
  (list
    (course/render-assignment
      "Listen, outline, and take notes: The Missionary Encounter with World Religions 1-24 (Dr. Harvie Conn, 16h)"
      "https://learn.artosacademy.org/courses/the-missionary-encounter-with-world-religions/" ; NOTE: 404
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: World Religions 1-8 (Dr. Hans Bayer et al., 7h)"
      "https://www.covenantseminary.edu/resources/lecture-series/the-francis-schaeffer-apologetics-seminar-2002-world-religions/" ; NOTE: 404
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: World Religions 1-20 (Dr. Timothy Tennent, 11h)"
      "https://drive.google.com/drive/folders/1vQ8AOLBhhkO40duZX8Q-BWRwXUskC2hl"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: Roman Catholicism 1-5 (Dr. R.C. Sproul, 4h)"
      "https://learn.ligonier.org/series/roman-catholicism"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: Confronting the Cults 1-10 (Dr. Curt Daniel, 7.5h)"
      "https://www.sermonaudio.com/series/10531"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: Is Jesus the Only Savior? (Dr. Ronald Nash, 1h)"
      "https://drive.google.com/file/d/1_L15bWowES4Znv-QB5hHBsjGNGmgSvwz/view"
      #f)
    (course/render-assignment
      "Read and provide chapter summaries: The Religions of the World (David James Burrell, 348pp)"
      "https://archive.org/details/religionsofworld00burruoft"
      #f)
    (course/render-assignment
      "Read and provide chapter summaries: The Light of the World: A Brief Comparative Study of Christianity and Non-Christian Religions (Robert Speer, 416pp)"
      "https://archive.org/details/lightofworldbrie00spe"
      #f)
    (course/render-assignment
      "Read and provide chapter summaries: Cults and Contemporary Religious Movements (Probe Ministries, 167pp)"
      "https://drive.google.com/file/d/10mFb7_D2Ix2XuTiGRC-zRRt_hWWv_Y4-/view"
      #f)
    (course/render-assignment
      "Write: 30-page paper on a world religion with directives on how Christians can best relate and share the gospel with that religion's adherents"
      "https://example.com"
      #f)
  ))

(define completed
  (reverse
    (list )))

`([title . "AP605 - Survey of World Religions and Cults"]
  [tasks . [
    ,@(course/render completed todo)]])
