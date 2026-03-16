(use-modules (scripts lib course))

(define todo
  (list
    (course/render-assignment
      "Read: Job, Psalms, Proverbs, Ecclesiastes, and Song of Solomon"
      "https://example.com"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: Psalms and Wisdom Books 1-33 (Dr. Philip Long, 21h)"
      "https://resources.covenantseminary.edu/programs/psalms-wisdom-books"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: Poets 1-24 (Dr. Richard Belcher, 19h)"
      "https://subsplash.com/+3c13/media/li/+6ecf1cd"
      #f)
    (course/render-assignment
      "Listen, outline, and take notes: Ecclesiastes 1-4 (Dr. R.C. Sproul, 1.5h)"
      "https://learn.ligonier.org/series/ecclesiastes"
      #f)
    (course/render-assignment
      "Read and provide chapter summaries: The Beauty of the Bible: A Study of its Poets and Poetry (James Stalker, 196pp)"
      "https://archive.org/details/beautyofbiblestu00stal"
      #f)
    (course/render-assignment
      "Read and provide chapter summaries: The Psalms: Their History, Teachings, and Use (William Binnie, 424pp)"
      "https://archive.org/details/psalmstheirhisto00binn"
      #f)
    (course/render-assignment
      "Helpful resource: Psalms Classification Chart"
      "https://drive.google.com/file/d/1LZwyfjowBImAmdVdY8jrb6iAeZmYsRUK/view"
      #f)
    (course/render-assignment
      "Write: 30-page paper on a subject of interest presented in the course material"
      "https://example.com"
      #f)
  ))

(define completed
  (reverse
    (list )))

`([title . "BS534 - Old Testament Wisdom Books"]
  [tasks . [
    ,@(course/render completed todo)]])
