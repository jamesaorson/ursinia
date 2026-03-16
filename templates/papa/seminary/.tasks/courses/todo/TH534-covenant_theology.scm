(use-modules (scripts lib course))

(define todo
  (list
    (course/render-assignment
      "Listen, outline, and take notes: Covenant Theology 1-22 (Dr. Stephen Myers, 20h)"
      "https://www.monergism.com/covenant-theology-23-part-lecture-series"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: Covenant Theology 1-4 (Dr. O Palmer Robertson, 5h)"
      "https://www.monergism.com/covenant-theology-mp3-series"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: On the Covenants 1-6 (Dr. O Palmer Robertson, 3.5h)"
      "https://www.monergism.com/covenant-theology-mp3-series"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: The Old Testament in the New 1-6 (Dr. O Palmer Robertson, 5.5h)"
      "https://www.sermonaudio.com/series/15498"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: The Promissory Land Covenant in the New Testament (Dr. Bruce Waltke, 1h)"
      "https://media1.wts.edu/media/audio/bw061_copyright.mp3"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: The Temple, the Land, and Paradise Restored (Dr. John Mackay, 1.5h)"
      "https://www.christian.org.uk/resource/the-temple-the-land-and-paradise-restored/"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: Dispensationalism Refuted 1-10 (Dr. Michael Barrett, 7h)"
      "https://www.sermonaudio.com/series/10339"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: Covenant Theology and the Preacher: How Covenant Theology Helps You Preach the Gospel (Dr. Ligon Duncan, 43m)"
      "https://www.sermonaudio.com/sermons/8230794547"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: Church and Covenant Theology (Dr. Morton Smith, 58m)"
      "https://www.sermonaudio.com/sermons/2180471237"
      #f)
    (course/render-assignment
      "Read and provide chapter summaries: A Treatise on the Covenant of Grace (John Colquhoun, 556pp)"
      "https://ia800101.us.archive.org/33/items/treatiseoncovena00colq_0/treatiseoncovena00colq_0.pdf"
      #f)
    (course/render-assignment
      "Read and provide chapter summaries: A History of the Work of Redemption, pp. 1-302 (Jonathan Edwards, 302pp)"
      "https://drive.google.com/file/d/1w-k3vT-NwFW9EWK00ZfRSMJpkQZGhELi/view"
      #f)
    (course/render-assignment
      "Read and provide chapter summaries: Christ in all the Scriptures (A.M. Hodgkin, 272pp)"
      "https://archive.org/details/christinallscrip00hodguoft"
      #f)
    (course/render-assignment
      "Write: 30 page paper outlining the key concepts integral to covenant theology"
      "https://example.com"
      #f)
  ))

(define completed
  (reverse
    (list
)))

`([title . "TH534 - Covenant Theology"]
  [tasks . [
    ,@(course/render completed todo)]])