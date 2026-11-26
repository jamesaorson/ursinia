;; Copyright (C) 2026
;;
;; Generate the Greek Source Bible pages straight into wwwroot/ (nothing here is
;; committed):
;;
;;   wwwroot/bible/versions/gsb/text/index.html   the whole Bible on one page
;;   wwwroot/bible/versions/gsb/data/             the public dataset, which the
;;                                                page's script also fetches
;;
;; Greek comes from gsb/greek/, English from gsb/translation/ (format:
;; gsb/translation/README.md), glosses from gsb/lexicon/. The page itself is
;; plain text per verse; assets/bible/gsb/gsb.js adds per-word markup on demand.
;; Output is deterministic and unchanged files are left alone. Invoked through
;; ./scripts/gsb-site.sh (make gsb/site).

(use-modules (scripts lib gsb)
             (scripts lib gsb-translation)
             (scripts lib md)
             (scripts lib bible)
             (ice-9 format)
             (ice-9 match)
             (ice-9 textual-ports)
             (srfi srfi-1)
             (srfi srfi-13))

(fluid-set! %default-port-encoding "UTF-8")

(define %out "wwwroot/bible/versions/gsb")

(define (usage port)
  (format port "Usage: ./scripts/gsb-site.sh [-h|--help]~%~%")
  (format port "Generate the Greek Source Bible page and dataset into ~a/:~%" %out)
  (format port "  text/index.html  Greek and English side by side, every verse anchored~%")
  (format port "  data/            Greek tables, lexicon, concordance and translation JSON~%~%")
  (format port "Reads gsb/greek/ (run `make gsb` if missing), gsb/translation/ and~%")
  (format port "gsb/lexicon/. Run `make gsb/lint` first if a translation file fails to load.~%")
  (format port "Normally run as `make gsb/site` (part of `make render`).~%"))

;;; ---------------------------------------------------------------------------
;;; Small helpers
;;; ---------------------------------------------------------------------------

