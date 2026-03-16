(use-modules (scripts lib course))

(define todo
  (list
    (course/render-assignment
      "Listen, outline, and take notes: A Call to the Ministry 1-5 (Albert Martin)"
      "https://www.sermonaudio.com/series/31760"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: Call to Ministry 1-4 (J.I. Packer et al.)"
      "https://drive.google.com/drive/folders/1z6uNhtCmD4NyW4uQnpWVTQBfqzUPPONV"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: A Case for the Call 1-3 (Mark Johnson)"
      "https://drive.google.com/drive/folders/1EunpJ8uBXeso9LLoE2xKHQeURMoNgvhF"
      #f)
    (course/render-assignment
      "Read: Address to Students of Divinity (John Brown of Haddington)"
      "https://archive.org/details/compendiousviewo00bro"
      #f)
    (course/render-assignment
      "Read: Scripture Doctrine of a Call to the Work of the Gospel Ministry (W.S. Plumer)"
      "https://archive.org/details/scripturedoctrin01plum/page/n7/mode/2up"
      #f)
    (course/render-assignment
      "Read: The Qualifications of the Christian Ministry (Charles Bridges)"
      "https://archive.org/details/christianminist05bridgoog"
      #f)
    (course/render-assignment
      "Read: The Importance of a Thorough and Adequate Course of Preparatory Study for the Holy Ministry (Samuel Miller)"
      "https://archive.org/details/importanceofthor00mill"
      #f)
    (course/render-assignment
      "Read: An Address to Candidates for the Ministry (Archibald Alexander)"
      "https://archive.org/details/addresstocandida05alex"
      #f)
    (course/render-assignment
      "Read: The Religious Life of Theological Students (B.B. Warfield)"
      "https://drive.google.com/file/d/1FoWayMXzFiPiNLzj7awsF1UQomq_ST0l/view"
      #f)
    (course/render-assignment
      "Read: The Danger of an Unconverted Ministry (Gilbert Tennent)"
      "https://drive.google.com/file/d/1S9ZouPRCbBjHBtiArE1NU43uQqgrOl_X/view"
      #f)
    (course/render-assignment
      "Complete: James Nisbet's Spiritual Checklist and personal evaluation"
      "https://drive.google.com/file/d/1yCpnspeIfiEFlk62QPh2B_dAhoarZb0b/view"
      #f)
    (course/render-assignment
      "Present to mentor: Written summary of your personal call to ministry"
      "https://example.com"
      #f)
  ))

(define completed
  (reverse
    (list
)))

`([title . "PRE500 - Preparatory Studies"]
  [tasks . [
    ,@(course/render completed todo)]])
