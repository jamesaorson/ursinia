(use-modules (scripts lib course))

(define todo
  (list
    (course/render-assignment
      "Listen, outline, and take notes: The Free Offer of the Gospel (David Silversides, 1h)"
      "https://www.sermonaudio.com/sermons/22603142641"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: A Theology of Evangelism (Dr. Edmund Clowney, 1h)"
      "https://media1.wts.edu/media/audio/leec-copyright.mp3"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: Evangelism and Mission 1-20 (Dr. Michael Horton, 12h)"
      "https://www.christurc.org/adult-catechism/class-1-an-introduction-to-evangelism-and-mission"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: God's World Mission 1-17 (Dr. Nelson Jennings, 17h)"
      "https://itunes.apple.com/us/itunes-u/gods-world-mission-audio-lectures/id418583428?mt=10"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: Supremacy of God in World Evangelism 1-5 (John Piper, 4h)"
      "https://drive.google.com/file/d/1EUrWTR0lfwq4imiU11BjiMzWP_Jcvq6o/view"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: Personal Evangelism 1-5 (Dr. John Blanchard, 4h)"
      "https://www.sermonaudio.com/series/3311"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: Motives for Mission (Dr. John Blanchard, 38m)"
      "https://www.sermonaudio.com/sermons/122082158149"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: Eager to Preach (John Blanchard, 25m)"
      "https://www.sermonaudio.com/sermons/120081738314"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: The Spiritual Dynamics of Missions (Dr. J. Edwin Orr, 30m)"
      "https://www.sermonaudio.com/sermons/10270295939"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: Mobilizing the Church for Evangelism (John Blanchard, 1h)"
      "https://www.sermonaudio.com/sermons/102009044281"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: Why Won't They Listen? (Ken Ham, 1h)"
      "https://www.sermonaudio.com/sermons/11606143116"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: Harvest Imperatives 1 (Randy Pope, 1h)"
      "https://www.perimeter.org/podcasts/prexpress1.mp3" ; NOTE: 404
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: Harvest Imperatives 2 (Randy Pope, 1h)"
      "https://www.perimeter.org/podcasts/prexpress2.mp3" ; NOTE: 404
      "...")
    (course/render-assignment
      "Read and provide chapter summaries: Every-Member Evangelism (J.E. Conant, 232pp)"
      "https://archive.org/details/everymemberevang00cona"
      "...")
    (course/render-assignment
      "Read and provide chapter summaries: The Way of Life (Charles Hodge, 374pp)"
      "https://archive.org/details/wayoflife00hodg"
      "...")
    (course/render-assignment
      "Read and summarize: The Art of Man-Fishing (Thomas Boston, 120pp)"
      "https://archive.org/details/soliloquyonartof00bost"
      "...")
    (course/render-assignment
      "Read and summarize: The Universal Offer of the Gospel (Dogmatic Theology Vol. 2, pp. 482-489) (W.G.T. Shedd, 7pp)"
      "https://archive.org/details/dogmatictheology02sheduoft"
      "...")
    (course/render-assignment
      "Read and summarize: The World White to Harvest (Discussions of Robert L. Dabney Vol. 1, pp. 575-594) (R.L. Dabney, 19pp)"
      "https://archive.org/details/discussions01dabn/page/n9/mode/2up"
      "...")
    (course/render-assignment
      "Read and outline: Ultimate Questions (John Blanchard, 36pp)"
      "https://www.wordtoall.org/questions"
      "...")
    (course/render-assignment
      "Write: 30-page paper on the importance of developing a missional lifestyle and outline a method for personal evangelism"
      "https://example.com"
      "...")
    (course/render-assignment
      "Document a one-on-one evangelistic encounter including approach and method used, setting, summary of dialogue, and the person's response"
      "https://example.com"
      "...")
  ))

(define completed
  (reverse
    (list )))

`([title . "PT505 - Evangelism and Missions"]
  [tasks . [
    ,@(course/render completed todo)]])
