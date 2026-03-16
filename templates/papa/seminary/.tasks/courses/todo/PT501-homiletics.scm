(use-modules (scripts lib course))

(define todo
  (list
    (course/render-assignment
      "Listen, outline, and take notes: Preaching and Preachers 1-18 (Dr. David Martyn Lloyd-Jones, 16h)"
      "https://www.mljtrust.org/sermons/preaching-and-preachers/"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: Biblical Preaching 1-20 (Dr. John Stott, 16h)"
      "https://drive.google.com/drive/folders/1-zFem1ZBlQtWz_un6Tl-vhMJM7Je0gPN"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: What is Preaching? (Dr. David Murray, 49m)"
      "https://www.sermonaudio.com/sermons/8813171279"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: Centrality of Preaching (Maurice Roberts, 34m)"
      "http://www.bible-sermons.org.uk/audio/1952.mp3" ; NOTE: 404
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: Central Task of Preaching 1-3 (Dr. Sinclair Ferguson, 2.5h)"
      "https://itunes.apple.com/us/itunes-u/the-central-task-of-preaching/id378879734?mt=10" ; NOTE: 404
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: Preachers and Preaching 1-4 (Dr. R.C. Sproul, 1.5h)"
      "https://learn.ligonier.org/series/preachers-and-preaching"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: The Man and His Message (John Blanchard, 1h)"
      "https://www.sermonaudio.com/sermons/10200915286"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: Biblical Standards for Evangelism (John Blanchard, 1h)"
      "https://www.sermonaudio.com/sermons/102009019310"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: Effective Evangelistic Preaching (John Blanchard, 1h)"
      "https://www.sermonaudio.com/sermons/10200919258"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: How to Prepare a Sermon (Jay Adams, 1h)"
      "http://media2.wts.edu/media/audio/pc883-copyright.mp3"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: Preaching for Change (Jay Adams, 39m)"
      "https://media2.wts.edu/media/audio/pc881a-copyright.mp3"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: Preaching for Change Q&A (Jay Adams, 40m)"
      "http://media2.wts.edu/media/audio/pc881b-copyright.mp3"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: Passion in Preaching (Maurice Roberts, 1h)"
      "https://www.sermonaudio.com/sermons/102408101354"
      #f)
    (course/render-assignment
      "Read and provide chapter summaries: Sacred Rhetoric (R.L. Dabney, 376pp)"
      "https://archive.org/details/sacredrhetoric00pabnuoft"
      #f)
    (course/render-assignment
      "Read and provide chapter summaries: Homiletics (W.G.T. Shedd, 397pp)"
      "https://archive.org/details/homileticsandpa02shedgoog"
      #f)
    (course/render-assignment
      "Read and provide chapter summaries: Thoughts on Preaching (James W. Alexander, 542pp)"
      "https://archive.org/details/thoughtsonprea00alex"
      #f)
    (course/render-assignment
      "Read and summarize: Simplicity in Preaching (J.C. Ryle, 48pp)"
      "https://archive.org/details/simplicityinpre00rylegoog"
      #f)
    (course/render-assignment
      "Listen to and outline 30 sermons, noting structure and distinctive characteristics, from suggested preachers: Harry Reeder, Randy Pope, Derek Thomas, R.C. Sproul, John Blanchard, Alan Cairns, Bryan Chapell, Iver Martin, John Piper, Steven Lawson, John Stott, Joel Beeke, A.N. Martin, David Martyn Lloyd-Jones, Eric Alexander, Jay Adams, Maurice Roberts, Sinclair Ferguson, Stuart Olyott, Tim Keller, Paul Washer, Alistair Begg, Carl Trueman, Louie Giglio, Ian Brown, Richard D. Phillips, Greg Laurie. Other pastors may be chosen as approved or directed by your mentor"
      "https://example.com"
      #f)
    (course/render-assignment
      "Write: 10-page paper outlining your personal approach to homiletical structure and content"
      "https://example.com"
      #f)
    (course/render-assignment
      "Write four 5-page manuscript sermons and submit to your mentor for review"
      "https://example.com"
      #f)
  ))

(define completed
  (reverse
    (list )))

`([title . "PT501 - Homiletics"]
  [tasks . [
    ,@(course/render completed todo)]])
