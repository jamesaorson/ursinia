;; Copyright (C) 2026
;;
;; Render the Greek Source Bible pages from the GSB database (built by
;; `make gsb/db`, scripts/gsb-db.scm; schema gsb/schema.sql) into wwwroot/.
;; Nothing under gsb/ is read here: everything published comes out of the
;; database, which is the proof that the database holds all of it.
;;
;;   wwwroot/bible/versions/gsb/index.html        landing page
;;   wwwroot/bible/versions/gsb/text/index.html   the English as a reading text
;;   wwwroot/bible/versions/gsb/study/index.html  Greek and English side by side
;;   wwwroot/bible/versions/gsb/data/index.html   the dataset page; beside it
;;     schema.sql, and the files the study page's script loads on demand
;;     (NN-<id>.tsv, strongs.tsv, glosses.json, translation/NN-<id>.json)
;;
;; The study page is plain text per verse; assets/bible/gsb/gsb.js adds
;; per-word markup on demand. Output is deterministic and unchanged files are
;; left alone. Invoked through ./scripts/gsb-site.sh (make gsb/site).

(use-modules (scripts lib gsb)
             (scripts lib gsb-db)
             (scripts lib md)
             (scripts lib dirs)
             (ice-9 format)
             (ice-9 ftw)
             (ice-9 match)
             (ice-9 regex)
             (ice-9 textual-ports)
             (srfi srfi-1)
             (srfi srfi-13))

(fluid-set! %default-port-encoding "UTF-8")

(define %out "wwwroot/bible/versions/gsb")
(define %db (string-append %out "/data/gsb.sqlite"))

