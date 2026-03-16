(use-modules (scripts lib course))

(define todo
  (list
    (course/render-assignment
      "Listen, outline, and take notes: Christian Ethics 1-24 (Dr. Ronald Nash, 18.5h)"
      "https://drive.google.com/drive/folders/1vGMi2aIGmdnzAQLETprQbOd6khAHUzC7"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: Christian Ethics 1-21 (Dr. Daniel Doriani, 25h)"
      "https://www.covenantseminary.edu/resources/christian-ethics-doriani/" ; NOTE: 404
      "...")
    (course/render-assignment
      "Read and provide chapter summaries: A Theory of Conduct (Archibald Alexander, 134pp)"
      "https://archive.org/details/theoryofconduct00alexiala/page/n7/mode/2up"
      "...")
    (course/render-assignment
      "Read and provide chapter summaries: The Revelation of Law in Scripture (Patrick Fairbairn, 524pp)"
      "https://archive.org/details/therevelationofl00fairuoft"
      "...")
    (course/render-assignment
      "Read and provide chapter summaries: An Exposition of the Ten Commandments (Ezekiel Hopkins, 456pp)"
      "https://archive.org/details/expositionoftenc00hopk"
      "...")
    (course/render-assignment
      "Write: 15-page paper defending the continuing validity, obligation, and use of the moral law in the life of the New Testament Christian"
      "https://example.com"
      "...")
    (course/render-assignment
      "Write: 15-page commentary on the Ten Commandments"
      "https://example.com"
      "...")
  ))

(define completed
  (reverse
    (list )))

`([title . "TH625 - Biblical Ethics"]
  [tasks . [
    ,@(course/render completed todo)]])
