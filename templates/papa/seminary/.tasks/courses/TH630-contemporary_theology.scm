(use-modules (scripts lib course))

(define todo
  (list
    (course/render-assignment
      "Listen, outline, and take notes: Contemporary Theology I (Dr. John Feinberg, 17h)"
      "https://duckduckgo.com/?q=Contemporary+Theology+I+John+Feinberg"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: Contemporary Theology II (Dr. John Feinberg, 17h)"
      "https://duckduckgo.com/?q=Contemporary+Theology+II+John+Feinberg"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: Church and the World 1-28 (Dr. James Anderson, 21h)"
      "https://students.wts.edu/resources/media.html?paramType=search&keywords=Church%20and%20the%20World%20James%20Anderson"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: Contemporary Theology: Its Formative Development (Dr. Robert Letham, 52m)"
      "https://duckduckgo.com/?q=Contemporary+Theology+Its+Formative+Development+Robert+Letham"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: Neo-Orthodoxy (Dr. Curt Daniel, 57m)"
      "https://duckduckgo.com/?q=Neo-Orthodoxy+Curt+Daniel"
      "...")
    (course/render-assignment
      "Read: An Overview of Contemporary Theology (Dr. C. Matthew McMahon)"
      "https://www.apuritansmind.com/theological-studies/an-overview-of-contemporary-theology/"
      "...")
    (course/render-assignment
      "Read and provide chapter summaries: Christianity and Liberalism (J. Gresham Machen, 168pp)"
      "https://archive.org/details/christianitylibe00mach"
      "...")
    (course/render-assignment
      "Read and provide chapter summaries: Christian Faith and Modern Theology (Carl Henry, ed., 416pp)"
      "https://archive.org/details/christianfaithmo00henr"
      "...")
    (course/render-assignment
      "Write: 20-page paper focusing on a particular school of contemporary theology"
      "https://example.com"
      "...")
  ))

(define completed
  (reverse
    (list )))

`([title . "TH630 - Contemporary Theology"]
  [tasks . [
    ,@(course/render completed todo)]])
