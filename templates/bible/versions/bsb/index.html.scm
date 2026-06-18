(use-modules (scripts lib html)
             (ice-9 rdelim))

(define (text->id text)
  (string-downcase
   (string-map (lambda (c) (if (char=? c #\space) #\- c)) text)))

(define (bsb-book-name ref)
  ;; ref is like "Genesis 1:1" or "1 Samuel 3:4" — extract book name
  ;; by finding the last colon, then the space before the chapter number
  (let loop-colon ((i (- (string-length ref) 1)))
    (cond
     ((< i 0) #f)
     ((char=? (string-ref ref i) #\:)
      (let loop-space ((j (- i 1)))
        (cond
         ((< j 0) #f)
         ((char=? (string-ref ref j) #\space) (substring ref 0 j))
         (else (loop-space (- j 1))))))
     (else (loop-colon (- i 1))))))

(define (book-heading book)
  (let ((id (text->id book)))
    `(h2 (a (@ (id ,id) (href ,(string-append "#" id))) ,book))))

(define (read-bsb-nodes filename)
  (with-input-from-file filename
    (lambda ()
      (read-line) ; copyright line 1
      (read-line) ; copyright line 2
      (read-line) ; "Verse\tBerean Standard Bible" header
      (let loop ((line (read-line))
                 (current-book #f)
                 (nodes '()))
        (if (eof-object? line)
            (reverse nodes)
            (let* ((tab-pos (string-index line #\tab))
                   (ref (and tab-pos (string-trim-both (substring line 0 tab-pos))))
                   (book (and ref (not (string=? ref "Verse")) (bsb-book-name ref))))
              (if (and book (not (equal? book current-book)))
                  (loop (read-line) book
                        (cons (string-append line "\n")
                              (cons (book-heading book) nodes)))
                  (loop (read-line) current-book
                        (cons (string-append line "\n") nodes)))))))))

(render-template "Ursinia - BSB" "bible"
  `((header
      (div (@ (id "header"))
           (span (@ (id "header-bible-versions"))
                 (a (@ (id "header-bible-versions-link")
                        (href "/bible/versions/"))
                    ,(string #\x21a4) " " (code "versions")))))
    (h1 (a (@ (id "title") (href "#full-text")) "BSB"))
    (div (@ (id "resources"))
         (a (@ (href "#resources")) "Self Hosted (downloads a file)")
         (ul
           (li (a (@ (href "/assets/bible/data/versions/bsb.txt")) "BSB - Source"))
           (li (a (@ (href "/assets/bible/data/versions/bsb.pdf")) "BSB - PDF (linked)"))
           (li (a (@ (href "/assets/bible/data/versions/bsb-book.pdf")) "BSB - PDF (book-style, no links)"))))
    (div (@ (id "full-text"))
         (pre ,@(read-bsb-nodes "assets/bible/data/versions/bsb.txt")))))
