(use-modules (scripts lib course))

(define todo
  (list
    (course/render-assignment
      "Listen, outline, and take notes: No Apology for Apologetics (Dr. John Blanchard, 51m)"
      "https://www.sermonaudio.com/sermoninfo.asp?sermonID=92509234392" ; NOTE: 404
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: Defending Your Faith 1-32 (Dr. R.C. Sproul, 14h)"
      "https://drive.google.com/file/d/15uN1c4nCKnBuhKtxlwrYdxP4i1vab_uc/view"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: Apologetics 1-44 (Dr. Douglas Groothuis, 31h)"
      "https://www.monergism.com/legacy/mt/mp3/dr-douglas-groothuis-apologetics-mp3s"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: Christian Apologetics 1-17 (Dr. Ronald Nash, 14.5h)"
      "https://drive.google.com/drive/folders/1-OYYC31p5alCxO3UexxolYhFk2XQgJx7"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: Objections Answered 1-8 (Dr. R.C. Sproul, 3h)"
      "https://learn.ligonier.org/series/objections-answered"
      "...")
    (course/render-assignment
      "Read and provide chapter summaries: Apologetics, or the Rational Vindication of Christianity (Francis Beattie, 624pp)"
      "https://archive.org/details/apologeticsorrat01beat"
      "...")
    (course/render-assignment
      "Read and provide chapter summaries: Evidences of the Authenticity, Inspiration, and Canonical Authority of the Holy Scriptures (Archibald Alexander, 322pp)"
      "https://archive.org/details/evidencesofauth00alex"
      "...")
    (course/render-assignment
      "Write: 30-page paper outlining your personal approach to apologetics and presenting a defense of the Christian faith with special attention to modern objections"
      "https://example.com"
      "...")
  ))

(define completed
  (reverse
    (list )))

`([title . "AP600 - Apologetics"]
  [tasks . [
    ,@(course/render completed todo)]])