(define (usage port)
  (format port "Usage: ./scripts/gsb-site.sh [-h|--help]~%~%")
  (format port "Render the Greek Source Bible pages into ~a/ from the database~%" %out)
  (format port "~a (run `make gsb/db` first):~%" %db)
  (format port "  index.html        landing page with the download~%")
  (format port "  text/index.html   the English as a reading text~%")
  (format port "  study/index.html  Greek and English side by side, word lookup, notes~%")
  (format port "  data/             the dataset page, schema.sql and the study page's data~%~%")
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

(define (emit path text)
  (let ((r (write-if-changed path text #f)))
    (when (eq? r 'wrote) (format #t "GSB: ~a~%" path))))

(define (q sql) (sql-query %db sql))

(define (num n)
  "N with thousands separators: 12,345."
  (let loop ((s (number->string n)))
    (if (<= (string-length s) 3) s
        (string-append (loop (substring s 0 (- (string-length s) 3))) "," (substring s (- (string-length s) 3))))))

(define (megabytes path)
  (format #f "~,1f MB" (/ (stat:size (stat path)) 1048576.0)))

(define (group-by key rows)
  "Hash KEY(row) -> rows in order."
  (let ((h (make-hash-table)))
    (for-each (lambda (r) (hash-set! h (key r) (cons r (hash-ref h (key r) '())))) (reverse rows))
    h))

;;; ---------------------------------------------------------------------------
;;; Loading from the database
;;; ---------------------------------------------------------------------------

;; A book: alist with the books columns as symbols, plus
;;   verses: list of (ref chapter verse . words), printed order; a word is
;;           (n pre word post lemma strong morph flags), flags a list
(define (load-books)
  (let* ((words (group-by car (q "SELECT w.ref, w.n, ifnull(w.pre,''), w.word, ifnull(w.post,''), ifnull(w.lemma,''),
                                         ifnull(w.strong,''), ifnull(w.morph,''),
                                         ifnull((SELECT group_concat(value, ',') FROM json_each(w.flags)), '')
                                  FROM words w JOIN verses v USING (ref) ORDER BY v.id, w.n")))
         (verses (group-by car (q "SELECT book, ref, chapter, verse FROM verses ORDER BY id"))))
    (map (match-lambda
           ((nn id english greek testament deutero role notes chapters slug)
            `((nn . ,nn) (id . ,id) (english . ,english) (greek . ,greek) (testament . ,testament)
              (deuterocanonical . ,(if (string=? deutero "1") "yes" "no")) (role . ,role) (notes . ,notes)
              (chapters . ,chapters) (slug . ,slug)
              (verses . ,(map (match-lambda
                                ((_ ref chapter verse)
                                 (cons* ref chapter verse
                                        (map (match-lambda
                                               ((_ n pre word post lemma strong morph flags)
                                                (list (string->number n) pre word post lemma strong morph
                                                      (if (string-null? flags) '() (string-split flags #\,)))))
                                             (hash-ref words ref '())))))
                              (hash-ref verses id '()))))))
         (q "SELECT nn, id, english, greek, testament, deuterocanonical, role, ifnull(notes,''), ifnull(chapters,''), slug
             FROM books ORDER BY ord"))))

(define (book-field book field) (or (assq-ref book field) ""))
(define (book-stem book) (string-append (book-field book 'nn) "-" (book-field book 'id)))
(define (book-verses book) (assq-ref book 'verses))
(define v-ref car)
(define v-chapter cadr)
(define v-verse caddr)
(define v-words cdddr)

;; Translation: hash ref -> alist status literal readable segs (literal
;; segments) rsegs (aligned readable segments or '()). A segment is
;; (clause text refs) with REFS a list of (n cont? sense).
(define (load-translation)
  (let ((table (make-hash-table))
        (words (group-by (lambda (r) (string-append (first r) " " (second r) " " (third r)))
                         (q "SELECT ref, layer, seg, n, cont, ifnull(sense,'') FROM translation_words ORDER BY ref, layer, seg, pos")))
        (segs (group-by (lambda (r) (string-append (first r) " " (second r)))
                        (q "SELECT ref, layer, seg, ifnull(clause,-1), text FROM translation_segments ORDER BY ref, layer, seg"))))
    (define (segments ref layer)
      (map (match-lambda
             ((_ _ seg clause text)
              (list (string->number clause) text
                    (map (match-lambda ((_ _ _ n cont sense) (list (string->number n) (string=? cont "1") sense)))
                         (hash-ref words (string-append ref " " layer " " seg) '())))))
           (hash-ref segs (string-append ref " " layer) '())))
    (for-each (match-lambda
                ((ref status literal readable)
                 (hash-set! table ref `((status . ,status) (literal . ,literal) (readable . ,readable)
                                        (segs . ,(segments ref "literal")) (rsegs . ,(segments ref "readable"))))))
              (q "SELECT l.ref, l.status, l.text, ifnull(r.text,'') FROM translation l
                  LEFT JOIN translation r ON r.ref = l.ref AND r.layer = 'readable' WHERE l.layer = 'literal'"))
    table))

;; Notes: (book-notes chapter-notes verse-notes): hashes book -> markdown list,
;; "book.chapter" -> markdown list, ref -> list of (n-or-#f . markdown).
(define (load-notes)
  (let ((rows (q "SELECT book, ifnull(chapter,''), ifnull(ref,''), ifnull(n,''), markdown FROM notes ORDER BY id"))
        (b (make-hash-table)) (c (make-hash-table)) (v (make-hash-table)))
    (define (push! h k x) (hash-set! h k (append (hash-ref h k '()) (list x))))
    (for-each (match-lambda
                ((book "" "" _ text) (push! b book text))
                ((book chapter "" _ text) (push! c (string-append book "." chapter) text))
                ((_ _ ref n text) (push! v ref (cons (string->number n) text))))
              rows)
    (list b c v)))

;;; ---------------------------------------------------------------------------
;;; Study page: verse HTML
;;; ---------------------------------------------------------------------------

(define (greek-html words)
  "The verse's Greek as plain text; runs of restored TR words are wrapped in
<span class=tr> so they stay marked without the script."
  (let* ((tokens (map (lambda (w)
                        (cons (member "tr" (eighth w))
                              (esc (string-append (second w) (third w) (fourth w)))))
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

(define (english-html t anchor notes?)
  (string-append
   "<div class=\"e\"><p class=\"l\">" (esc (assq-ref t 'literal))
   "</p><p class=\"r\">" (esc (assq-ref t 'readable)) "</p>"
   (if notes? (format #f "<a class=\"nl\" href=\"#~a-n\">note</a>" anchor) "")
   "</div>"))

(define (verse-html slug v trans verse-notes)
  (let* ((ref (v-ref v))
         (anchor (string-append slug "-" (v-chapter v) "-" (v-verse v)))
         (t (hash-ref trans ref))
         (tr-verse? (every (lambda (w) (member "tr" (eighth w))) (v-words v))))
    (string-append
     "<div class=\"v" (if t (if (string=? (assq-ref t 'status) "reviewed") " t" " t d") "") "\" id=\"" anchor "\">"
     "<a href=\"#" anchor "\">" (v-verse v) "</a>"
     "<p lang=\"grc\"" (if tr-verse? " class=\"trv\"" "") ">" (greek-html (v-words v)) "</p>"
     (if t (english-html t anchor (pair? (hash-ref verse-notes ref '()))) "")
     "</div>\n")))

(define (chapters-of verses)
  "VERSES grouped by chapter: a list of (chapter . verses), chapters in order of
first appearance, verses in printed order. A verse printed out of order across
a chapter boundary joins its own chapter rather than starting a second one."
  (let ((groups (make-hash-table)) (order '()))
    (for-each (lambda (v)
                (let ((c (v-chapter v)))
                  (unless (hash-ref groups c) (set! order (cons c order)))
                  (hash-set! groups c (cons v (hash-ref groups c '())))))
              verses)
    (map (lambda (c) (cons c (reverse (hash-ref groups c)))) (reverse order))))

(define (chapter-notes-html slug book chapter chapter-verses notes)
  (match notes
    ((_ chapter-notes verse-notes)
     (let* ((cnotes (hash-ref chapter-notes (string-append (book-field book 'id) "." chapter) '()))
            (vnotes (filter-map (lambda (v) (let ((ns (hash-ref verse-notes (v-ref v) '()))) (and (pair? ns) (cons v ns))))
                                chapter-verses)))
       (if (and (null? cnotes) (null? vnotes))
           ""
           (string-append
            "<details class=\"notes\" id=\"" slug "-" chapter "-notes\"><summary>Translation notes</summary>"
            (string-concatenate (map md cnotes))
            (if (null? vnotes)
                ""
                (string-append
                 "<dl>"
                 (string-concatenate
                  (map (match-lambda
                         ((v . ns)
                          (let ((anchor (string-append slug "-" chapter "-" (v-verse v))))
                            (string-append
                             "<dt id=\"" anchor "-n\"><a href=\"#" anchor "\">" chapter ":" (v-verse v) "</a></dt>"
                             (string-concatenate
                              (map (match-lambda
                                     ((#f . text) (string-append "<dd>" (md text) "</dd>"))
                                     ((n . text)
                                      (let ((w (find (lambda (w) (= (first w) n)) (v-words v))))
                                        (string-append "<dd><span lang=\"grc\">" (esc (third w)) "</span> (word " (number->string n) ") "
                                                       (md text) "</dd>"))))
                                   ns))))))
                       vnotes))
                 "</dl>"))
            "</details>"))))))

;;; ---------------------------------------------------------------------------
;;; Study page: books
;;; ---------------------------------------------------------------------------

(define (book-labels book)
  (let ((verses (book-verses book))
        (role (book-field book 'role))
        (notes (book-field book 'notes)))
    (string-append
     (if (string=? (book-field book 'deuterocanonical) "yes")
         "<p class=\"label\">Deuterocanonical: outside the 39-book Protestant Old Testament; translated last.</p>" "")
     (if (string=? role "comparison") "<p class=\"label\">For comparison only: this is not the main text.</p>" "")
     (if (string-null? notes) "" (string-append "<p class=\"label\">" (esc notes) "</p>"))
     (cond
      ((null? verses) "<p class=\"label missing\">Greek not yet transcribed.</p>")
      ;; A Swete book is partial unless books.tsv records its chapter total
      ;; and every chapter has a table (blank total: always partial).
      ((string=? (book-field book 'testament) "OT")
       (let ((chapters (map car (chapters-of verses)))
             (total (string->number (book-field book 'chapters))))
         (if (and total (>= (length chapters) total))
             ""
             (format #f "<p class=\"label missing\">Greek partially transcribed: chapter~a ~a so far.</p>"
                     (if (= 1 (length chapters)) "" "s")
                     (string-join chapters ", ")))))
      (else "")))))

(define (translated? book trans) (any (lambda (v) (hash-ref trans (v-ref v))) (book-verses book)))

(define (book-html book trans notes)
  (let* ((id (book-field book 'id))
         (slug (book-field book 'slug))
         (chapters (chapters-of (book-verses book)))
         (book-notes (hash-ref (first notes) id '())))
    (string-append
     "<section class=\"book\" id=\"" slug "\" data-id=\"" id "\" data-f=\"" (book-stem book) "\""
     (if (translated? book trans) " data-t" "")
     "><h2>" (esc (book-field book 'english)) " <span lang=\"grc\">" (esc (book-field book 'greek)) "</span></h2>"
     (book-labels book)
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
               (chapter-notes-html slug book chapter chapter-verses notes)
               (string-concatenate (map (lambda (v) (verse-html slug v trans (third notes))) chapter-verses))
               "</section>")))
           chapters))
     "</section>\n")))

(define (progress-html books trans)
  (let* ((rows (filter-map (lambda (b)
                             (let ((verses (book-verses b)))
                               (and (pair? verses)
                                    (list b (length verses) (count (lambda (v) (hash-ref trans (v-ref v))) verses)))))
                           books))
         (total (apply + (map second rows)))
         (done (apply + (map third rows))))
    (string-append
     "<details id=\"progress\"><summary>Progress: " (num done) " of " (num total)
     " verses translated (of the verses whose Greek is transcribed)</summary>"
     "<div class=\"table-scroll\"><table><thead><tr><th>Book</th><th>Translated</th><th>Verses</th></tr></thead><tbody>"
     (string-concatenate
      (map (match-lambda
             ((book total done)
              (format #f "<tr><td><a href=\"#~a\">~a</a></td><td>~a</td><td>~a</td></tr>"
                      (book-field book 'slug) (esc (book-field book 'english)) (num done) (num total))))
           rows))
     "</tbody></table></div>"
     "<p>Books not listed have no Greek transcribed yet.</p></details>\n")))

;; Concordance rows: (lemma sense gloss forms-json readable why), file order.
(define (load-glosses)
  (q "SELECT lemma, sense, gloss, forms, ifnull(readable,''), why FROM glosses ORDER BY rowid"))

(define (lemmas-in-order glosses)
  (delete-duplicates (map first glosses)))

(define (concordance-html glosses)
  (let ((by-lemma (group-by first glosses))
        (lemmas (lemmas-in-order glosses)))
    (string-append
     "<details id=\"concordance\"><summary>Concordance decisions (" (number->string (length lemmas))
     " lemmas)</summary><p>One English gloss per Greek lemma per sense, enforced by a script. Each entry gives the gloss and the reasoning.</p><dl>"
     (string-concatenate
      (map (lambda (lemma)
             (string-append
              "<dt lang=\"grc\" id=\"lemma-" (esc lemma) "\">" (esc lemma) "</dt>"
              (string-concatenate
               (map (match-lambda
                      ((_ sense gloss _ readable why)
                       (string-append "<dd><b>" (if (string-null? gloss) "(not rendered)" (esc gloss))
                                      "</b> <small>(" sense ")</small> "
                                      (if (string-null? readable) "" (string-append "Readable layer: <b>" (esc readable) "</b>. "))
                                      (esc why) "</dd>")))
                    (hash-ref by-lemma lemma)))))
           lemmas))
     "</dl></details>\n")))

(define (nav-html books)
  (define (links testament)
    (string-join
     (filter-map (lambda (b)
                   (and (string=? (book-field b 'testament) testament)
                        (format #f "<a href=\"#~a\"~a>~a</a>" (book-field b 'slug)
                                (if (pair? (book-verses b)) "" " class=\"missing\"")
                                (esc (book-field b 'english)))))
                 books)
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
<h3 id=\"limits\">Limits, stated up front</h3>
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
<p>All sources are public domain or CC0. The Greek text, the translation and every decision behind them are published as <a href=\"/bible/versions/gsb/data/\">one open database</a>.</p>
<p><b>Dedication.</b> To the extent possible under law, the authors have dedicated all copyright and related rights in the Greek Source Bible (the translation, the transcription, the notes and all of its data) to the public domain worldwide under <a href=\"https://creativecommons.org/publicdomain/zero/1.0/\">CC0 1.0</a>. No permission or attribution is needed.</p>
</section>
")

(define (options-html books)
  "The sticky bar: book and chapter pickers and the display switches. Hidden
until gsb.js runs; without JS the book links above do the navigating."
  (define (options testament)
    (string-concatenate
     (filter-map (lambda (b)
                   (and (string=? (book-field b 'testament) testament)
                        (format #f "<option value=\"~a\"~a>~a</option>" (book-field b 'slug)
                                (if (pair? (book-verses b)) "" " disabled")
                                (esc (book-field b 'english)))))
                 books)))
  (string-append "
<form id=\"options\" hidden>
<label>Book <select name=\"book\"><option value=\"\">Go to…</option>
<optgroup label=\"Old Testament\">" (options "OT") "</optgroup>
<optgroup label=\"New Testament\">" (options "NT") "</optgroup></select></label>
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

(define %links
  "<p class=\"gsb-links\"><a href=\"/bible/versions/gsb/\">Greek Source Bible</a> · <a href=\"/bible/versions/gsb/text/\">Read the text</a> · <a href=\"/bible/versions/gsb/study/\">Study edition</a> · <a href=\"/bible/versions/gsb/data/\">Download the data</a></p>\n")

(define* (page-head title #:key (back "/bible/versions/gsb/") (back-name "gsb") (extra ""))
  (string-append
   "<!DOCTYPE html>\n<html lang=\"en\"><head><meta charset=\"UTF-8\">"
   "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">"
   "<link rel=\"icon\" type=\"image/x-icon\" href=\"/shared/favicons/favicon.ico\">"
   "<link rel=\"stylesheet\" href=\"/shared/styles/openword-theme.css\">"
   extra
   "<title>" (esc title) "</title></head><body>\n"
   "<header><div id=\"header\"><span id=\"header-back\"><a id=\"header-back-link\" href=\"" back "\">&#8612; <code>"
   back-name "</code></a></span></div></header>\n"))

(define (heading tag id text)
  (format #f "<~a><a id=\"~a\" href=\"#~a\" class=\"list-item-internal-link\">~a</a></~a>" tag id id (esc text) tag))

(define (study-html books trans notes glosses)
  (string-append
   (page-head "Greek Source Bible: study edition"
              #:extra (string-append
                       ;; ?v= changes whenever the file does, so browsers never show a stale copy.
                       "<link rel=\"stylesheet\" href=\"/assets/bible/gsb/gsb.css?v=" (asset-version "assets/bible/gsb/gsb.css") "\">"
                       "<script src=\"/assets/bible/gsb/gsb.js?v=" (asset-version "assets/bible/gsb/gsb.js") "\" defer></script>"))
   (options-html books)
   "<h1>Greek Source Bible: study edition</h1>\n"
   %links
   "<p>The whole Bible translated from Greek: the Old Testament from the Septuagint, the New Testament from the Greek New Testament. Greek and English side by side; every verse can be linked (<code>#john-3-16</code>), with the same anchors as the other versions on this site. For the English alone, see <a href=\"/bible/versions/gsb/text/\">the reading text</a>.</p>\n"
   (nav-html books)
   (progress-html books trans)
   %intro
   %legend
   (concordance-html glosses)
   ;; ponytail: one page for the whole Bible (3.5 MB at the New Testament plus
   ;; Genesis, Exodus and Daniel); at ~750,000 Greek words (~15 MB of HTML)
   ;; split it into one page per book.
   "<main id=\"text\">\n"
   (string-concatenate (map (lambda (b) (book-html b trans notes)) books))
   "</main></body></html>\n"))

;;; ---------------------------------------------------------------------------
;;; Reading page: the English alone, laid out like the KJV and BSB text pages
;;; ---------------------------------------------------------------------------

(define (chapter-ranges chapters)
  "(\"1\" \"2\" \"3\" \"5\") -> \"1-3, 5\"."
  (let loop ((ns (map string->number chapters)) (acc '()))
    (match ns
      (() (string-join (reverse acc) ", "))
      ((a . rest)
       (let run ((b a) (rest rest))
         (if (and (pair? rest) (= (car rest) (+ b 1)))
             (run (car rest) (cdr rest))
             (loop rest (cons (if (= a b) (number->string a) (format #f "~a-~a" a b)) acc))))))))

;;; ---------------------------------------------------------------------------
;;; Progress: the progress and progress_totals views (gsb/schema.sql)
;;; ---------------------------------------------------------------------------

(define %progress-columns '(book english testament transcribed chapters_transcribed chapters complete literal readable accepted))

(define progress-rows
  (let ((rows #f))
    (lambda ()
      "The progress view, in book order: alists keyed by %progress-columns."
      (unless rows
        (set! rows (map (lambda (r) (map (lambda (k v) (cons k (if (memq k '(book english testament chapters)) v (string->number v))))
                                         %progress-columns r))
                        (q "SELECT book, english, testament, transcribed, chapters_transcribed, ifnull(chapters,''),
                                   transcription_complete, literal, readable, accepted FROM progress ORDER BY ord"))))
      rows)))

(define (book-progress id) (find (lambda (r) (string=? (assq-ref r 'book) id)) (progress-rows)))

(define (progress-table)
  "The progress table: one row per Old Testament book with Greek, the Old
Testament total, the New Testament as one row, and the overall total."
  (let* ((rows (progress-rows))
         (ot (filter (lambda (r) (and (string=? (assq-ref r 'testament) "OT") (> (assq-ref r 'transcribed) 0))) rows))
         (totals (map (match-lambda ((scope books started . counts) (cons* scope (string->number books) (string->number started) (map string->number counts))))
                      (q "SELECT scope, books, books_started, transcribed, literal, readable, accepted FROM progress_totals")))
         (pct (lambda (n of) (if (zero? of) "" (format #f " <small>(~a%)</small>" (let ((p (* 100.0 (/ n of)))) (if (and (> p 0) (< p 1)) "<1" (inexact->exact (round p))))))))
         (cells (lambda (transcribed literal readable accepted greek-note)
                  (string-append "<td>" (num transcribed) greek-note "</td>"
                                 (string-concatenate (map (lambda (n) (string-append "<td>" (num n) (pct n transcribed) "</td>"))
                                                          (list literal readable accepted))))))
         (total-row (lambda (label t)
                      (match t ((_ _ _ transcribed literal readable accepted)
                                (string-append "<tr><th>" label "</th>" (cells transcribed literal readable accepted "") "</tr>")))))
         (ot-total (assoc "OT" totals))
         (nt-total (assoc "NT" totals)))
    (string-append
     "<div class=\"table-scroll\"><table class=\"progress\"><thead><tr><th>Book</th><th>Greek transcribed</th><th>Literal</th><th>Readable</th><th>Accepted</th></tr></thead><tbody>"
     (string-concatenate
      (map (lambda (r)
             (string-append "<tr><td>" (esc (assq-ref r 'english)) "</td>"
                            (cells (assq-ref r 'transcribed) (assq-ref r 'literal) (assq-ref r 'readable) (assq-ref r 'accepted)
                                   (if (= 1 (assq-ref r 'complete))
                                       " <small>(complete)</small>"
                                       (format #f " <small>(~a~a chapter~a)</small>" (assq-ref r 'chapters_transcribed)
                                               (if (string-null? (assq-ref r 'chapters)) "" (string-append " of " (assq-ref r 'chapters)))
                                               (if (and (= 1 (assq-ref r 'chapters_transcribed)) (string-null? (assq-ref r 'chapters))) "" "s"))))
                            "</tr>"))
           ot))
     (total-row "Old Testament" ot-total)
     (total-row (format #f "New Testament <small>(~a books, not being worked on now)</small>" (second nt-total)) nt-total)
     (total-row "All" (assoc "all" totals))
     "</tbody></table></div>"
     (format #f "<p>Verses. Literal, readable and accepted are percentages of the verses transcribed; accepted means the owner has accepted the readable verse. ~a of the ~a Old Testament books are not yet started.</p>\n"
             (- (second ot-total) (third ot-total)) (second ot-total)))))

(define (readable trans v)
  "V's readable English (plain or aligned, as prose), or #f when it has none."
  (let ((t (hash-ref trans (v-ref v))))
    (and t (not (string-null? (assq-ref t 'readable))) (assq-ref t 'readable))))

(define (readable? book trans) (any (lambda (v) (readable trans v)) (book-verses book)))

(define (reading-book-html book trans)
  (let* ((slug (book-field book 'slug))
         (verses (book-verses book))
         (done (filter (lambda (v) (readable trans v)) verses))
         (chapters (filter-map (match-lambda ((c . vs) (let ((ds (filter (lambda (v) (readable trans v)) vs)))
                                                          (and (pair? ds) (cons c ds)))))
                               (chapters-of verses))))
    (string-append
     (heading "h2" slug (book-field book 'english)) "\n"
     "<p><i>"
     (let* ((p (book-progress (book-field book 'id)))
            (transcribed (assq-ref p 'transcribed)) (literal (assq-ref p 'literal)) (readable (assq-ref p 'readable)))
       (cond ((zero? transcribed) "Not yet translated; the Greek is not yet transcribed.")
             ((and (zero? readable) (> literal 0))
              (format #f "Readable translation not yet written (literal draft of ~a of ~a verses and the Greek in the <a href=\"/bible/versions/gsb/study/#~a\">study edition</a>)."
                      (num literal) (num transcribed) slug))
             ((zero? readable) (format #f "Not yet translated (~a verses of Greek transcribed)." (num transcribed)))
             ((= readable transcribed) "Readable translation (draft).")
             (else (format #f "Readable translation so far: chapter~a ~a (~a of the ~a verses transcribed). Draft."
                           (if (= 1 (length chapters)) "" "s") (chapter-ranges (map car chapters))
                           (num readable) (num transcribed)))))
     "</i></p>\n"
     (string-concatenate
      (map (match-lambda
             ((chapter . vs)
              (string-append
               (heading "h3" (string-append slug "-" chapter) (string-append (book-field book 'english) " " chapter)) "\n"
               (string-concatenate
                (map (lambda (v)
                       (let ((anchor (string-append slug "-" chapter "-" (v-verse v))))
                         (format #f "<p id=\"~a\"><strong><a href=\"#~a\">~a</a></strong> ~a</p>\n"
                                 anchor anchor (v-verse v) (esc (readable trans v)))))
                     vs)))))
           chapters)))))

(define (reading-html books trans)
  (string-append
   (page-head "Greek Source Bible"
              ;; This address used to be the study edition: a link to a verse
              ;; not translated yet goes on to its Greek there.
              #:extra "<script>function gsbOn(){var h=location.hash;if(h&&!document.getElementById(decodeURIComponent(h.slice(1))))location.replace('/bible/versions/gsb/study/'+h)}addEventListener('DOMContentLoaded',gsbOn);addEventListener('hashchange',gsbOn)</script>")
   (heading "h1" "greek-source-bible" "Greek Source Bible") "\n"
   %links
   "<p>This is the readable translation. It is made after the literal, word-for-word translation, and so far covers only the chapters listed below. For the literal translation and the Greek beside it, word by word, see the <a href=\"/bible/versions/gsb/study/\">study edition</a>.</p>\n"
   "<p>The translation is drafted with AI assistance and reviewed by the owner (<a href=\"/bible/versions/gsb/#limits\">limits</a>). The Old Testament comes first; books are listed as they are translated.</p>\n"
   (string-concatenate
    (map (lambda (b) (reading-book-html b trans))
         (filter (lambda (b) (or (and (string=? (book-field b 'testament) "OT") (string=? (book-field b 'role) "main"))
                                 (readable? b trans)))
                 books)))
   "</body></html>\n"))

;;; ---------------------------------------------------------------------------
;;; Landing page
;;; ---------------------------------------------------------------------------

(define (sibling-nav)
  "Previous/next links among the Bible versions, as the markdown pages have."
  (let* ((dir "templates/bible/versions")
         (names (sort (filter (lambda (n) (and (not (member n '("." "..")))
                                               (file-exists? (string-append dir "/" n "/index.md"))))
                              (or (scandir dir) '()))
                      string<?))
         (tail (member "gsb" names))
         (prev (and tail (let ((before (list-head names (- (length names) (length tail))))) (and (pair? before) (last before)))))
         (next (and tail (pair? (cdr tail)) (cadr tail)))
         (title (lambda (n) (esc (or (read-frontmatter-title (string-append dir "/" n "/index.md")) n)))))
    (if (not (or prev next))
        ""
        (string-append
         "<nav id=\"page-nav\">"
         (if prev (format #f "<a id=\"nav-prev\" href=\"/bible/versions/~a/\">&larr; ~a</a>" prev (title prev)) "")
         (if (and prev next) " " "")
         (if next (format #f "<a id=\"nav-next\" href=\"/bible/versions/~a/\" style=\"float: right;\">~a &rarr;</a>" next (title next)) "")
         "</nav><script>document.addEventListener('keydown',function(e){if(e.altKey||e.ctrlKey||e.metaKey)return;if(e.key==='ArrowLeft'){var a=document.getElementById('nav-prev');if(a)a.click();}if(e.key==='ArrowRight'){var a=document.getElementById('nav-next');if(a)a.click();}});</script>"))))

(define (download-html)
  (string-append
   "<section id=\"download\" style=\"border:1px solid currentColor;border-radius:6px;padding:0.2em 1em;margin:1em 0\">"
   (heading "h2" "download-the-data" "Download the data")
   "<p><a href=\"/bible/versions/gsb/data/gsb.sqlite\" download><b>gsb.sqlite</b></a> (" (megabytes %db)
   "; <a href=\"/bible/versions/gsb/data/gsb.sqlite.gz\" download>compressed</a>, " (megabytes (string-append %db ".gz"))
   "). CC0: no permission or attribution needed.</p>"
   "<p>One SQLite file with the whole project: the Greek text with every word tagged, the translation and its word-by-word alignment, the concordance with the reason for each English gloss, the notes, and every decision made in transcribing the Septuagint. Every page of this translation is made from it. <a href=\"/bible/versions/gsb/data/\">What is in it, what it is for, and how to use it.</a></p>"
   "</section>\n"))

(define (landing-html)
  (string-append
   (page-head "Ursinia - GSB" #:back "/bible/versions/" #:back-name "versions")
   (heading "h1" "ursinia---gsb" "Ursinia - GSB") "\n"
   "<p>The Greek Source Bible: the whole Bible translated from Greek, the Old Testament from the Septuagint and the New Testament from the Greek New Testament. A work in progress, dedicated to the public domain (CC0).</p>\n"
   "<ul>"
   "<li><a href=\"/bible/versions/gsb/text/\">Full text</a>: the readable translation, so far as it is written</li>"
   "<li><a href=\"/bible/versions/gsb/study/\">Study edition</a>: Greek and English side by side, word by word, with every translation decision</li>"
   "<li><a href=\"/bible/versions/gsb/data/\">Data</a>: the whole project as one SQLite database</li>"
   "</ul>\n"
   (download-html)
   (heading "h2" "progress" "Progress") "\n"
   (progress-table)
   (heading "h2" "self-hosted-(downloads-a-file)" "Self-Hosted (downloads a file)")
   "<ul><li><a href=\"/bible/versions/gsb/data/gsb.sqlite\">GSB - Database (SQLite)</a></li>"
   "<li><a href=\"/bible/versions/gsb/data/gsb.sqlite.gz\">GSB - Database (SQLite, gzip)</a></li>"
   "<li><a href=\"/bible/versions/gsb/data/schema.sql\">GSB - Schema and data dictionary</a></li></ul>\n"
   %intro
   (sibling-nav)
   "</body></html>\n"))

;;; ---------------------------------------------------------------------------
;;; Data page
;;; ---------------------------------------------------------------------------

(define (meta key) (match (q (format #f "SELECT value FROM meta WHERE key = '~a'" key)) (((v)) v) (_ "")))

(define (schema-docs schema)
  "Alist name -> description, from the comments in SCHEMA above (or beside)
each CREATE TABLE / VIEW."
  (let loop ((lines (string-split schema #\newline)) (comment '()) (acc '()))
    (match lines
      (() (reverse acc))
      ((l . rest)
       (cond
        ((string-prefix? "-- " l) (loop rest (append comment (list (substring l 3))) acc))
        ((string-match "^CREATE (VIRTUAL )?(TABLE|VIEW) ([a-z_]+)[^-]*(-- (.*))?" l)
         => (lambda (m)
              (loop rest '()
                    (acons (match:substring m 3)
                           (if (match:substring m 5) (match:substring m 5)
                               ;; first sentence of the comment block
                               (let ((s (string-join comment " ")))
                                 (match (string-contains s ". ") (#f s) (i (substring s 0 (+ i 1)))))) acc))))
        (else (loop rest '() acc)))))))

(define (code-block kind text)
  "A code block; assets/bible/gsb/copy.js gives it a copy button (KIND is
\"query\" or \"command\", for the button's name)."
  (string-append "<pre data-copy=\"" kind "\"><code>" (esc text) "</code></pre>"))

(define %queries
  `(("Search the Septuagint by lemma"
     "Every Old Testament verse with a form of λόγος, the word and how it is translated so far."
     "SELECT e.ref, e.word, e.english
FROM word_english e
JOIN verses v USING (ref)
JOIN books b ON b.id = v.book
WHERE b.testament = 'OT' AND e.lemma = 'λόγος'
ORDER BY v.id;")
    ("Search the text"
     "Full text over the Greek, the Greek without accents (write final sigma as σ), the lemmas and the English."
     "SELECT v.ref, v.greek
FROM search JOIN verses v ON v.id = search.rowid
WHERE search MATCH 'greek_plain: αρχη'
ORDER BY v.id;")
    ("Find every place a Greek word is rendered a given way"
     "Which Greek words are translated \"firmament\", and how each English rendering of ἀρχή is used."
     "SELECT ref, word, lemma, sense, english
FROM word_english WHERE english LIKE '%firmament%';

SELECT sense, english, count(*) AS uses
FROM word_english WHERE lemma = 'ἀρχή' AND english IS NOT NULL
GROUP BY sense, english;")
    ("Compare a New Testament quotation with its Septuagint source"
     "Old Testament verses sharing the most lemmas with Matthew 19:5 (which quotes Genesis 2:24), leaving out the commonest words."
     "WITH q AS (
  SELECT DISTINCT lemma FROM words
  WHERE ref = 'matt.19.5'
    AND lemma NOT IN ('ὁ', 'καί', 'αὐτός', 'εἰμί', 'δέ', 'εἰς', 'ἐν', 'λέγω'))
SELECT w.ref, count(DISTINCT w.lemma) AS shared, v.greek
FROM words w
JOIN books b ON b.id = w.book
JOIN verses v ON v.ref = w.ref
WHERE b.testament = 'OT' AND w.lemma IN (SELECT lemma FROM q)
GROUP BY w.ref ORDER BY shared DESC LIMIT 5;")
    ("Pull the transcription decisions for a verse"
     "Every place on the printed lines of Genesis 1:1 where the readings disagreed, and the page as we transcribed it."
     "SELECT leaf, line, reading_a, reading_b, reading_c, chosen, basis
FROM verse_decisions WHERE ref = 'gen.1.1';

SELECT p.text FROM transcription_pages p
JOIN verses v ON v.book = p.book AND v.leaf_first = p.leaf
WHERE v.ref = 'gen.1.1';")
    ("Look up a word in the lexicon and the concordance"
     "Strong's entry and our glosses with their reasoning."
     "SELECT l.strong, l.gloss, l.definition, g.sense, g.gloss AS ours, g.why
FROM lexicon l LEFT JOIN glosses g ON g.lemma = l.lemma
WHERE l.lemma = 'ἀρχή';")
    ("Track progress"
     "Verses per Old Testament book: Greek transcribed, literal English, readable English, and readable verses the owner has accepted; then the totals."
     "SELECT english, transcribed, literal, readable, accepted, transcription_complete
FROM progress WHERE testament = 'OT' AND transcribed > 0 ORDER BY ord;

SELECT * FROM progress_totals;")
    ("Build your own reader or app"
     "A chapter with Greek and English side by side, as JSON."
     "sqlite3 -json gsb.sqlite \\
  \"SELECT verse, greek, literal FROM verse_text
   WHERE book = 'gen' AND chapter = 1\" > genesis-1.json")))

(define (data-html books trans)
  (let* ((docs (schema-docs (meta "schema")))
         (tables (q "SELECT name, type FROM sqlite_master WHERE type IN ('table','view') AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'search_%' ORDER BY rowid"))
         (ot (filter (lambda (b) (string=? (book-field b 'testament) "OT")) books))
         (transcribed (filter (lambda (b) (pair? (book-verses b))) ot))
         (translated (filter (lambda (b) (translated? b trans)) books))
         (pages (q "SELECT count(*), sum(status = 'done') FROM transcription_pages")))
    (string-append
     (page-head "Greek Source Bible: data"
                #:extra (string-append
                         "<link rel=\"stylesheet\" href=\"/assets/bible/gsb/copy.css?v=" (asset-version "assets/bible/gsb/copy.css") "\">"
                         "<script src=\"/assets/bible/gsb/copy.js?v=" (asset-version "assets/bible/gsb/copy.js") "\" defer></script>"))
     (heading "h1" "greek-source-bible-data" "Greek Source Bible: data") "\n"
     %links
     "<p>The whole Greek Source Bible project is one SQLite database. Every page of this translation is made from it and from nothing else, so what you download is everything we have: the Greek text, every word's lemma, Strong's number and grammar tag, the translation and which Greek words each piece of English translates, our concordance with the reason for every gloss, the notes, and every decision made while transcribing Swete's Septuagint from the page scans.</p>\n"
     (download-html)
     (format #f "<p>Also: <a href=\"schema.sql\">schema.sql</a>, the schema with every column explained. Data as of ~a.</p>\n" (esc (meta "updated")))

     (heading "h2" "what-it-is-for" "What it is for") "\n"
     "<p>There is no other public-domain Septuagint with its words tagged. Use it to study the Greek Old Testament and its use in the New, to check our translation word by word, or to build your own Bible software with no license to negotiate. Each example below can be pasted into <code>sqlite3 gsb.sqlite</code>.</p>\n"
     (string-concatenate
      (map (match-lambda
             ((title text sql)
              (string-append "<h3>" (esc title) "</h3><p>" (esc text) "</p>" (code-block (if (string-prefix? "sqlite3 " sql) "command" "query") sql) "\n")))
           %queries))

     (heading "h2" "how-to-open-it" "How to open it") "\n"
     "<ul><li>The <code>sqlite3</code> command-line program, which comes with macOS and most Linux systems. Open the file, then list the tables and show one table's columns:"
     (code-block "command" "sqlite3 gsb.sqlite") (code-block "command" ".tables\n.schema words") "</li>"
     "<li><a href=\"https://sqlitebrowser.org/\">DB Browser for SQLite</a>, to browse and query it in a window.</li>"
     "<li><a href=\"https://datasette.io/\">Datasette</a> serves it as a website with search and JSON:" (code-block "command" "datasette gsb.sqlite") "</li>"
     "<li>Any programming language's SQLite library. The compressed copy unpacks with:" (code-block "command" "gunzip gsb.sqlite.gz") "</li></ul>\n"

     (heading "h2" "tables" "What is in it") "\n"
     "<div class=\"table-scroll\"><table><thead><tr><th>Table</th><th>Rows</th><th>What</th></tr></thead><tbody>"
     (string-concatenate
      (map (match-lambda
             ((name type)
              (format #f "<tr><td><code>~a</code>~a</td><td>~a</td><td>~a</td></tr>"
                      name (if (string=? type "view") " (view)" "")
                      (if (string=? type "view") "" (num (string->number (caar (q (format #f "SELECT count(*) FROM \"~a\"" name))))))
                      (esc (or (assoc-ref docs name) "")))))
           tables))
     "</tbody></table></div>\n"
     "<p>Verses are addressed as <code>gen.1.1</code>, words as a verse and a number from 1. Empty values are NULL; flags and lists are JSON arrays.</p>\n"

     (heading "h2" "done-so-far" "What is done and what is not") "\n"
     (progress-table)
     "<ul>"
     (format #f "<li><b>Greek, Old Testament:</b> ~a of ~a books transcribed so far (~a), from ~a scan pages.</li>"
             (length transcribed) (length ot)
             (esc (string-join (map (lambda (b) (book-field b 'english)) transcribed) ", "))
             (num (string->number (caar pages))))
     "<li><b>Greek, New Testament:</b> complete (Nestle 1904 with the longer Textus Receptus readings restored).</li>"
     "<li><b>Translation:</b> all draft. The literal layer for the whole Old Testament comes next; the readable translation, which is what the reading text shows, will be made from it afterwards.</li>"
     "<li><b>Lemmas:</b> Septuagint words have a lemma only where the same form occurs in the New Testament data, or where we have supplied one while translating (see the <code>lxx_coverage</code> table).</li>"
     "</ul>\n"

     (heading "h2" "known-gaps" "Known gaps in open resources") "\n"
     (md (meta "resource_gaps"))

     (heading "h2" "license" "License") "\n"
     "<p>" (esc (meta "license_statement")) "</p>\n"
     "</body></html>\n")))

;;; ---------------------------------------------------------------------------
;;; Data files for the study page's script
;;; ---------------------------------------------------------------------------

(define (tsv header rows)
  (string-append (string-join header "\t") "\n"
                 (string-concatenate (map (lambda (r) (string-append (string-join r "\t") "\n")) rows))))

(define (greek-tsv book)
  (tsv '("ref" "n" "pre" "word" "post" "lemma" "strong" "morph" "flags")
       (append-map (lambda (v)
                     (map (match-lambda
                            ((n pre word post lemma strong morph flags)
                             (list (v-ref v) (number->string n) pre word post lemma strong morph (string-join flags ","))))
                          (v-words v)))
                   (book-verses book))))

(define (translation-json book trans)
  "JSON of a book's translated verses, keyed by chapter.verse:
{\"1.1\": {\"s\": status, \"l\": [[clause, text, [n...], [sense...], [cont n...]]...],
\"r\": [[text, [n...]]...] (aligned readable only)}}. Clause -1 = none. A
word's sense is the one its own segment uses (null when the lemma is not in
the concordance); [cont n...], present only when non-empty, lists the words of
[n...] whose own segment is an earlier one (the English continues it)."
  (json
   (filter-map
    (lambda (v)
      (let ((t (hash-ref trans (v-ref v))))
        (and t
             (let* ((senses (filter-map (match-lambda ((n cont? sense) (and (not cont?) (cons n sense))))
                                        (append-map third (assq-ref t 'segs))))
                    (sense-of (lambda (n) (match (assv-ref senses n) ((or #f "") 'null) (s s)))))
               (cons (string-append (v-chapter v) "." (v-verse v))
                     `(("s" . ,(assq-ref t 'status))
                       ("l" . ,(list->vector
                                (map (match-lambda
                                       ((clause text refs)
                                        (let ((conts (filter-map (match-lambda ((n #t _) n) (_ #f)) refs)))
                                          (list->vector
                                           (append
                                            (list clause text
                                                  (list->vector (map first refs))
                                                  (list->vector (map (lambda (r) (sense-of (first r))) refs)))
                                            (if (null? conts) '() (list (list->vector conts))))))))
                                     (assq-ref t 'segs))))
                       ,@(if (null? (assq-ref t 'rsegs))
                             '()
                             `(("r" . ,(list->vector
                                        (map (match-lambda ((_ text refs) (vector text (list->vector (map first refs)))))
                                             (assq-ref t 'rsegs))))))))))))
    (book-verses book))))

(define (glosses-json glosses)
  (let ((by-lemma (group-by first glosses)))
    (string-append
     "{"
     (string-join
      (map (lambda (lemma)
             (string-append (json lemma) ":["
                            (string-join (map (match-lambda
                                                ((_ sense _ forms _ why) (string-append "[" (json sense) "," forms "," (json why) "]")))
                                              (hash-ref by-lemma lemma))
                                         ",")
                            "]"))
           (lemmas-in-order glosses))
      ",")
     "}")))

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
  (let ((problem (sqlite3-problem)))
    (when problem
      (format (current-error-port) "gsb-site: ~a~%" problem)
      (exit 1)))
  (unless (and (file-exists? %db) (file-exists? (string-append %db ".gz")))
    (format (current-error-port) "gsb-site: ~a (or its .gz) is missing; run `make gsb/db`~%" %db)
    (exit 1))
  (let* ((books (load-books))
         (trans (load-translation))
         (notes (load-notes))
         (glosses (load-glosses))
         (data (string-append %out "/data/")))
    (emit (string-append %out "/index.html") (landing-html))
    (emit (string-append %out "/text/index.html") (reading-html books trans))
    (emit (string-append %out "/study/index.html") (study-html books trans notes glosses))
    (emit (string-append data "index.html") (data-html books trans))
    (emit (string-append data "schema.sql") (meta "schema"))
    (for-each (lambda (b)
                (when (pair? (book-verses b))
                  (emit (string-append data (book-stem b) ".tsv") (greek-tsv b)))
                (when (translated? b trans)
                  (emit (string-append data "translation/" (book-stem b) ".json") (translation-json b trans))))
              books)
    (emit (string-append data "strongs.tsv")
          (tsv '("strong" "lemma" "strongs_headword" "gloss" "definition" "definition_source")
               (q "SELECT strong, ifnull(lemma,''), ifnull(strongs_headword,''), ifnull(gloss,''), ifnull(definition,''), ifnull(definition_source,'') FROM lexicon ORDER BY rowid")))
    (emit (string-append data "glosses.json") (glosses-json glosses))))

(main (command-line))
