(use-modules (scripts lib course))

(define todo
  (list
    (course/render-assignment
      "Listen, outline, and take notes: Contemporary Theology I (Dr. John Feinberg, 17h)"
      "https://learn.artosacademy.org/courses/contemporary-theology-i-hegel-to-death-of-god-theologies/" ; NOTE: 404
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: Contemporary Theology II (Dr. John Feinberg, 17h)"
      "https://learn.artosacademy.org/courses/contemporary-theology-ii-from-theology-of-hope-to-post-modernism/" ; NOTE: 404
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: Church and the World 1-28 (Dr. James Anderson, 21h)"
      "https://www.subsplash.com/reformtheosem/learn-about-rts/li/+e9646fe?" ; NOTE: 404
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: Contemporary Theology: Its Formative Development (Dr. Robert Letham, 52m)"
      "http://media1.wts.edu/media/audio/rl102_copyright.mp3"
      "...")
    (course/render-assignment
      "Listen, outline, and take notes: Neo-Orthodoxy (Dr. Curt Daniel, 57m)"
      "https://www.sermonaudio.com/sermons/8300412599"
      "...")
    (course/render-assignment
      "Read: An Overview of Contemporary Theology (Dr. C. Matthew McMahon)"
      "https://www.apuritansmind.com/historical-theology/an-overview-of-contemporary-theology-by-dr-c-matthew-mcmahon/"
      "...")
    (course/render-assignment
      "Read and provide chapter summaries: Christianity and Liberalism (J. Gresham Machen, 168pp)"
      "https://drive.google.com/file/d/1dNuzw93YikG3MsQ3g0OpcMPJx5cDatiu/view"
      "...")
    (course/render-assignment
      "Read and provide chapter summaries: Christian Faith and Modern Theology (Carl Henry, ed., 416pp)"
      "https://drive.google.com/file/d/10HXlVoOPtmIVMiOtje_EXEhQ_XgYjyoS/view"
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
