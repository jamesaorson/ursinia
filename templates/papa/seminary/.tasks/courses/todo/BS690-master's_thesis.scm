(use-modules (scripts lib course))

(define todo
  (list
    (course/render-assignment
      "Develop your thesis topic and thesis work closely with your mentor"
      "https://example.com"
      #f)
    (course/render-assignment
      "Submit Request for Approval of Thesis Topic Form to seminary administration before beginning thesis work"
      "https://logcollege.net/assignment-examples#1ca754b5-23b8-44ba-9d7d-8591503a2da0"
      #f)
    (course/render-assignment
      "Email completed thesis topic approval form to info@logcollege.net"
      "mailto:info@logcollege.net"
      #f)
    (course/render-assignment
      "Do not begin thesis work until seminary administration approves the topic"
      "https://example.com"
      #f)
    (course/render-assignment
      "Write: Master's thesis of at least 100 pages with 1 inch margins, 12-point Times New Roman font, double spacing, in current Turabian formatting"
      "https://example.com"
      #f)
    (course/render-assignment
      "Include submission page, table of contents, and full bibliography in thesis"
      "https://example.com"
      #f)
    (course/render-assignment
      "Ensure thesis is free of grammatical and syntax errors and reflects master's-level program work"
      "https://example.com"
      #f)
    (course/render-assignment
      "Have mentor submit thesis to LCS administration after grading for final review and approval before graduation"
      "https://example.com"
      #f)
    (course/render-assignment
      "Complete the Comprehensive Final Exam and contact the seminary to schedule exam time"
      "https://example.com"
      #f)
  ))

(define completed
  (reverse
    (list )))

`([title . "BS690 - Master's Thesis"]
  [tasks . [
    ,@(course/render completed todo)]])
