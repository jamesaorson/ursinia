;; Copyright (C) 2026
;;
;; Working tool for transcribing Swete's Septuagint from page scans, one leaf at
;; a time, by many agents at once. Every per-leaf command reads and writes only
;; that leaf's own files (pages/<book>/vN-LLLL.txt and .decisions.tsv) and its
;; own work directory in the cache; `merge` alone writes the shared tables.
;; The procedure is .claude/skills/gsb-transcribe/SKILL.md. Invoked through
;; ./scripts/gsb-swete.sh.

(use-modules (scripts lib swete)
             (ice-9 ftw)
             (ice-9 match)
             (ice-9 regex)
             (ice-9 format)
             (ice-9 textual-ports)
             (srfi srfi-1)
             (srfi srfi-11)
             (srfi srfi-13))

(define %program "gsb-swete")
(define %method "swete-2")
(define %root "gsb/sources/swete")

(define (usage port)
  (format port "Usage: ./scripts/gsb-swete.sh COMMAND ARGS...

Per leaf (BOOK is an id from gsb/sources/swete/leaves.tsv, e.g. gen; LEAF the
scan leaf, e.g. 39). Fetch first: ./scripts/gsb-swete-fetch.sh VOLUME LEAF...
  box BOOK LEAF [Y0 Y1 X0 X1]   create the page file / set or show the main-text box;
                                writes a preview image with the box drawn
  strips BOOK LEAF              cut the box into 5-line reading strips (PNG)
  collate BOOK LEAF             compare the page file with both OCR readings; log
                                disagreements and mandatory checks in the leaf's
                                decisions file; make zoom sheets for open rows
  decide BOOK LEAF ROWS@REV BASIS [CHOSEN]
                                settle decision rows (ROWS like 3 or 3,5,9; REV the
                                rows revision the last collate printed); without
                                CHOSEN the row records what the page file says now
  flag BOOK LEAF LINE WORD BASIS
                                log a reading no OCR row covers (damaged or ambiguous
                                print): BASIS starts 'ambiguous:' or 'image:'
  zoom BOOK LEAF LINE [SCALE]   enlarged crop of one printed line (in 3 pieces);
                                LINE counts the page file's text lines, as flag and
                                decide do (the OCR's lines before the file has text)
  zoom BOOK LEAF X0 Y0 X1 Y1 [SCALE]
                                enlarged crop of any rectangle (page pixels)
  done BOOK LEAF                check the leaf and stamp it done

Coordinator:
  status BOOK [FIRST LAST]      done / wip / missing / FAIL per leaf; exit 1 on FAIL
  merge                         rebuild NN-<id>.tsv, decisions.tsv, provenance.tsv
                                from the per-leaf files (done leaves only)

Images go to $GSB_SWETE_CACHE (default ~~/.cache/gsb-swete)/<scan>/work/<book>-LLLL/.
Example session:
  ./scripts/gsb-swete-fetch.sh 1 39
  ./scripts/gsb-swete.sh box gen 39
  ./scripts/gsb-swete.sh strips gen 39
  (write gsb/sources/swete/pages/gen/v1-0039.txt from the strips)
  ./scripts/gsb-swete.sh collate gen 39
  ./scripts/gsb-swete.sh decide gen 39 4@k3f9 'image (3x): rough breathing' 'Ἁβραάμ'
  ./scripts/gsb-swete.sh done gen 39
"))

(define (die fmt . args)
  (format (current-error-port) "~a: ~?~%" %program fmt args)
  (exit 1))

(define (say fmt . args) (format #t "~?~%" fmt args))

;;; ---------------------------------------------------------------------------
;;; Files
;;; ---------------------------------------------------------------------------

(define (read-file path) (call-with-input-file path get-string-all))

(define (write-file! path text)
  "Write TEXT to PATH via a private temporary file and rename (atomic), and only
if the content changes. Returns #t when written."
  (if (and (file-exists? path) (string=? text (read-file path)))
      #f
      (let ((tmp (format #f "~a.tmp.~a" path (getpid))))
        (call-with-output-file tmp (lambda (p) (display text p)))
        (rename-file tmp path)
        #t)))

(define (tsv-rows path)
  "Data rows (lists of fields) of a TSV file with a header row."
  (if (file-exists? path)
      (map (lambda (l) (string-split l #\tab))
           (filter (negate string-null?) (cdr (string-split (read-file path) #\newline))))
      '()))

(define (mkdir-p dir)
  (unless (file-exists? dir)
    (mkdir-p (dirname dir))
    (catch 'system-error (lambda () (mkdir dir)) (lambda _ #t))))

(define (leaf-number s)
  (or (and (string-match "^[0-9]+$" s) (string->number s))
      (die "leaf '~a' is not a number (see --help)" s)))

;;; Books and leaves

(define (books)
  "Rows of leaves.tsv as alists."
  (map (match-lambda
         ((book vol scan first last step . _)
          `((book . ,book) (volume . ,vol) (scan . ,scan) (first . ,(string->number first))
            (last . ,(string->number last)) (step . ,(string->number step)))))
       (tsv-rows (string-append %root "/leaves.tsv"))))

(define (book-info book)
  (or (find (lambda (b) (string=? (assq-ref b 'book) book)) (books))
      (die "unknown book '~a'. Known: ~a~%  (add a row to ~a/leaves.tsv for a new book)"
           book (string-join (map (lambda (b) (assq-ref b 'book)) (books)) ", ") %root)))

(define (cache-dir)
  (or (getenv "GSB_SWETE_CACHE")
      (string-append (or (getenv "XDG_CACHE_HOME") (string-append (getenv "HOME") "/.cache")) "/gsb-swete")))

(define (leaf-name info leaf) (format #f "v~a-~4,'0d" (assq-ref info 'volume) leaf))
(define (page-dir info) (string-append %root "/pages/" (assq-ref info 'book)))
(define (page-path info leaf) (format #f "~a/~a.txt" (page-dir info) (leaf-name info leaf)))
(define (decisions-path info leaf) (format #f "~a/~a.decisions.tsv" (page-dir info) (leaf-name info leaf)))
(define (scan-file info leaf ext) (format #f "~a/~a/leaf-~4,'0d.~a" (cache-dir) (assq-ref info 'scan) leaf ext))
(define (work-dir info leaf)
  (let ((d (format #f "~a/~a/work/~a-~4,'0d" (cache-dir) (assq-ref info 'scan) (assq-ref info 'book) leaf)))
    (mkdir-p d)
    d))

(define (fetch-hint info leaf)
  (format #f "run ./scripts/gsb-swete-fetch.sh ~a ~a first" (assq-ref info 'volume) leaf))

(define (need-file path info leaf)
  (unless (file-exists? path)
    (die "~a is missing: ~a" path (fetch-hint info leaf)))
  path)

(define (hocr-of info leaf ext)
  (let ((path (scan-file info leaf ext)))
    (and (file-exists? path) (hocr-lines (read-file path)))))

(define (page-size info leaf)
  "Image width and height from the fresh hOCR's ocr_page bbox."
  (let* ((text (read-file (need-file (scan-file info leaf "tess.hocr") info leaf)))
         (m (string-match "ocr_page[^>]*bbox 0 0 ([0-9]+) ([0-9]+)" text)))
    (if m
        (values (string->number (match:substring m 1)) (string->number (match:substring m 2)))
        (die "cannot read the page size from ~a: delete it and ~a" (scan-file info leaf "tess.hocr") (fetch-hint info leaf)))))

(define (page-numbers info)
  "Alist leaf -> printed page from archive.org's page_numbers.json (if fetched)."
  ;; The JSON counts the scan's "Delete" leaves, which /page/nK (our leaf
  ;; numbering) skips: vol. II drops jp2 0510-0511 (blank), so its JSON leaf
  ;; N >= 512 is our leaf N-2.
  (let ((json (format #f "~a/~a/~a_page_numbers.json" (cache-dir) (assq-ref info 'scan) (assq-ref info 'scan)))
        (leaf (lambda (n) (if (and (equal? (assq-ref info 'scan) "oldtestamenting02swet") (>= n 512)) (- n 2) n))))
    (if (file-exists? json)
        (map (lambda (m) (cons (leaf (string->number (match:substring m 1))) (match:substring m 2)))
             (list-matches "\"leafNum\": ([0-9]+),[^}]*\"pageNumber\": \"([^\"]+)\"" (read-file json)))
        '())))

(define (printed-page info leaf) (or (assv-ref (page-numbers info) leaf) "?"))

(define (load-page info leaf)
  (let ((path (page-path info leaf)))
    (unless (file-exists? path)
      (die "~a does not exist: run ./scripts/gsb-swete.sh box ~a ~a first" path (assq-ref info 'book) leaf))
    (parse-page (read-file path))))

(define (page-box info leaf page)
  (match (page-header page "box")
    (((= string->number y0) (= string->number y1) (= string->number x0) (= string->number x1))
     (=> fail)
     (if (and y0 y1 x0 x1) (list y0 y1 x0 x1) (fail)))
    (_ (die "~a has no `# box Y0 Y1 X0 X1` line: run ./scripts/gsb-swete.sh box ~a ~a"
            (page-path info leaf) (assq-ref info 'book) leaf))))

(define (set-header-line text key line)
  "TEXT with its `# KEY ...` line replaced by LINE, or LINE inserted after the
leading comment lines."
  (let* ((ls (string-split text #\newline))
         (key? (lambda (l) (string-prefix? (string-append "# " key " ") (string-append l " ")))))
    (string-join
     (if (any key? ls)
         (map (lambda (l) (if (key? l) line l)) ls)
         (let-values (((head tail) (span (lambda (l) (string-prefix? "#" l)) ls)))
           (append head (list line) tail)))
     "\n")))

(define (main-lines info leaf box)
  "Main-text lines of the fresh OCR (reading B), else archive.org's (A)."
  (let ((b (hocr-of info leaf "tess.hocr")) (a (hocr-of info leaf "ia.hocr")))
    (cond (b (main-text-lines b box))
          (a (main-text-lines a box))
          (else (die "no OCR for leaf ~a: ~a" leaf (fetch-hint info leaf))))))

;;; ffmpeg

(define (ffmpeg . args)
  (unless (zero? (status:exit-val (apply system* "ffmpeg" "-nostdin" "-loglevel" "error" "-y" args)))
    (die "ffmpeg failed (~a): run ./scripts/gsb-swete-fetch.sh doctor" (string-join args " "))))

(define (crop-filter x0 y0 x1 y1 scale)
  (format #f "crop=~a:~a:~a:~a,scale=iw*~a:ih*~a:flags=lanczos" (- x1 x0) (- y1 y0) x0 y0 scale scale))

;;; ---------------------------------------------------------------------------
;;; box, strips, zoom
;;; ---------------------------------------------------------------------------

(define (cmd-box book leaf-s . coords)
  (let* ((info (book-info book)) (leaf (leaf-number leaf-s))
         (img (need-file (scan-file info leaf "jpg") info leaf))
         (path (page-path info leaf)))
    (let-values (((w h) (page-size info leaf)))
      (mkdir-p (page-dir info))
      (unless (file-exists? path)
        (write-file! path (format #f "# ~a leaf ~4,'0d (printed page ~a)~%"
                                  (assq-ref info 'scan) leaf (printed-page info leaf)))
        (say "created ~a" path))
      (let* ((page (parse-page (read-file path)))
             (box (match coords
                    ((y0 y1 x0 x1)
                     (map (lambda (s) (or (string->number s) (die "box values must be numbers: Y0 Y1 X0 X1"))) coords))
                    (() (match (page-header page "box")
                          (#f (or (suggest-box (hocr-of info leaf "tess.hocr") w h)
                                  (die "found no main text on leaf ~a: give the box by hand, Y0 Y1 X0 X1 in page pixels (~ax~a)" leaf w h)))
                          (_ (page-box info leaf page))))
                    (_ (die "box takes BOOK LEAF, optionally followed by all four of Y0 Y1 X0 X1")))))
        (match box
          ((y0 y1 x0 x1)
           (write-file! path (set-header-line (read-file path) "box" (format #f "# box ~a ~a ~a ~a" y0 y1 x0 x1)))
           (let ((preview (string-append (work-dir info leaf) "/box.png")))
             (ffmpeg "-i" img "-vf"
                     (format #f "drawbox=x=~a:y=~a:w=~a:h=~a:color=red@0.8:t=5,scale=1000:-1" x0 y0 (- x1 x0) (- y1 y0))
                     preview)
             (say "box ~a ~a ~a ~a (y0 y1 x0 x1, page ~ax~a) in ~a" y0 y1 x0 x1 w h path)
             (say "preview: ~a" preview)
             (say "Check the red box: all main-text lines inside; running head, margin numbers/sigla and the")
             (say "apparatus outside. To change it: ./scripts/gsb-swete.sh box ~a ~a Y0 Y1 X0 X1" book leaf)
             (say "Main-text lines the OCR finds in it: ~a" (length (main-lines info leaf box))))))))))

(define (cmd-strips book leaf-s)
  (let* ((info (book-info book)) (leaf (leaf-number leaf-s))
         (img (need-file (scan-file info leaf "jpg") info leaf))
         (page (load-page info leaf))
         (box (page-box info leaf page))
         (lines (main-lines info leaf box))
         (dir (work-dir info leaf)))
    (for-each (lambda (f) (when (string-prefix? "strip-" f) (delete-file (string-append dir "/" f))))
              (or (scandir dir) '()))
    (match box
      ((Y0 Y1 X0 X1)
       (let* ((groups (let loop ((ls lines) (acc '()))
                        (if (null? ls) (reverse acc)
                            (let ((n (min 5 (length ls))))
                              (loop (drop ls n) (cons (take ls n) acc))))))
              (n (length groups)))
         (when (zero? n) (die "the OCR finds no main-text lines in the box: check it with ./scripts/gsb-swete.sh box ~a ~a" book leaf))
         ;; Strip k runs from the gap above its first line to the gap below its
         ;; last, plus a margin, so consecutive strips overlap and miss nothing.
         (for-each
          (lambda (g k)
            (let* ((top (if (= k 0) Y0 (quotient (+ (second (last (list-ref groups (- k 1)))) (first (first g))) 2)))
                   (bot (if (= k (- n 1)) Y1 (quotient (+ (second (last g)) (first (first (list-ref groups (+ k 1))))) 2)))
                   (out (format #f "~a/strip-~2,'0d.png" dir (+ k 1))))
              (ffmpeg "-i" img "-vf" (crop-filter (max 0 (- X0 10)) (max 0 (- top 25)) (+ X1 10) (+ bot 25) 1) out)
              (say "~a  lines ~a-~a" out (+ 1 (* 5 k)) (+ (* 5 k) (length g)))))
          groups (iota n))
         (say "~a main-text lines found by OCR. Line numbers are the OCR's; the image is the truth:" (length lines))
         (say "a line the OCR missed still shows in the strips (they overlap), so read every line you see."))))))

(define (cmd-zoom book leaf-s . args)
  (let* ((info (book-info book)) (leaf (leaf-number leaf-s))
         (img (need-file (scan-file info leaf "jpg") info leaf))
         (dir (work-dir info leaf))
         (nums (map (lambda (s) (or (string->number s) (die "zoom arguments must be numbers (see --help)"))) args)))
    (match nums
      ;; One or two numbers: a line. (A guard, not a failure continuation: in
      ;; ice-9 match, calling `fail` returns into this clause, which then ran on.)
      ((? (lambda (ns) (<= 1 (length ns) 2)) (line . scale))
       (let* ((page (load-page info leaf))
              (box (page-box info leaf page))
              (lines (main-lines info leaf box))
              (scale (if (pair? scale) (car scale) 2))
              ;; LINE is the page file's printed line (what collate, decide and
              ;; flag count) once it has text, mapped to the OCR line its words
              ;; align to; before that, the OCR's own line (as strips number them).
              (k (if (null? (page-lines page))
                     (- line 1)
                     (begin
                       (unless (assv line (page-lines page))
                         (die "~a has no printed line ~a" (page-path info leaf) line))
                       (or (ocr-line-of (page-tokens page) (ocr-tokens lines) line)
                           (die "page line ~a matches no OCR line: use the rectangle form X0 Y0 X1 Y1 instead" line))))))
         (unless (< -1 k (length lines))
           (die "line ~a: the OCR finds ~a main-text lines; use the rectangle form X0 Y0 X1 Y1 instead" line (length lines)))
         (match (list-ref lines k)
           ((y0 y1 _)
            (match box
              ((_ _ X0 X1)
               (let* ((third (quotient (- X1 X0) 3))
                      (out (format #f "~a/line-~2,'0d.png" dir line))
                      ;; equal widths (vstack needs them), overlapping by 80 px
                      (piece (lambda (k) (let ((x (max 0 (- (+ X0 (* k third)) 40))))
                                           (format #f "[0]~a[p~a]" (crop-filter x (max 0 (- y0 40)) (+ x third 80) (+ y1 25) scale) k)))))
                 (ffmpeg "-i" img "-filter_complex"
                         (string-append (piece 0) ";" (piece 1) ";" (piece 2) ";"
                                        "[p0][p1][p2]vstack=inputs=3")
                         out)
                 (say "~a  (~a in three overlapping pieces, ~ax)" out
                      (match (assv line (page-lines page))
                        ((_ . text) (format #f "page line ~a = OCR line ~a: ~a" line (+ k 1) text))
                        (#f (format #f "OCR line ~a (the page file has no text yet)" line)))
                      scale))))))))
      ((x0 y0 x1 y1 . scale)
       (let ((out (format #f "~a/zoom-~a-~a.png" dir x0 y0)))
         (ffmpeg "-i" img "-vf" (crop-filter x0 y0 x1 y1 (if (pair? scale) (car scale) 3)) out)
         (say "~a" out)))
      (_ (die "zoom takes BOOK LEAF LINE [SCALE] or BOOK LEAF X0 Y0 X1 Y1 [SCALE]")))))

;;; ---------------------------------------------------------------------------
;;; collate, decide, done
;;; ---------------------------------------------------------------------------

(define %decisions-header "book\tscan\tleaf\tline\treading_a\treading_b\treading_c_first\tchosen\tbasis")

(define (row-basis r)
  (or (assq-ref r 'basis)
      (format #f "TODO zoom: ~a"
              (string-join
               (append (map (lambda (h) (assq-ref '((H1 . "breathing on a capital (OCR misreads rough/smooth)")
                                                    (H2 . "accent before an enclitic")
                                                    (H3 . "acute or grave before a capitalized word"))
                                                  h))
                            (assq-ref r 'hazards))
                       (if (and (eq? (assq-ref r 'class-a) 'R0) (eq? (assq-ref r 'class-b) 'R0))
                           '("no OCR reading at all")
                           (let ((ca (assq-ref r 'class-a)) (cb (assq-ref r 'class-b)))
                             (if (or (memq ca '(OPEN DIA DROP)) (memq cb '(OPEN DIA DROP)))
                                 (list (format #f "A ~a, B ~a" ca cb))
                                 '()))))
               "; "))))

(define (collation info leaf)
  "Collate the leaf: returns (values rows decisions problems) where ROWS are
collate rows each with the matched decision index (or #f, new), DECISIONS the
sidecar rows after adding the new ones, PROBLEMS a list of strings."
  (let* ((page (load-page info leaf))
         (box (page-box info leaf page))
         (a (hocr-of info leaf "ia.hocr"))
         (b (hocr-of info leaf "tess.hocr")))
    (unless (and a b) (die "OCR files for leaf ~a are missing: ~a" leaf (fetch-hint info leaf)))
    (let* ((a-lines (main-text-lines a box)) (b-lines (main-text-lines b box))
           (rows (collate (page-tokens page) (ocr-tokens a-lines) (ocr-tokens b-lines)))
           (old (filter (lambda (d) (>= (length d) 9)) (tsv-rows (decisions-path info leaf))))
           (c-lines (length (page-lines page))))
      (let-values (((matches decisions orphans) (reconcile rows old)))
        (let ((out (map (lambda (r i) (acons 'decision i r)) rows matches))
              (fresh (lambda (r) (list (assq-ref info 'book) (assq-ref info 'scan) (number->string leaf)
                                       (number->string (assq-ref r 'line)) (assq-ref r 'a) (assq-ref r 'b)
                                       (assq-ref r 'c) (assq-ref r 'c) (row-basis r)))))
          ;; DECISIONS holds #f for rows still to be created; fill them in.
          (let ((decisions (map (lambda (d i) (or d (fresh (list-ref rows (list-index (lambda (m) (eqv? m i)) matches)))))
                                decisions (iota (length decisions)))))
            (values out decisions
                    (append
                     (if (= c-lines (length b-lines)) '()
                         (list (format #f "the page file has ~a lines, the OCR finds ~a in the box: a missed or doubled line? (OCR line counts can be off where lines are short)"
                                       c-lines (length b-lines))))
                     (filter-map
                      (lambda (r)
                        (let* ((d (assq-ref r 'decision)) (row (list-ref decisions d)))
                          (and (not (string=? (eighth row) (assq-ref r 'c)))
                               (format #f "row #~a (line ~a): the decision chose ~a but the page now says ~a: fix one of them"
                                       (+ d 1) (assq-ref r 'line) (eighth row) (assq-ref r 'c)))))
                      out)
                     (map (lambda (i)
                            (let ((d (list-ref decisions i)))
                              (format #f "row #~a (line ~a): its reading ~a is no longer on that line (open until settled again): check the page; if the page is right, ./scripts/gsb-swete.sh decide ~a ~a ~a@~a 'image: ...' WORD-ON-THE-PAGE"
                                      (+ i 1) (fourth d) (eighth d) (assq-ref info 'book) leaf (+ i 1) (rows-revision decisions))))
                          ;; A settled row that no OCR disagreement matches any more is
                          ;; normal (the page was corrected, the OCR now agrees); one
                          ;; whose chosen word has left its line is open again.
                          (stale-rows decisions orphans (page-tokens page)))))))))))

(define (stale? problem) (string-contains problem "no longer on that line"))

(define (decisions-text rows)
  (string-append %decisions-header "\n"
                 (string-concatenate (map (lambda (r) (string-append (string-join r "\t") "\n")) rows))))


(define (paragraph-hints info leaf page)
  (indent-hints (main-lines info leaf (page-box info leaf page)) page))

(define (make-sheets info leaf rows decisions)
  "Zoom crops for the rows whose decision is TODO, four per sheet. Returns
((row-number . sheet-label) ...)."
  (let* ((img (scan-file info leaf "jpg"))
         (dir (work-dir info leaf))
         (page (load-page info leaf))
         (box (page-box info leaf page))
         (lines (main-lines info leaf box))
         (todo (filter (lambda (r) (todo? (list-ref decisions (assq-ref r 'decision)))) rows)))
    (for-each (lambda (f) (when (string-prefix? "sheet-" f) (delete-file (string-append dir "/" f))))
              (or (scandir dir) '()))
    (define (rect r)
      ;; Word box (with the next word for an enclitic), else the whole line.
      (let ((w (assq-ref r 'word)) (nw (assq-ref r 'next-word)))
        (cond (w (list (first w) (second w) (third (or nw w)) (max (fourth w) (fourth (or nw w)))))
              ((ocr-line-of (page-tokens page) (ocr-tokens lines) (assq-ref r 'line))
               => (lambda (k) (let ((l (list-ref lines k)))
                                (list (third box) (first l) (fourth box) (second l)))))
              (else #f))))
    ;; Rows with no crop are left out up front, so ffmpeg labels [c0]..[cN-1]
    ;; stay contiguous and each "#i" matches its place on the sheet.
    (let loop ((rs (filter rect todo)) (k 1) (acc '()))
      (if (null? rs)
          (reverse acc)
          (let* ((group (take rs (min 4 (length rs))))
                 (out (format #f "~a/sheet-~2,'0d.png" dir k))
                 (parts
                  (filter-map
                   (lambda (r i)
                     (match (rect r)
                       ((x0 y0 x1 y1)
                        (let* ((cx (quotient (+ x0 x1) 2))
                               (half (max 260 (+ 60 (quotient (- x1 x0) 2))))
                               (cx0 (max 0 (- cx half))) (cy0 (max 0 (- y0 45))))
                          (format #f "[0]crop=~a:~a:~a:~a,drawbox=x=~a:y=~a:w=~a:h=3:color=red@0.7:t=fill,scale=iw*3:ih*3:flags=lanczos,pad=~a:ih+24:0:12:white[c~a]"
                                  (* 2 half) (+ (- y1 y0) 75) cx0 cy0
                                  (- x0 cx0) (+ (- y1 cy0) 6) (- x1 x0)
                                  (* 3 2 (max 260 (+ 60 (quotient (- x1 x0) 2)))) i)))
                       (#f #f)))
                   group (iota (length group)))))
            (if (null? parts)
                (loop (drop rs (length group)) k acc)
                (let* ((n (length parts))
                       ;; vstack needs equal widths: pad all to the widest.
                       (width (* 6 (apply max (map (lambda (r) (match (rect r) ((x0 _ x1 _) (max 260 (+ 60 (quotient (- x1 x0) 2)))) (#f 0))) group))))
                       (parts (map (lambda (p) (regexp-substitute/global #f "pad=[0-9]+:" p 'pre (format #f "pad=~a:" width) 'post)) parts))
                       (labels (map (lambda (i) (format #f "[c~a]" i)) (iota n))))
                  (ffmpeg "-i" img "-filter_complex"
                          (string-append (string-join parts ";")
                                         (if (= n 1) ";[c0]null" (format #f ";~avstack=inputs=~a" (string-concatenate labels) n)))
                          out)
                  (loop (drop rs (length group)) (+ k 1)
                        (append (reverse (filter-map (lambda (r i) (and (rect r) (cons (+ 1 (assq-ref r 'decision))
                                                                                       (format #f "sheet-~2,'0d.png #~a" k (+ i 1)))))
                                                     group (iota (length group))))
                                acc)))))))))

(define (cmd-collate book leaf-s)
  (let* ((info (book-info book)) (leaf (leaf-number leaf-s))
         (page (load-page info leaf)))
    (let-values (((rows decisions problems) (collation info leaf)))
      (when (write-file! (decisions-path info leaf) (decisions-text decisions))
        (say "wrote ~a" (decisions-path info leaf)))
      (let* ((sheets (make-sheets info leaf rows decisions))
             (todo (filter (lambda (r) (todo? (list-ref decisions (assq-ref r 'decision)))) rows)))
        ;; Every TODO decision belongs to a current row (reconcile drops stale
        ;; ones); with the settled rows whose word left its line, this count
        ;; is the one done checks.
        (say "~a tokens differ or need a check; ~a settled, ~a open."
             (length rows) (- (length rows) (length todo)) (+ (count todo? decisions) (count stale? problems)))
        (for-each
         (lambda (r)
           (let ((n (+ 1 (assq-ref r 'decision))))
             (say "#~a L~a ~a c=~a a=~a b=~a  ~a~a" n (assq-ref r 'line) (assq-ref r 'kind)
                  (assq-ref r 'c) (assq-ref r 'a) (assq-ref r 'b)
                  (ninth (list-ref decisions (- n 1)))
                  (match (assv-ref sheets n) (#f "  [no crop: use zoom]") (s (string-append "  -> " s))))))
         todo)
        (when (pair? sheets) (say "zoom sheets in ~a (rows top to bottom; the word is underlined in red)" (work-dir info leaf)))
        (for-each (lambda (p) (say "NOTE ~a" p)) (append problems (paragraph-hints info leaf page)))
        (say "Rows revision ~a. Settle each open row: ./scripts/gsb-swete.sh decide ~a ~a ROWS@~a 'image (3x): ...' [CHOSEN]"
             (rows-revision decisions) book leaf (rows-revision decisions))))))

(define (cmd-decide book leaf-s rows-s basis . chosen)
  (let* ((info (book-info book)) (leaf (leaf-number leaf-s))
         (path (decisions-path info leaf))
         (rows (tsv-rows path))
         (nums+rev (match (string-split rows-s #\@)
                     ((nums rev) (cons nums rev))
                     (_ (die "give ROWS with the revision collate printed, e.g. 3,5@~a: run ./scripts/gsb-swete.sh collate ~a ~a to list the rows"
                             "k3f9" book leaf))))
         (picks (map (lambda (s) (or (string->number s) (die "ROWS must be numbers like 3 or 3,5,9 (then @REV)"))) (string-split (car nums+rev) #\,))))
    (when (null? rows) (die "~a has no rows: run ./scripts/gsb-swete.sh collate ~a ~a first" path book leaf))
    (unless (string=? (cdr nums+rev) (rows-revision rows))
      (die "rows were renumbered by the last collate (revision ~a is not the current one): list them again with ./scripts/gsb-swete.sh collate ~a ~a and use the new numbers and revision"
           (cdr nums+rev) book leaf))
    (when (or (string-prefix? "TODO" basis) (string-any (lambda (c) (memv c '(#\tab #\newline))) basis)
              (string-null? (string-trim basis)))
      (die "BASIS must say what the image shows (no tabs, not TODO), e.g. 'image (3x): rough breathing'"))
    (for-each (lambda (p) (unless (<= 1 p (length rows)) (die "row ~a: ~a has rows 1-~a" p path (length rows)))) picks)
    (let* ((current   ; row number -> the page file's reading now (reading C)
            (if (pair? chosen) '()
                (let-values (((crows decisions problems) (collation info leaf)))
                  (unless (string=? (rows-revision decisions) (rows-revision rows))
                    (die "the page file changed since the last collate: run ./scripts/gsb-swete.sh collate ~a ~a and use the new row numbers and revision" book leaf))
                  (map (lambda (r) (cons (+ 1 (assq-ref r 'decision)) (assq-ref r 'c))) crows))))
           (new (map (lambda (r i)
                       (if (memv i picks)
                           (append (take r 7) (list (match chosen ((c) (string-normalize-nfc c)) (() (or (assv-ref current i) (eighth r))))) (list basis))
                           r))
                     rows (iota (length rows) 1))))
      (write-file! path (decisions-text new))
      (for-each (lambda (p)
                  (let ((r (list-ref new (- p 1))) (old (list-ref rows (- p 1))))
                    (say "#~a L~a chosen=~a  ~a" p (fourth r) (eighth r) (ninth r))
                    (unless (or (todo? old) (equal? (drop old 7) (drop r 7)))
                      (say "   replaced the settled decision: chosen=~a  ~a" (eighth old) (ninth old)))))
                picks)
      (match chosen
        ((c) (let* ((c (string-normalize-nfc c))
                    (lines (delete-duplicates (map (lambda (p) (string->number (fourth (list-ref new (- p 1))))) picks)))
                    (toks (page-tokens (load-page info leaf)))
                    (todo (filter (lambda (l) (not (any (lambda (t) (and (eqv? (second t) l) (string=? (first t) c))) toks))) lines)))
               (if (null? todo)
                   (say "The page already reads ~a there." c)
                   (say "Now make line ~a of ~a read ~a (collate checks they agree)."
                        (string-join (map number->string todo) ",") (page-path info leaf) c))))
        (_ #t)))))

(define (cmd-flag book leaf-s line-s word basis)
  "Log a reading no OCR disagreement covers: damaged or ambiguous print, a
correction found by eye."
  (let* ((info (book-info book)) (leaf (leaf-number leaf-s))
         (page (load-page info leaf))
         (line (or (string->number line-s) (die "LINE must be a number")))
         (path (decisions-path info leaf))
         ;; the word as page-tokens has it: markers and witness marks stripped
         (word (string-delete (lambda (c) (memv c '(#\¶ #\§)))
                              (regexp-substitute/global #f "\\{[^}]*\\}" word 'pre 'post))))
    (unless (assv line (page-lines page)) (die "~a has no printed line ~a" (page-path info leaf) line))
    (unless (any (lambda (t) (and (= (second t) line) (string=? (first t) (string-normalize-nfc word)))) (page-tokens page))
      (die "line ~a of ~a has no word ~a (give the word as on the page, with its punctuation; ¶ § and {...} markers may be left out): ~a"
           line (page-path info leaf) word
           (string-join (filter-map (lambda (t) (and (= (second t) line) (first t))) (page-tokens page)) " ")))
    (when (or (string-prefix? "TODO" basis) (string-any (lambda (c) (memv c '(#\tab #\newline))) (string-append word basis))
              (string-null? (string-trim basis)))
      (die "BASIS must say what the image shows (no tabs, not TODO), e.g. 'ambiguous: ink blot over the accent; read acute'"))
    (let ((rows (append (tsv-rows path)
                        (list (list book (assq-ref info 'scan) (number->string leaf) (number->string line)
                                    "-" "-" (string-normalize-nfc word) (string-normalize-nfc word) basis)))))
      (write-file! path (decisions-text rows))
      (say "logged row #~a in ~a: L~a ~a  ~a" (length rows) path line word basis))))

(define (leaf-problems info leaf)
  "Everything that keeps one leaf from being done, as strings."
  (let* ((page (load-page info leaf))
         (own (book-problems (list (cons leaf page)) #f #f (assq-ref info 'step))))
    (let-values (((rows decisions problems) (collation info leaf)))
      (append
       (map (match-lambda ((l n sev msg) (format #f "~a line ~a: ~a" sev n msg))) own)
       ;; A common verse this leaf shares with another page file (status's
       ;; check across leaves; the own-page check above sees only this leaf).
       (filter-map (match-lambda
                     ((l n sev msg)
                      (and (eq? sev 'fail) (string-contains msg "already at leaf")
                           (not (eq? (= l leaf) (and (string-contains msg (format #f "already at leaf ~a line" leaf)) #t)))
                           (format #f "fail: leaf ~a line ~a: ~a" l n msg))))
                   (book-problems (present-pages info) (assq-ref info 'first) (assq-ref info 'last) (assq-ref info 'step)))
       ;; The same reconciliation collate writes: done never disagrees with it.
       (if (string=? (decisions-text decisions)
                     (let ((p (decisions-path info leaf))) (if (file-exists? p) (read-file p) "")))
           '()
           (list (format #f "fail: ~a is out of date with the page and OCR: run ./scripts/gsb-swete.sh collate ~a ~a"
                         (decisions-path info leaf) (assq-ref info 'book) leaf)))
       (match (count todo? decisions)
         (0 '())
         (n (list (format #f "fail: ~a decision rows still TODO: settle them (collate lists them)" n))))
       (map (lambda (p) (string-append (if (or (string-contains p "chose") (stale? p)) "fail: " "note: ") p)) problems)))))

(define (cmd-done book leaf-s)
  (let* ((info (book-info book)) (leaf (leaf-number leaf-s))
         (problems (leaf-problems info leaf))
         (fails (filter (lambda (p) (not (string-prefix? "note" p))) problems)))
    (for-each (lambda (p) (say "~a" p)) problems)
    (unless (null? fails)
      (die "leaf ~a is not done: fix the lines above and rerun" leaf))
    (let ((path (page-path info leaf)))
      (write-file! path (set-header-line (read-file path) "done"
                                         (format #f "# done ~a ~a" (strftime "%Y-%m-%d" (localtime (current-time))) %method)))
      (say "~a stamped done. Next: ./scripts/gsb-swete.sh status ~a" path book))))

;;; ---------------------------------------------------------------------------
;;; status, merge
;;; ---------------------------------------------------------------------------

(define (present-pages info)
  "((leaf . page) ...) for every page file of the book, by leaf."
  (let ((dir (page-dir info)))
    (if (file-exists? dir)
        (filter-map (lambda (f)
                      (match (string-match "^v[0-9]+-([0-9]+)\\.txt$" f)
                        (#f #f)
                        (m (let ((leaf (string->number (match:substring m 1))))
                             (cons leaf (parse-page (read-file (page-path info leaf))))))))
                    (sort (or (scandir dir) '()) string<?))
        '())))

(define (done? page) (and (page-header page "done") #t))

(define (cmd-status book . range)
  (let* ((info (book-info book))
         (pages (present-pages info))
         (step (assq-ref info 'step))
         (first-leaf (match range ((f l) (leaf-number f)) (_ (assq-ref info 'first))))
         (last-leaf (match range ((f l) (leaf-number l))
                      (_ (or (assq-ref info 'last) (fold max first-leaf (map car pages))))))
         (problems (book-problems pages (assq-ref info 'first) (assq-ref info 'last) step))
         (counts (make-hash-table))
         (numbers (page-numbers info)))
    (say "~a: leaves ~a-~a~a (~a)" book first-leaf last-leaf (if (= step 1) "" (format #f " every ~a" step))
         (assq-ref info 'scan))
    (do ((leaf first-leaf (+ leaf step))) ((> leaf last-leaf))
      (let* ((page (assv-ref pages leaf))
             (mine (filter (lambda (p) (= (first p) leaf)) problems))
             (todo (count todo? (tsv-rows (decisions-path info leaf))))
             (fail? (or (any (lambda (p) (eq? (third p) 'fail)) mine)
                        (and page (done? page) (> todo 0))))
             (state (cond ((not page) "missing")
                          (fail? "FAIL")
                          ((done? page) "done")
                          (else "wip"))))
        (hash-set! counts state (+ 1 (hash-ref counts state 0)))
        (say "~a  p.~4a ~7a~a" (leaf-name info leaf) (or (and page (and=> (page-header page "scan") third)) (assv-ref numbers leaf) "?") state
             (if (> todo 0) (format #f "  ~a TODO decisions" todo) ""))
        (for-each (match-lambda ((l n sev msg) (say "    ~a line ~a: ~a" sev n msg))) mine)))
    (say "~a" (string-join (map (lambda (s) (format #f "~a ~a" (hash-ref counts s 0) s)) '("done" "wip" "FAIL" "missing")) ", "))
    (exit (if (> (hash-ref counts "FAIL" 0) 0) 1 0))))

(define (leaves-text leaves step)
  "33,34,35 -> 33-35; with a STEP other than 1 (Daniel's alternate leaves) a plain list."
  (if (not (= step 1))
   (string-join (map number->string leaves) ",")
   (string-join
   (map (lambda (run) (if (= (length run) 1) (number->string (car run)) (format #f "~a-~a" (last run) (first run))))
        (reverse (fold (lambda (l acc)
                         (match acc
                           (((prev . more) . others) (if (= l (+ prev step))
                                                         (cons (cons l (cons prev more)) others)
                                                         (cons (list l) acc)))
                           (() (list (list l)))))
                       '() leaves)))
   ",")))

(define (nn-of book)
  (or (any (lambda (r) (and (string=? (second r) book) (first r)))
           (tsv-rows "gsb/books.tsv"))
      (die "book '~a' is not in gsb/books.tsv" book)))

(define (versification book)
  "BOOK's rows of versification.tsv (book from to english: Hebrew c:v range in
one chapter, English c:v of its first verse) as (chapter from to english-chapter
english-first) for english-numbering."
  (filter-map
   (match-lambda
     ((b from to english . _)
      (and (string=? b book)
           (match (map (lambda (s) (map string->number (string-split s #\:))) (list from to english))
             ((((? number? c) (? number? f)) ((? number? c2) (? number? t)) ((? number? ec) (? number? ev)))
              (=> fail)
              (if (and (= c c2) (<= f t)) (list c f t ec ev) (fail)))
             (_ (die "~a/versification.tsv: bad row ~a ~a ~a ~a (FROM and TO are c:v in one chapter, ENGLISH is c:v)"
                     %root b from to english)))))
     (row (die "~a/versification.tsv: a row needs 4 columns: ~a" %root (string-join row " "))))
   (tsv-rows (string-append %root "/versification.tsv"))))

(define (cmd-merge)
  (let loop ((infos (books)) (decisions '()) (prov '()))
    (match infos
      (()
       (when (write-file! (string-append %root "/decisions.tsv") (decisions-text decisions))
         (say "wrote ~a/decisions.tsv" %root))
       (when (write-file! (string-append %root "/provenance.tsv")
                          (string-append "book\tchapter\tscan\tleaves\tprinted_pages\tdate\tmethod\n"
                                         (string-concatenate (map (lambda (r) (string-append (string-join r "\t") "\n")) prov))))
         (say "wrote ~a/provenance.tsv" %root)))
      ((info . more)
       (let* ((book (assq-ref info 'book)) (step (assq-ref info 'step))
              (pages (present-pages info))
              ;; The leading run of done pages from the book's first leaf.
              (run (let take ((ps pages) (want (assq-ref info 'first)) (acc '()))
                     (match ps
                       (((leaf . page) . rest)
                        (if (and (= leaf want) (done? page)) (take rest (+ want step) (cons (car ps) acc)) (reverse acc)))
                       (() (reverse acc))))))
         (when (and (pair? pages) (< (length run) (length pages)))
           (say "~a: table stops before leaf ~a (missing or not done); ~a later page files left out"
                book (+ (if (null? run) (- (assq-ref info 'first) step) (car (last run))) step) (- (length pages) (length run))))
         (let*-values (((printed problems) (book-verses run))
                       ((rows) (english-numbering printed (versification book))))
           (unless (null? problems)
             (die "~a: ~a~%  fix the page, then rerun merge" book
                  (match (car problems) ((l n sev msg) (format #f "leaf ~a line ~a: ~a" l n msg)))))
           (let ((keys (map (lambda (r) (take r 2)) rows)))
             (unless (= (length keys) (length (delete-duplicates keys)))
               (die "~a: two rows share a reference after applying ~a/versification.tsv: check its rows for ~a"
                    book %root book)))
           (when (pair? run)
             (let ((out (format #f "~a/~a-~a.tsv" %root (nn-of book) book)))
               (when (write-file! out (string-append "chapter\tverse\ttext\n"
                                                     (string-concatenate (map (lambda (r) (format #f "~a\t~a\t~a~%" (first r) (second r) (third r))) rows))))
                 (say "wrote ~a" out)))))
         (loop more
               (append decisions (append-map (lambda (p) (tsv-rows (decisions-path info (car p)))) run))
               (append prov (provenance info run))))))))

(define (provenance info run)
  "Rows (book chapter scan leaves pages dates methods) per Swete chapter."
  (let* ((by-chapter
          ;; (chapter . leaf) for each chapter with text on each page.
          (let loop ((ps run) (ch #f) (acc '()))
            (match ps
              (() (reverse acc))
              (((leaf . page) . rest)
               (let* ((starts (append-map (lambda (l) (filter-map (match-lambda (('chapter n) n) (_ #f))
                                                                  (line-items (cdr l))))
                                          (page-lines page)))
                      (text-first? (match (page-lines page)
                                     (((_ . l) . _) (not (string-prefix? "{C" l)))
                                     (_ #f)))
                      (chs (append (if (and ch text-first?) (list ch) '()) starts)))
                 (loop rest (if (pair? starts) (last starts) ch)
                       (append (reverse (map (lambda (c) (cons c leaf)) chs)) acc)))))))
         (chapters (delete-duplicates (map car by-chapter))))
    (map (lambda (c)
           (let* ((leaves (delete-duplicates (filter-map (lambda (p) (and (= (car p) c) (cdr p))) by-chapter)))
                  (pages (map (lambda (l) (assv-ref run l)) leaves))
                  (field (lambda (k) (string-join (delete-duplicates (filter-map (lambda (p) (match (page-header p "done") ((d m . _) (if (eq? k 'date) d m)) (_ #f))) pages)) ","))))
             (list (assq-ref info 'book) (number->string c) (assq-ref info 'scan)
                   (leaves-text leaves (assq-ref info 'step))
                   (let ((ns (map (lambda (p) (and=> (and=> (page-header p "scan") third) string->number)) pages)))
                     (if (every identity ns) (leaves-text ns (assq-ref info 'step)) "?"))
                   (field 'date) (field 'method))))
         chapters)))

;;; ---------------------------------------------------------------------------

(define (main args)
  (match (cdr args)
    ((or () ("-h") ("--help") ("help"))
     (usage (if (null? (cdr args)) (current-error-port) (current-output-port)))
     (exit (if (null? (cdr args)) 2 0)))
    (("box" book leaf . coords) (apply cmd-box book leaf coords))
    (("strips" book leaf) (cmd-strips book leaf))
    (("collate" book leaf) (cmd-collate book leaf))
    (("decide" book leaf rows basis . chosen) (if (<= (length chosen) 1) (apply cmd-decide book leaf rows basis chosen)
                                                  (die "decide takes BOOK LEAF ROWS@REV BASIS [CHOSEN]; quote BASIS")))
    (("flag" book leaf line word basis) (cmd-flag book leaf line word basis))
    (("zoom" book leaf . more) (apply cmd-zoom book leaf more))
    (("done" book leaf) (cmd-done book leaf))
    (("status" book . range) (if (memv (length range) '(0 2)) (apply cmd-status book range)
                                 (die "status takes BOOK, or BOOK FIRST LAST")))
    (("merge") (cmd-merge))
    ((cmd . _)
     (format (current-error-port) "~a: unknown command or wrong arguments: ~a~%~%" %program (string-join (cdr args) " "))
     (usage (current-error-port))
     (exit 2))))

(main (command-line))
