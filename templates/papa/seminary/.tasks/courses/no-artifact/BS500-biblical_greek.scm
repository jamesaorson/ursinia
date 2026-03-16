(use-modules (scripts lib course))

(define todo
  (list
    (course/render-assignment
      "Read: Tips for Better Note-Taking for Greek and Hebrew Courses"
      "https://drive.google.com/file/d/1AAdDtDhEXYwx5C2RbeuOtO7smbEwPOrJ/view"
      #f)
    (course/render-assignment
      "Memorize: 311 Most Frequently Used Words in the Greek New Testament"
      "https://drive.google.com/file/d/1o_zxrXrBhlCPvBkI15XwGgK_sXyYnqXk/view"
      #f)
  ))

(define completed
  (reverse
    (list
)))

`([title . "BS500 - Biblical Greek"]
  [tasks . [
    ,@(course/render completed todo)]])