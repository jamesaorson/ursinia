(use-modules (scripts lib course))

(define todo
  (list
    (course/render-assignment
      "Listen, outline, and take notes: The Effective Gospel Minister and the Pursuit of Holiness (Dr. Harry Reeder, 64m)"
      "https://www.sermonaudio.com/sermons/62314107148"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: What is a Preacher? (Dr. David Murray, 47m)"
      "https://www.sermonaudio.com/sermons/72113119132"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: The Ministry 1-7 (Dr. Sinclair Ferguson, 8h)"
      "https://www.monergism.com/legacy/mt/mp3/ministry-7-part-lecture-series-dr-sinclair-b-ferguson"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: The Apostolic Foundation for an Effective Pastoral Ministry (Dr. Harry Reeder, 1h)"
      "http://media2.wts.edu/media/audio/reeder-10-22-13-copyright.mp3"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: Survival and Success in Ministry 1-2 (Dr. John DeWitt, 2h)"
      "https://itunes.apple.com/us/itunes-u/survival-success-in-ministry/id422594578?mt=10"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: Dealing with the Highs and Lows of Pastoral Ministry (Dr. Timothy Lane, 22m)"
      "http://media1.wts.edu/media/audio/2007_ch0607tl01.mp3"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: Disappointment and Failure in Ministry (Dr. Timothy Lane, 22m)"
      "http://media1.wts.edu/media/audio/ch0607tl01-copyright.mp3"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: The Pastor and His Study 1 (Ian Murray, 1h)"
      "https://www.thegospelcoalition.org/sermon/the-pastor-and-his-study-part-1-en/"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: The Pastor and His Study 2 (Ian Murray, 1h)"
      "https://www.thegospelcoalition.org/sermon/the-pastor-and-his-study-part-2-en/"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: The Pastor and His Study 3 (Ian Murray, 1h)"
      "https://www.thegospelcoalition.org/sermon/the-pastor-and-his-study-part-3-en/"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: The Church in Biblical Perspective 1-12 (Dr. Harry Reeder, 9h)"
      "https://drive.google.com/drive/folders/12QSfcKjomnMBKm21jccp7QYqYvG9_OBZ"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: The Christ-Centered Disciple 1-12 (Dr. Harry Reeder, 9h)"
      "https://drive.google.com/drive/folders/14aNrlGjdGvEZdemD1cw-XvAlYPzjfmMC"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: Biblical Counseling 1-16 (Stephen Gambill, 15h)"
      "https://www.sermonaudio.com/series/50371"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: Essential Objectives of Biblical Parenting (Dr. Harry Reeder, 53m)"
      "https://www.sermonaudio.com/sermons/82916951294"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: Family Worship (Dr. Harry Reeder, 47m)"
      "https://drive.google.com/file/d/1dPjE9TB2y5PQsCTT671-OCxr4Y2Ceycc/view"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: Leadership 1-10 (Dr. David Murray, 5h)"
      "https://www.sermonaudio.com/series/26991"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: Worship 1-10 (Dr. R.C. Sproul, 3.5h)"
      "https://learn.ligonier.org/series/worship"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: Puritans and Pastoral Ministry (Dr. Sinclair Ferguson, 40m)"
      "https://media2.wts.edu/media/audio/insfck-copyright.mp3"
      "...")
    (course/render-assignment
      "Read and provide chapter summaries: An Earnest Ministry (John Angell James, 352pp)"
      "https://archive.org/details/anearnestminist00jamegoog/page/n6/mode/2up"
      "...")
    (course/render-assignment
      "Read and provide chapter summaries: Pastoral Theology (Thomas Murphy, 488pp)"
      "https://archive.org/details/pastoraltheology00murpuoft"
      "...")
    (course/render-assignment
      "Read and provide chapter summaries: The Christian Ministry, Vol. 1 (Charles Bridges, 343pp)"
      "https://archive.org/details/christianminist05bridgoog"
      "...")
    (course/render-assignment
      "Read and provide chapter summaries: The Christian Ministry, Vol. 2 (Charles Bridges, 335pp)"
      "https://archive.org/details/christianminist04bridgoog"
      "...")
    (course/render-assignment
      "Read and provide chapter summaries: Helps and Hints in Pastoral Theology (W.S. Plumer, 396pp)"
      "https://archive.org/details/hintshelpsinpas00plum"
      "...")
    (course/render-assignment
      "Read and provide chapter summaries: Words to the Winners of Souls (Horatius Bonar, 105pp)"
      "https://archive.org/details/pts_worldstothewinners_1687"
      "...")
    (course/render-assignment
      "Read and provide chapter summaries: Divorce and Remarriage: Recovering the Biblical View (William Luck, 287pp)"
      "https://bible.org/assets/worddocs/luck_divorceremarriage.zip"
      "...")
    (course/render-assignment
      "Read and provide chapter summaries: The Visitor's Book of Texts (Andrew Bonar, 280pp)"
      "https://drive.google.com/file/d/1MpYn-Bmgy9fXI0N4asLc7XOP7DWaTAOA/view"
      "...")
    (course/render-assignment
      "Write: 30-page paper outlining your personal ministry and pastoral philosophy and how you would apply it as a pastor"
      "https://example.com"
      "...")
  ))

(define completed
  (reverse
    (list )))

`([title . "PT600 - Pastoral Theology"]
  [tasks . [
    ,@(course/render completed todo)]])