(define (esc s)
  (if (string-index s (char-set #\& #\< #\> #\"))
      (string-concatenate
       (map (lambda (c)
              (case c
                ((#\&) "&amp;") ((#\<) "&lt;") ((#\>) "&gt;") ((#\") "&quot;")
                (else (string c))))
            (string->list s)))
      s))

(define (md s)
  (call-with-output-string
    (lambda (port)
      (md->html (open-input-string s) port #f
                #:add-heading-anchors? #f #:scripture-links? #f #:confession-links? #f))))

(define (json x)
  "JSON text for X: strings, numbers, #t/#f/'null, vectors (arrays) and alists
with string keys (objects)."
  (cond
   ((string? x)
    (string-append
     "\""
     (string-concatenate
      (map (lambda (c)
             (cond ((char=? c #\") "\\\"")
                   ((char=? c #\\) "\\\\")
                   ((char<? c #\space) (format #f "\\u~4,'0x" (char->integer c)))
                   (else (string c))))
           (string->list x)))
     "\""))
   ((number? x) (number->string x))
   ((symbol? x) (if (eq? x 'null) "null" (json (symbol->string x))))
   ((eq? x #t) "true")
   ((eq? x #f) "false")
   ((vector? x) (string-append "[" (string-join (map json (vector->list x)) ",") "]"))
   ((null? x) "{}")
   (else (string-append "{" (string-join (map (lambda (p) (string-append (json (car p)) ":" (json (cdr p)))) x) ",") "}"))))

(define (emit path text)
  (let ((r (write-if-changed path text #f)))
    (when (eq? r 'wrote) (format #t "GSB: ~a~%" path))))

(define (copy-if-changed from to)
  (emit to (call-with-input-file from get-string-all)))

;;; ---------------------------------------------------------------------------
;;; Anchors: the same #<book>-<chapter>-<verse> ids as the KJV and BSB pages
;;; wherever the book is the same book; the GSB id otherwise.
;;; ---------------------------------------------------------------------------

(define %shared-books
  '(("gen" . "Genesis") ("exod" . "Exodus") ("lev" . "Leviticus") ("num" . "Numbers")
    ("deut" . "Deuteronomy") ("josh" . "Joshua") ("judg" . "Judges") ("ruth" . "Ruth")
    ("1kgdms" . "1 Samuel") ("2kgdms" . "2 Samuel") ("3kgdms" . "1 Kings") ("4kgdms" . "2 Kings")
    ("1chr" . "1 Chronicles") ("2chr" . "2 Chronicles") ("esth" . "Esther") ("job" . "Job")
    ;; ponytail: Psalms and Jeremiah keep the shared slug although Swete's
    ;; numbering differs (LXX Ps 9 = Heb 9-10; Jeremiah's order); revisit with
    ;; the versification decision (ursinia-vff.8).
    ("ps" . "Psalm") ("prov" . "Proverbs") ("eccl" . "Ecclesiastes") ("song" . "Song of Solomon")
    ("isa" . "Isaiah") ("jer" . "Jeremiah") ("lam" . "Lamentations") ("ezek" . "Ezekiel")
    ("dan" . "Daniel") ("hos" . "Hosea") ("joel" . "Joel") ("amos" . "Amos") ("obad" . "Obadiah")
    ("jonah" . "Jonah") ("mic" . "Micah") ("nah" . "Nahum") ("hab" . "Habakkuk")
    ("zeph" . "Zephaniah") ("hag" . "Haggai") ("zech" . "Zechariah") ("mal" . "Malachi")
    ("matt" . "Matthew") ("mark" . "Mark") ("luke" . "Luke") ("john" . "John") ("acts" . "Acts")
    ("rom" . "Romans") ("1cor" . "1 Corinthians") ("2cor" . "2 Corinthians") ("gal" . "Galatians")
    ("eph" . "Ephesians") ("phil" . "Philippians") ("col" . "Colossians")
    ("1thess" . "1 Thessalonians") ("2thess" . "2 Thessalonians") ("1tim" . "1 Timothy")
    ("2tim" . "2 Timothy") ("titus" . "Titus") ("phlm" . "Philemon") ("heb" . "Hebrews")
    ("jas" . "James") ("1pet" . "1 Peter") ("2pet" . "2 Peter") ("1john" . "1 John")
    ("2john" . "2 John") ("3john" . "3 John") ("jude" . "Jude") ("rev" . "Revelation")))

(define (book-anchor id)
  (let ((name (assoc-ref %shared-books id)))
    (if name (book-slug (book-by-display-name name)) id)))

;;; ---------------------------------------------------------------------------
;;; Loading
;;; ---------------------------------------------------------------------------

;; A loaded book: the books.tsv row plus its Greek verses (#f when there is no
;; table), translated verses (hash ref -> verse form), chapter notes (hash
;; chapter -> list of strings) and book notes.
(define (load-book book)
  (let* ((path (greek-table-path book))
         (verses (and (file-exists? path) (read-greek-table path)))
         (id (book-field book 'id))
         (translated (make-hash-table))
         (chapter-notes (make-hash-table))
         (dir (translation-dir book))
         (book-notes
          (if (file-exists? (string-append dir "/book.scm"))
              (filter-map (match-lambda (('note s) s) (_ #f)) (read-forms (string-append dir "/book.scm")))
              '())))
    (for-each
     (lambda (name)
       (let ((chapter (chapter-file-number name)))
         (when chapter
           (for-each (lambda (form)
                       (match form
                         (('note s) (hash-set! chapter-notes chapter (append (hash-ref chapter-notes chapter '()) (list s))))
                         (('verse n . _) (hash-set! translated (format #f "~a.~a.~a" id chapter n) form))
                         (_ #f)))
                     (read-forms (string-append dir "/" name))))))
     (chapter-files book))
    `((book . ,book) (verses . ,verses) (translated . ,translated)
      (chapter-notes . ,chapter-notes) (book-notes . ,book-notes))))

(define (ref-chapter ref) (cadr (string-split ref #\.)))
(define (ref-verse ref) (caddr (string-split ref #\.)))

(define (chapters-of verses)
  "VERSES grouped by chapter: a list of (chapter . verses), chapters in order of
first appearance, verses in printed order. A verse printed out of order across
a chapter boundary joins its own chapter rather than starting a second one."
  (let ((groups (make-hash-table)) (order '()))
    (for-each (lambda (v)
                (let ((c (ref-chapter (car v))))
                  (unless (hash-ref groups c) (set! order (cons c order)))
                  (hash-set! groups c (cons v (hash-ref groups c '())))))
              verses)
    (map (lambda (c) (cons c (reverse (hash-ref groups c)))) (reverse order))))

;;; ---------------------------------------------------------------------------
;;; Verse HTML
;;; ---------------------------------------------------------------------------

(define (greek-html words)
  "The verse's Greek as plain text; runs of restored TR words are wrapped in
<span class=tr> so they stay marked without the script."
  (let* ((tokens (map (lambda (w)
                        (cons (member "tr" (word-flags* w))
                              (esc (string-append (word-pre* w) (word-text* w) (word-post* w)))))
                      words))
         (runs (fold-right (lambda (t acc)
                             (if (and (pair? acc) (eq? (not (car t)) (not (caar acc))))
                                 (cons (cons (car t) (cons (cdr t) (cdar acc))) (cdr acc))
                                 (cons (list (car t) (cdr t)) acc)))
                           '() tokens)))
    (string-join (map (lambda (run)
                        (let ((text (string-join (cdr run) " ")))
                          (if (car run) (string-append "<span class=\"tr\">" text "</span>") text)))
                      runs)
                 " ")))

(define (verse-notes form) (if form (verse-fields form 'note) '()))

(define (english-html form anchor)
  (let* ((literal (verse-field form 'literal))
         (readable (verse-field form 'readable))
         (notes (verse-notes form)))
    (string-append
     "<div class=\"e\"><p class=\"l\">"
     (esc (string-join (map (lambda (c) (segments-text (cdr c))) (literal-clauses literal)) " "))
     "</p><p class=\"r\">"
     (esc (if (string? (car readable)) (car readable) (segments-text readable)))
     "</p>"
     (if (null? notes) "" (format #f "<a class=\"nl\" href=\"#~a-n\">note</a>" anchor))
     "</div>")))

(define (verse-html book-id slug v translated)
  (let* ((ref (car v))
         (key (string-append (ref-chapter ref) "-" (ref-verse ref)))
         (anchor (string-append slug "-" key))
         (form (hash-ref translated ref))
         (status (and form (car (verse-field form 'status))))
         (tr-verse? (every (lambda (w) (member "tr" (word-flags* w))) (cdr v))))
    (string-append
     "<div class=\"v" (if form (if (eq? status 'reviewed) " t" " t d") "") "\" id=\"" anchor "\">"
     "<a href=\"#" anchor "\">" (ref-verse ref) "</a>"
     "<p lang=\"grc\"" (if tr-verse? " class=\"trv\"" "") ">" (greek-html (cdr v)) "</p>"
     (if form (english-html form anchor) "")
     "</div>\n")))

;;; ---------------------------------------------------------------------------
;;; Notes
;;; ---------------------------------------------------------------------------

(define (chapter-notes-html loaded slug chapter chapter-verses)
  (let* ((translated (assq-ref loaded 'translated))
         (chapter-notes (hash-ref (assq-ref loaded 'chapter-notes) (string->number chapter) '()))
         (verse-notes (filter-map (lambda (v)
                                    (let ((notes (verse-notes (hash-ref translated (car v)))))
                                      (and (pair? notes) (cons v notes))))
                                  chapter-verses)))
    (if (and (null? chapter-notes) (null? verse-notes))
        ""
        (string-append
         "<details class=\"notes\" id=\"" slug "-" chapter "-notes\"><summary>Translation notes</summary>"
         (string-concatenate (map md chapter-notes))
         (if (null? verse-notes)
             ""
             (string-append
              "<dl>"
              (string-concatenate
               (map (match-lambda
                      ((v . notes)
                       (let ((anchor (string-append slug "-" chapter "-" (ref-verse (car v)))))
                         (string-append
                          "<dt id=\"" anchor "-n\"><a href=\"#" anchor "\">" chapter ":" (ref-verse (car v)) "</a></dt>"
                          (string-concatenate
                           (map (match-lambda
                                  ((text) (string-append "<dd>" (md text) "</dd>"))
                                  ((n text)
                                   (let ((w (find (lambda (w) (= (word-n w) n)) (cdr v))))
                                     (string-append "<dd><span lang=\"grc\">" (esc (word-text* w)) "</span> (word " (number->string n) ") "
                                                    (md text) "</dd>"))))
                                notes))))))
                    verse-notes))
              "</dl>"))
         "</details>"))))

;;; ---------------------------------------------------------------------------
;;; Books
;;; ---------------------------------------------------------------------------

(define (book-labels book verses)
  (let ((role (book-field book 'role))
        (notes (book-field book 'notes)))
    (string-append
     (if (string=? (book-field book 'deuterocanonical) "yes")
         "<p class=\"label\">Deuterocanonical: outside the 39-book Protestant Old Testament; translated last.</p>" "")
     (cond ((string=? role "comparison") "<p class=\"label\">For comparison only: this is not the main text.</p>")
           (else ""))
     (if (string-null? notes) "" (string-append "<p class=\"label\">" (esc notes) "</p>"))
     (cond
      ((not verses) "<p class=\"label missing\">Greek not yet transcribed.</p>")
      ;; ponytail: every Swete book counts as partial until a book's chapter
      ;; total is recorded somewhere (add a column to books.tsv when the first
      ;; book is fully transcribed).
      ((string=? (book-field book 'testament) "OT")
       (let ((chapters (map car (chapters-of verses))))
         (format #f "<p class=\"label missing\">Greek partially transcribed: chapter~a ~a so far.</p>"
                 (if (= 1 (length chapters)) "" "s")
                 (string-join chapters ", "))))
      (else "")))))

(define (book-html loaded)
  (let* ((book (assq-ref loaded 'book))
         (id (book-field book 'id))
         (slug (book-anchor id))
         (verses (assq-ref loaded 'verses))
         (translated (assq-ref loaded 'translated))
         (chapters (if verses (chapters-of verses) '()))
         (book-notes (assq-ref loaded 'book-notes)))
    (string-append
     "<section class=\"book\" id=\"" slug "\" data-id=\"" id "\" data-f=\"" (book-file-stem book) "\""
     (if (zero? (hash-count (const #t) translated)) "" " data-t")
     "><h2>" (esc (book-field book 'english)) " <span lang=\"grc\">" (esc (book-field book 'greek)) "</span></h2>"
     (book-labels book verses)
     (if (null? book-notes) ""
         (string-append "<details class=\"notes\" id=\"" slug "-notes\"><summary>Book translation notes</summary>"
                        (string-concatenate (map md book-notes)) "</details>"))
     (if (null? chapters) ""
         (string-append "<p class=\"chs\">"
                        (string-join (map (lambda (c) (format #f "<a href=\"#~a-~a\">~a</a>" slug (car c) (car c))) chapters) " ")
                        "</p>"))
     (string-concatenate
      (map (match-lambda
             ((chapter . chapter-verses)
              (string-append
               ;; ~6em per verse is a rough height until the browser has laid
               ;; the chapter out once (content-visibility then remembers it).
               "<section class=\"ch\" id=\"" slug "-" chapter "\" style=\"contain-intrinsic-size:auto "
               (number->string (* 6 (length chapter-verses))) "em\">"
               "<h3><a href=\"#" slug "-" chapter "\">" (esc (book-field book 'english)) " " chapter "</a></h3>"
               (chapter-notes-html loaded slug chapter chapter-verses)
               (string-concatenate (map (lambda (v) (verse-html id slug v translated)) chapter-verses))
               "</section>")))
           chapters))
     "</section>\n")))

;;; ---------------------------------------------------------------------------
;;; Page
;;; ---------------------------------------------------------------------------

(define (progress-html loaded-books)
  (let* ((rows (filter-map (lambda (l)
                             (let ((verses (assq-ref l 'verses)))
                               (and verses
                                    (list (assq-ref l 'book) (length verses)
                                          (count (lambda (v) (hash-ref (assq-ref l 'translated) (car v))) verses)))))
                           loaded-books))
         (total (apply + (map second rows)))
         (done (apply + (map third rows)))
         (num (lambda (n) (let ((s (number->string n)))
                            (if (< n 1000) s (format #f "~a,~a" (substring s 0 (- (string-length s) 3))
                                                     (substring s (- (string-length s) 3))))))))
    (string-append
     "<details id=\"progress\"><summary>Progress: " (num done) " of " (num total)
     " verses translated (of the verses whose Greek is transcribed)</summary>"
     "<div class=\"table-scroll\"><table><thead><tr><th>Book</th><th>Translated</th><th>Verses</th></tr></thead><tbody>"
     (string-concatenate
      (map (match-lambda
             ((book total done)
              (format #f "<tr><td><a href=\"#~a\">~a</a></td><td>~a</td><td>~a</td></tr>"
                      (book-anchor (book-field book 'id)) (esc (book-field book 'english)) (num done) (num total))))
           rows))
     "</tbody></table></div>"
     "<p>Books not listed have no Greek transcribed yet.</p></details>\n")))

(define (concordance-html gloss-forms)
  (string-append
   "<details id=\"concordance\"><summary>Concordance decisions (" (number->string (length gloss-forms))
   " lemmas)</summary><p>One English gloss per Greek lemma per sense, enforced by a script. Each entry gives the gloss and the reasoning.</p><dl>"
   (string-concatenate
    (map (match-lambda
           (('lemma lemma senses ...)
            (string-append
             "<dt lang=\"grc\" id=\"lemma-" (esc lemma) "\">" (esc lemma) "</dt>"
             (string-concatenate
              (map (lambda (s)
                     (let ((glosses (cdr (assq 'gloss (cddr s))))
                           (readable (assq 'readable (cddr s)))
                           (why (cadr (assq 'why (cddr s)))))
                       (string-append "<dd><b>" (if (string-null? (car glosses)) "(not rendered)" (esc (car glosses)))
                                      "</b> <small>(" (symbol->string (cadr s)) ")</small> "
                                      (if readable (string-append "Readable layer: <b>" (esc (cadr readable)) "</b>. ") "")
                                      (esc why) "</dd>")))
                   senses)))))
         gloss-forms))
   "</dl></details>\n"))

(define (nav-html loaded-books)
  (define (links testament)
    (string-join
     (filter-map (lambda (l)
                   (let ((b (assq-ref l 'book)))
                     (and (string=? (book-field b 'testament) testament)
                          (format #f "<a href=\"#~a\"~a>~a</a>" (book-anchor (book-field b 'id))
                                  (if (assq-ref l 'verses) "" " class=\"missing\"")
                                  (esc (book-field b 'english))))))
                 loaded-books)
     " · "))
  (string-append
   "<nav id=\"books\" aria-label=\"Books\"><p><b>Old Testament (Septuagint order):</b> " (links "OT")
   "</p><p><b>New Testament:</b> " (links "NT") "</p></nav>\n"))

(define %intro "
<section id=\"why\">
<h2>Why do this?</h2>
<p>The apostles wrote in Greek, and when they quoted the Old Testament they most often quoted it in Greek, from the Septuagint. Most English Bibles translate the Old Testament from Hebrew and the New from Greek, so a quotation and its source often read differently in English even where the apostle's Greek is word for word the same.</p>
<p>The Greek Source Bible translates the whole Bible from Greek: the Old Testament from the Septuagint and the New Testament from the Greek New Testament, under one consistent vocabulary. Where the New Testament's Greek matches the Septuagint, our English matches. Where an apostle's wording differs, our English shows that too.</p>
<p>Modern English translations of the Septuagint are copyrighted. The public-domain ones are generations old and cover less. No public-domain Greek Septuagint text exists with its words tagged for study. We hold that <a href=\"https://copy.church/\">Scripture and the tools around it should not be gated</a>, so everything here is dedicated to the public domain: the translation, our transcription of the Greek, and all the data behind it. No permission or attribution is needed.</p>
<p>Every translation decision is shown. Each English word can be traced to its Greek word, and the reasons for our choices are recorded beside the text.</p>
<div class=\"table-scroll\"><table>
<thead><tr><th></th><th>Brenton (1844)</th><th>NETS (2007)</th><th>Greek Source Bible</th></tr></thead>
<tbody>
<tr><th>Scope</th><td>Old Testament only</td><td>Old Testament only</td><td>Old and New Testaments in one translation</td></tr>
<tr><th>Greek base</th><td>Vaticanus, via an older printed edition</td><td>Göttingen critical editions, Rahlfs elsewhere</td><td>Swete (Vaticanus-based), our own transcription</td></tr>
<tr><th>English</th><td>KJV-style</td><td>Revises the NRSV</td><td>Fresh: a hyper-literal layer plus a readable layer</td></tr>
<tr><th>Names</th><td>Traditional</td><td>Transliterated Greek</td><td>Traditional</td></tr>
<tr><th>Daniel</th><td>Theodotion only</td><td>Old Greek and Theodotion in parallel</td><td>Old Greek as the text, Theodotion for comparison</td></tr>
<tr><th>License</th><td>Public domain</td><td>Copyrighted</td><td>CC0, including all data</td></tr>
<tr><th>Apparatus</th><td>Sparse footnotes</td><td>Introductions per book</td><td>Word-level alignment, lemma and Strong's number, logged decisions</td></tr>
</tbody></table></div>
<h3>Limits, stated up front</h3>
<ul>
<li>Swete's text essentially follows one manuscript, Codex Vaticanus (Alexandrinus where Vaticanus is lacking, as at the start of Genesis), and is less critical than the copyrighted Göttingen editions.</li>
<li>The New Testament base is Nestle 1904, with the longer readings of the Textus Receptus restored and marked.</li>
<li>The translation is drafted with AI assistance and reviewed by the owner. Verses not yet reviewed are marked <i>draft</i>.</li>
<li>Translation is under way: untranslated verses show the Greek alone, and Old Testament books appear as their Greek is transcribed.</li>
</ul>
</section>
<section id=\"sources\">
<h2>Sources</h2>
<ul>
<li><b>Old Testament:</b> H. B. Swete, <i>The Old Testament in Greek according to the Septuagint</i> (Cambridge, 1887-1894; editions of 1907-1912), transcribed by us from public-domain page scans. Our transcription is dedicated to the public domain (CC0).</li>
<li><b>New Testament:</b> Eberhard Nestle's 1904 Greek New Testament (public domain), with the biblicalhumanities.org morphology (CC0).</li>
<li><b>Restored readings:</b> Scrivener's 1894 Textus Receptus (public domain); accents for restored words from the Robinson-Pierpont Byzantine text (public domain).</li>
<li><b>Glosses:</b> the Dodson Greek Lexicon (public domain) and Strong's Greek dictionary (public domain; XML edition CC0).</li>
</ul>
<p>All sources are public domain or CC0. The tagged Greek tables, lexicon and concordance are published as <a href=\"/bible/versions/gsb/data/\">an open dataset</a>.</p>
<p><b>Dedication.</b> To the extent possible under law, the authors have dedicated all copyright and related rights in the Greek Source Bible (the translation, the transcription, the notes and all of its data) to the public domain worldwide under <a href=\"https://creativecommons.org/publicdomain/zero/1.0/\">CC0 1.0</a>. No permission or attribution is needed.</p>
</section>
")

(define (options-html loaded-books)
  "The sticky bar: book and chapter pickers and the display switches. Hidden
until gsb.js runs; without JS the book links above do the navigating."
  (define (books testament)
    (string-concatenate
     (filter-map (lambda (l)
                   (let ((b (assq-ref l 'book)))
                     (and (string=? (book-field b 'testament) testament)
                          (format #f "<option value=\"~a\"~a>~a</option>" (book-anchor (book-field b 'id))
                                  (if (assq-ref l 'verses) "" " disabled")
                                  (esc (book-field b 'english))))))
                 loaded-books)))
  (string-append "
<form id=\"options\" hidden>
<label>Book <select name=\"book\"><option value=\"\">Go to…</option>
<optgroup label=\"Old Testament\">" (books "OT") "</optgroup>
<optgroup label=\"New Testament\">" (books "NT") "</optgroup></select></label>
<label>Chapter <select name=\"chapter\" disabled><option value=\"\">–</option></select></label>
<label>English <select name=\"layer\">
<option value=\"both\">Both layers</option>
<option value=\"literal\">Literal</option>
<option value=\"readable\">Readable</option></select></label>
<label>Colors <select name=\"color\">
<option value=\"none\">None</option>
<option value=\"align\">Alignment</option>
<option value=\"clause\">Clauses</option>
<option value=\"pos\">Part of speech</option>
<option value=\"tr\">Restored TR readings</option></select></label>
</form>
"))

(define %legend "
<details id=\"legend\"><summary>How to read this page</summary>
<ul>
<li>Greek on the left, English on the right (stacked on narrow screens). The first English line is the <b>literal</b> layer: Greek word order where English grammar allows, one gloss per Greek word and sense, every supplied word in [brackets]. The second is the <b>readable</b> layer.</li>
<li>Point at, tap or tab to a verse to look up its words: each Greek word then shows its lemma, Strong's number, parsing and gloss.</li>
<li><span class=\"tr\">Dotted underline</span>: a longer Textus Receptus reading restored into the Nestle 1904 base (for example 1 John 5:7). The <i>Restored TR readings</i> color mode highlights them more strongly.</li>
<li><i>Alignment</i> gives each Greek word or word group the same color as its English; pointing at one outlines the other. <i>Clauses</i> colors by clause. <i>Part of speech</i> colors the Greek by its parsing (New Testament only): <span class=\"pv\">verb</span>, <span class=\"pn\">noun</span>, <span class=\"pa\">adjective</span>, <span class=\"pt\">article</span>, <span class=\"pp\">pronoun</span>, <span class=\"pr\">preposition</span>, <span class=\"pc\">conjunction</span>, <span class=\"pd\">adverb</span>, <span class=\"px\">particle</span>.</li>
<li>A dashed rule and the word <i>draft</i> mark English not yet reviewed; a solid rule marks reviewed English. Verses without English are marked <i>not yet translated</i>.</li>
</ul>
</details>
")

(define (asset-version path)
  (number->string (string-hash (call-with-input-file path get-string-all) 4294967296) 16))

(define (page-html loaded-books gloss-forms)
  (string-append
   "<!DOCTYPE html>\n<html lang=\"en\"><head><meta charset=\"UTF-8\">"
   "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">"
   "<link rel=\"icon\" type=\"image/x-icon\" href=\"/shared/favicons/favicon.ico\">"
   "<link rel=\"stylesheet\" href=\"/shared/styles/openword-theme.css\">"
   ;; ?v= changes whenever the file does, so browsers never show a stale copy.
   "<link rel=\"stylesheet\" href=\"/assets/bible/gsb/gsb.css?v=" (asset-version "assets/bible/gsb/gsb.css") "\">"
   "<script src=\"/assets/bible/gsb/gsb.js?v=" (asset-version "assets/bible/gsb/gsb.js") "\" defer></script>"
   "<title>Greek Source Bible</title></head><body>\n"
   "<header><div id=\"header\"><span id=\"header-back\"><a id=\"header-back-link\" href=\"/bible/versions/gsb/\">&#8612; <code>gsb</code></a></span></div></header>\n"
   (options-html loaded-books)
   "<h1>Greek Source Bible</h1>\n"
   "<p>The whole Bible translated from Greek: the Old Testament from the Septuagint, the New Testament from the Greek New Testament. Greek and English side by side; every verse can be linked (<code>#john-3-16</code>), with the same anchors as the other versions on this site.</p>\n"
   (nav-html loaded-books)
   (progress-html loaded-books)
   %intro
   %legend
   (concordance-html gloss-forms)
   ;; ponytail: one page for the whole Bible. Fine at the New Testament plus
   ;; the pilot books; at ~750,000 Greek words (~15 MB of HTML) split it into
   ;; one page per book if it gets too heavy to load.
   "<main id=\"text\">\n"
   (string-concatenate (map book-html loaded-books))
   "</main></body></html>\n"))

;;; ---------------------------------------------------------------------------
;;; Data
;;; ---------------------------------------------------------------------------

(define (translation-json loaded glosses)
  "JSON of a book's translated verses, keyed by chapter.verse:
{\"1.1\": {\"s\": status, \"l\": [[clause, text, [n...], [sense...], [cont n...]]...],
\"r\": [[text, [n...]]...] (aligned readable only)}}. Clause -1 = none. A
bare ref's sense is the lemma's default (first listed); [cont n...], present
only when non-empty, lists the words of [n...] whose own segment is an
earlier one (the English continues it)."
  (let* ((verses (assq-ref loaded 'verses))
         (translated (assq-ref loaded 'translated)))
    (json
     (filter-map
      (lambda (v)
        (let ((form (hash-ref translated (car v))))
          (and form
               (let* ((senses (map (match-lambda ((n lemma sense . _) (cons n sense)))
                                   (verse-uses form (cdr v) glosses)))
                      (sense-of (lambda (r) (or (assv-ref senses (ref-n r)) 'null)))
                      (readable (verse-field form 'readable)))
                 (cons (string-append (ref-chapter (car v)) "." (ref-verse (car v)))
                       `(("s" . ,(car (verse-field form 'status)))
                         ("l" . ,(list->vector
                                  (append-map (match-lambda
                                                ((clause . segs)
                                                 (map (lambda (s)
                                                        (let* ((refs (segment-refs s))
                                                               (conts (map ref-n (filter cont-ref? refs))))
                                                          (list->vector
                                                           (append
                                                            (list (or clause -1) (segment-text s)
                                                                  (list->vector (map ref-n refs))
                                                                  (list->vector (map sense-of refs)))
                                                            (if (null? conts) '() (list (list->vector conts)))))))
                                                      segs)))
                                              (literal-clauses (verse-field form 'literal)))))
                         ,@(if (string? (car readable))
                               '()
                               `(("r" . ,(list->vector
                                          (map (lambda (s) (vector (segment-text s) (list->vector (map ref-n (segment-refs s)))))
                                               readable)))))))))))
      verses))))

(define (glosses-json gloss-forms)
  (json (map (match-lambda
               (('lemma lemma senses ...)
                (cons lemma
                      (list->vector
                       (map (lambda (s)
                              (vector (symbol->string (cadr s))
                                      (list->vector (cdr (assq 'gloss (cddr s))))
                                      (cadr (assq 'why (cddr s)))))
                            senses)))))
             gloss-forms)))

(define (data-index-html files)
  (string-append
   "<!DOCTYPE html>\n<html lang=\"en\"><head><meta charset=\"UTF-8\">"
   "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">"
   "<link rel=\"stylesheet\" href=\"/shared/styles/openword-theme.css\">"
   "<title>Greek Source Bible - Data</title></head><body>"
   "<header><div id=\"header\"><span id=\"header-back\"><a id=\"header-back-link\" href=\"/bible/versions/gsb/\">&#8612; <code>gsb</code></a></span></div></header>"
   "<h1>Greek Source Bible: data</h1>"
   "<p>Dedicated to the public domain (CC0 1.0); no attribution needed. Formats: <a href=\"README.md\">README.md</a> (Greek tables) and "
   "<a href=\"translation/README.md\">translation/README.md</a> (translation files and concordance).</p><ul>"
   (string-concatenate (map (lambda (f) (format #f "<li><a href=\"~a\">~a</a></li>" f f)) files))
   "</ul></body></html>\n"))

;;; ---------------------------------------------------------------------------
;;; Main
;;; ---------------------------------------------------------------------------

(define (main args)
  (when (or (member "-h" args) (member "--help" args))
    (usage (current-output-port))
    (exit 0))
  (unless (null? (cdr args))
    (usage (current-error-port))
    (exit 2))
  (unless (file-exists? "gsb/greek")
    (format (current-error-port) "gsb-site: Greek tables missing (gsb/greek/); run `make gsb`~%")
    (exit 1))
  (let* ((gloss-forms (read-forms "gsb/lexicon/glosses.scm"))
         (gloss-errors (check-glosses gloss-forms)))
    (unless (null? gloss-errors)
      (for-each (lambda (e) (format (current-error-port) "gsb/lexicon/glosses.scm: ~a~%" e)) gloss-errors)
      (format (current-error-port) "gsb-site: fix the concordance (see `make gsb/lint`)~%")
      (exit 1))
    (let* ((glosses (parse-glosses gloss-forms))
           (loaded-books (map load-book (read-books)))
           (data (string-append %out "/data/"))
           (tables (filter (lambda (l) (assq-ref l 'verses)) loaded-books))
           (translated (filter (lambda (l) (positive? (hash-count (const #t) (assq-ref l 'translated)))) tables))
           (files (append
                   (map (lambda (l) (string-append (book-file-stem (assq-ref l 'book)) ".tsv")) tables)
                   '("books.tsv" "strongs.tsv" "glosses.scm" "glosses.json")
                   (map (lambda (l) (string-append "translation/" (book-file-stem (assq-ref l 'book)) ".json")) translated))))
      (emit (string-append %out "/text/index.html") (page-html loaded-books gloss-forms))
      (for-each (lambda (l)
                  (let ((stem (book-file-stem (assq-ref l 'book))))
                    (copy-if-changed (greek-table-path (assq-ref l 'book)) (string-append data stem ".tsv"))))
                tables)
      (for-each (lambda (l)
                  (emit (string-append data "translation/" (book-file-stem (assq-ref l 'book)) ".json")
                        (translation-json l glosses)))
                translated)
      (copy-if-changed "gsb/books.tsv" (string-append data "books.tsv"))
      (copy-if-changed "gsb/README.md" (string-append data "README.md"))
      (copy-if-changed "gsb/translation/README.md" (string-append data "translation/README.md"))
      (copy-if-changed "gsb/lexicon/strongs.tsv" (string-append data "strongs.tsv"))
      (copy-if-changed "gsb/lexicon/glosses.scm" (string-append data "glosses.scm"))
      (emit (string-append data "glosses.json") (glosses-json gloss-forms))
      (emit (string-append data "index.html") (data-index-html files)))))

(main (command-line))
