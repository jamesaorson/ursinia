(use-modules (scripts lib course))

(define todo
  (list
    (course/render-assignment
      "Read: Isaiah - Malachi"
      "https://example.com"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: Lectures in Prophecy 1-8 (Dr. Richard Pratt, 7h)"
      "https://drive.google.com/drive/folders/1GD1pTaiRy2CWYefCZkpgq7Uyqm471oNv"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: Isaiah - Malachi 1-34 (Dr. Richard Belcher)"
      "https://www.subsplash.com/reformtheosem/learn-about-rts/ms/+39145a6?" ; NOTE: 404
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: Isaiah - Malachi 1-21 (Dr. Richard Pratt, 13h)"
      "https://drive.google.com/drive/folders/1OFNaJ6VoI9nLO6QyIaZmbsmumCiBmyKj"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: Lessons from Lamentations (Dr. John Blanchard, 1h)"
      "https://www.sermonaudio.com/sermons/1250832259"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: Introduction to the Minor Prophets 1-12 (Dr. John Blanchard, 8.5h)"
      "https://www.sermonaudio.com/series/3315"
      #f)
    (course/render-assignment
      "Read and provide chapter summaries: My Servants the Prophets (Edward Young, 208pp)"
      "https://archive.org/details/MyServantsTheProphets"
      #f)
    (course/render-assignment
      "Read and provide chapter summaries: The Interpretation of Prophecy (Patrick Fairbairn, 538pp)"
      "https://archive.org/details/prophecyviewedin00fair"
      #f)
    (course/render-assignment
      "Read and provide chapter summaries: Daniel's Eschatology (Dr. Francis Nigel Lee, 64pp)"
      "https://drive.google.com/file/d/1MwLmkYxAFNOqKBVWzt-Z5M817TT6PPZ4/view"
      #f)
    (course/render-assignment
      "Write: 30-page paper on a subject of interest presented in the course material"
      "https://example.com"
      #f)
    (course/render-assignment
      "Helpful resource: Chronological Table of the Prophets"
      "https://drive.google.com/file/d/1BNqE5VBpNSCuyibYIPDW43792jLtDzFG/view"
      #f)
  ))

(define completed
  (reverse
    (list )))

`([title . "BS535 - Old Testament Prophetic Books"]
  [tasks . [
    ,@(course/render completed todo)]])
