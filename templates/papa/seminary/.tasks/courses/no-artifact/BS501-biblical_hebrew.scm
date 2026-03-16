(use-modules (scripts lib course))

(define todo
  (list
    (course/render-assignment
      "Read: Tips for Better Note-Taking for Greek and Hebrew Courses"
      "https://drive.google.com/file/d/1AAdDtDhEXYwx5C2RbeuOtO7smbEwPOrJ/view"
      #f)
    (course/render-assignment
      "Memorize: All 100 numbered vocabulary terms in the Hebrew Vocabulary List"
      "https://drive.google.com/file/d/1a7PJzCyOrZA9i54nd_g0PIbyjP5aWSR3/view"
      #f)
  ))

(define completed
  (reverse
    (list
)))

`([title . "BS501 - Biblical Hebrew"]
  [tasks . [
    ,@(course/render completed todo)]])