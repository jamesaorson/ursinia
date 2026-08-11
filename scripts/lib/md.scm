;; Copyright (C) 2026

(define-module (scripts lib md)
	#:use-module (scripts lib sxml html)
	#:use-module (scripts lib text)
	#:use-module (scripts lib bible)
	#:use-module (ice-9 rdelim)
	#:use-module (ice-9 match)
	#:use-module (srfi srfi-1)
	#:use-module (srfi srfi-11)
	#:use-module (srfi srfi-13)
	#:re-export (text->id)
	#:export (md->html
	          parse-frontmatter
	          read-frontmatter))

(define (starts-with? s prefix)
	(and (>= (string-length s) (string-length prefix))
			 (string=? (substring s 0 (string-length prefix)) prefix)))

(define (starts-with-at? s index prefix)
	(let ((prefix-len (string-length prefix))
				(s-len (string-length s)))
		(and (<= (+ index prefix-len) s-len)
				 (string=? (substring s index (+ index prefix-len)) prefix))))

(define (blank-line? s)
	(string-null? (string-trim-both s)))

(define (read-lines port)
	(let loop ((lines '()))
		(let ((line (read-line port 'concat)))
			(if (eof-object? line)
					(reverse lines)
					(loop (cons line lines))))))

(define (parse-frontmatter-line line)
	"Parse a single 'key: value' YAML line into a (key . value) pair, or #f."
	(let ((colon-pos (string-index line #\:)))
		(and colon-pos
				 (> colon-pos 0)
				 (let* ((key (string-trim-right (substring line 0 colon-pos)))
							  (raw (string-trim (substring line (+ colon-pos 1))))
							 (len (string-length raw))
							 ;; Strip surrounding YAML double-quotes if present
							 (val (if (and (>= len 2)
													 (char=? (string-ref raw 0) #\")
													 (char=? (string-ref raw (- len 1)) #\"))
											 (substring raw 1 (- len 1))
											 raw)))
					 (cons (string->symbol key) val)))))

(define (parse-frontmatter lines)
	"Parse a list of lines that may begin with YAML frontmatter delimited by ---.
 Returns an alist of (symbol . string) pairs, or '() if no frontmatter is present."
	(if (and (pair? lines) (string=? (string-trim-right (car lines)) "---"))
			(let loop ((rest (cdr lines)) (acc '()))
				(cond
				 ((null? rest) (reverse acc))
				 ((string=? (string-trim-right (car rest)) "---") (reverse acc))
				 (else
					(let ((pair (parse-frontmatter-line (string-trim-right (car rest)))))
						(loop (cdr rest) (if pair (cons pair acc) acc))))))
			'()))

(define (read-frontmatter port)
	"Read lines from PORT and return parsed frontmatter as an alist."
	(parse-frontmatter (read-lines port)))

(define (drop-frontmatter lines)
	(if (and (pair? lines) (string=? (string-trim-right (car lines)) "---"))
			(let skip ((rest (cdr lines)))
				(cond
				 ((null? rest) '())
				 ((string=? (string-trim-right (car rest)) "---") (cdr rest))
				 (else (skip (cdr rest)))))
			lines))

(define (heading-line->node line)
	(let loop ((i 0))
		(if (and (< i (string-length line)) (char=? (string-ref line i) #\#))
				(loop (+ i 1))
				(if (and (> i 0)
								 (<= i 6)
								 (< i (string-length line))
								 (char=? (string-ref line i) #\space))
						(let ((raw (string-trim (substring line (+ i 1) (string-length line))))
									(tag (string->symbol (string-append "h" (number->string i)))))
							(let-values (((text id) (split-trailing-anchor raw)))
								(if id
										(cons tag (cons `(@ (id ,id)) (parse-inline text)))
										(cons tag (parse-inline text)))))
						#f))))

(define (parse-inline-link-at text i)
	(if (not (starts-with-at? text i "["))
			#f
			(let* ((len (string-length text))
						 (label-end (string-index text #\] (+ i 1))))
				(if (or (not label-end)
							(>= (+ label-end 2) len)
							(not (char=? (string-ref text (+ label-end 1)) #\()))
					#f
					(let ((href-end (string-index text #\) (+ label-end 2))))
						(if (not href-end)
								#f
								(let ((label (substring text (+ i 1) label-end))
											(href (substring text (+ label-end 2) href-end)))
									(list (+ href-end 1)
											(cons 'a
													(cons (list '@ (list 'href href))
																(parse-inline label)))))))))))

(define (parse-inline-image-at text i)
	(if (not (starts-with-at? text i "!["))
			#f
			(let* ((len (string-length text))
						 (label-end (string-index text #\] (+ i 2))))
				(if (or (not label-end)
							(>= (+ label-end 2) len)
							(not (char=? (string-ref text (+ label-end 1)) #\()))
						#f
						(let ((href-end (string-index text #\) (+ label-end 2))))
							(if (not href-end)
									#f
									(let ((alt (substring text (+ i 2) label-end))
												(src (substring text (+ label-end 2) href-end)))
										(list (+ href-end 1)
												`(img (@ (src ,src) (alt ,alt)))))))))))

(define (parse-inline-delimited-at text i delimiter tag)
	(let ((delim-len (string-length delimiter)))
		(if (not (starts-with-at? text i delimiter))
				#f
				(let ((end (string-contains text delimiter (+ i delim-len))))
					(if (or (not end)
							(= end (+ i delim-len)))
							#f
							(let ((inner (substring text (+ i delim-len) end)))
								(list (+ end delim-len)
										(cons tag (parse-inline inner)))))))))

(define (parse-inline text)
	(let ((len (string-length text)))
		(define (flush-text start end nodes)
			(if (= start end)
					nodes
					(cons (substring text start end) nodes)))

		(let loop ((i 0)
						 (plain-start 0)
						 (nodes '()))
			(if (>= i len)
					(reverse (flush-text plain-start len nodes))
					(let* ((image-match (parse-inline-image-at text i))
								 (link-match (parse-inline-link-at text i))
								 (strong-asterisk (parse-inline-delimited-at text i "**" 'strong))
								 (strong-underscore (parse-inline-delimited-at text i "__" 'strong))
								 (em-asterisk (parse-inline-delimited-at text i "*" 'em))
								 (em-underscore (parse-inline-delimited-at text i "_" 'em))
								 (match (or image-match
													link-match
													strong-asterisk
													strong-underscore
													em-asterisk
													em-underscore)))
						(if match
								(let ((next-i (car match))
											(node (cadr match)))
									(loop next-i
												next-i
												(cons node (flush-text plain-start i nodes))))
								(loop (+ i 1) plain-start nodes)))))))
(define (line-indent line)
	"Count leading spaces in LINE."
	(let loop ((i 0))
		(if (and (< i (string-length line))
					 (char=? (string-ref line i) #\space))
				(loop (+ i 1))
				i)))

(define (list-marker-at line indent)
	"If LINE has a list marker at column INDENT, return (type . item-text), else #f."
	(let ((len (string-length line)))
		(and (>= len (+ indent 2))
				 (cond
					((and (memv (string-ref line indent) '(#\- #\* #\+))
							 (char=? (string-ref line (+ indent 1)) #\space))
					 (cons 'ul (string-trim-both (substring line (+ indent 2)))))
					(else
					 (let num ((i indent))
						 (cond
							((>= i len) #f)
							((char-numeric? (string-ref line i)) (num (+ i 1)))
							((and (> i indent)
									 (char=? (string-ref line i) #\.)
									 (< (+ i 1) len)
									 (char=? (string-ref line (+ i 1)) #\space))
							 (cons 'ol (string-trim-both (substring line (+ i 2)))))
							(else #f))))))))

(define (collect-list-block lines base-indent)
	"Consume lines belonging to a list starting at BASE-INDENT (no blank lines, indent >= base).
 Returns two values: collected lines and remaining lines."
	(let loop ((rest lines) (acc '()))
		(if (null? rest)
				(values (reverse acc) '())
				(let* ((line (car rest))
							 (trimmed (string-trim-both line)))
					(cond
					 ((blank-line? trimmed) (values (reverse acc) rest))
					 ((< (line-indent line) base-indent) (values (reverse acc) rest))
					 (else (loop (cdr rest) (cons line acc))))))))

(define (parse-list-block lines base-indent)
	"Recursively parse a list block at BASE-INDENT. Returns an SXML (ul/ol (li ...) ...) or #f."
	(let loop ((rest lines)
						 (list-type #f)
						 (items '())
						 (cur-text #f)
						 (sub-acc '()))
		(define (build-item)
			(and cur-text
					 (let* ((sub-lines (reverse sub-acc))
									(sub-node (and (not (null? sub-lines))
															 (parse-list-block
																sub-lines
																(apply min (map line-indent sub-lines))))))
						 (if sub-node
								 `(li ,@(parse-inline cur-text) ,sub-node)
								 `(li ,@(parse-inline cur-text))))))
		(if (null? rest)
				(let* ((item (build-item))
							 (all (if item (reverse (cons item items)) (reverse items))))
					(and list-type (pair? all) (cons list-type all)))
				(let* ((line (car rest))
							 (indent (line-indent line))
							 (marker (list-marker-at line base-indent)))
					(cond
					 (marker
						(let ((item (build-item)))
							(loop (cdr rest)
										(or list-type (car marker))
										(if item (cons item items) items)
										(cdr marker)
										'())))
					 ((> indent base-indent)
						;; Route to sub-acc if: line has a list marker at its indent (sub-item),
						;; or we're already collecting sub-items (continuation of a sub-item).
						;; Otherwise it's a continuation of the current item's text.
						(if (or (list-marker-at line indent) (not (null? sub-acc)))
								(loop (cdr rest) list-type items cur-text (cons line sub-acc))
								(loop (cdr rest) list-type items
											(if cur-text
													(string-append cur-text " " (string-trim-both line))
													(string-trim-both line))
											sub-acc)))
					 (else
						(loop (cdr rest) list-type items cur-text sub-acc)))))))

(define (anchor-id-char? c)
	"True if C is allowed inside a {#id} anchor marker."
	(not (or (char-set-contains? char-set:whitespace c)
					 (char=? c #\{)
					 (char=? c #\}))))

(define (split-trailing-anchor text)
	"Split a trailing {#id} anchor marker off the end of TEXT.
Returns two values: TEXT with the marker removed (and trailing space trimmed)
and the id string. If TEXT does not end in a well-formed marker, returns TEXT
unchanged and #f, so ordinary content containing braces is left alone."
	(let ((len (string-length text)))
		(if (or (= len 0)
						(not (char=? (string-ref text (- len 1)) #\})))
				(values text #f)
				(let ((open (string-rindex text #\{)))
					(if (or (not open)
									(not (starts-with-at? text open "{#"))
									(>= (+ open 2) (- len 1)))
							(values text #f)
							(let ((id (substring text (+ open 2) (- len 1))))
								(if (string-every anchor-id-char? id)
										(values (string-trim-right (substring text 0 open)) id)
										(values text #f))))))))

(define (paragraph->node text)
	"Build a (p ...) node from paragraph TEXT, honoring a trailing {#id} anchor."
	(let-values (((body id) (split-trailing-anchor text)))
		(if id
				(cons 'p (cons `(@ (id ,id)) (parse-inline body)))
				(cons 'p (parse-inline body)))))

(define (parse-markdown lines)
	(let loop ((rest lines)
						 (blocks '())
						 (paragraph-lines '())
						 (in-code? #f)
						 (code-lines '()))
		(define (flush-paragraph blocks paragraph-lines)
			(if (null? paragraph-lines)
					blocks
					(cons (paragraph->node (string-join (reverse paragraph-lines) " "))
							blocks)))
		(define (flush-code blocks code-lines)
			(if (null? code-lines)
					blocks
					(cons (list 'pre (list 'code (string-join (reverse code-lines) "\n")))
								blocks)))

		(if (null? rest)
				(reverse
				 (flush-code
					(flush-paragraph blocks paragraph-lines)
					code-lines))
				(let* ((line (car rest))
							 (trimmed (string-trim-both line))
							 (heading (and (not in-code?) (heading-line->node trimmed)))
							 (is-list-start (and (not in-code?) (list-marker-at line 0)))
							 (is-fence (starts-with? trimmed "```")))
					(cond
					 (in-code?
						(if is-fence
								(loop (cdr rest)
											(flush-code blocks code-lines)
											paragraph-lines
											#f
											'())
								(loop (cdr rest)
											blocks
											paragraph-lines
											#t
											(cons line code-lines))))
					 (is-fence
						(loop (cdr rest)
									(flush-paragraph blocks paragraph-lines)
									'()
									#t
									'()))
					 ((blank-line? trimmed)
						(loop (cdr rest)
									(flush-paragraph blocks paragraph-lines)
									'()
									#f
									code-lines))
					 (heading
						(loop (cdr rest)
									(cons heading (flush-paragraph blocks paragraph-lines))
									'()
									#f
									code-lines))
					 (is-list-start
						(let-values (((list-lines remaining) (collect-list-block rest 0)))
							(let ((node (parse-list-block list-lines 0)))
								(loop remaining
											(if node
													(cons node (flush-paragraph blocks paragraph-lines))
													(flush-paragraph blocks paragraph-lines))
											'()
											#f
											code-lines))))
					 (else
						(loop (cdr rest)
									blocks
									(cons trimmed paragraph-lines)
									#f
									code-lines)))))))
(define (text-from-sxml node)
	"Extract all text content from an SXML node, recursively."
	(cond
	 ((string? node) node)
	 ((pair? node)
	  (string-concatenate (map text-from-sxml (cdr node))))
	 (else "")))

;;; ---------------------------------------------------------------------------
;;; Scripture reference linking
;;;
;;; Turns bare references in prose ("Exodus 6:7", "Genesis 1:1-3") into links to
;;; the full-text Bible pages. This runs over the parsed tree rather than the
;;; raw markdown, so existing links, code spans and fenced blocks are already
;;; separate nodes and are left alone for free.
;;; ---------------------------------------------------------------------------

(define %scripture-base-url "/bible/versions/bsb/text/")

(define %scripture-book-aliases
	;; Spellings that appear in prose but are not the canonical display name.
	'(("Psalms" . "Psalm")
	  ("Song of Songs" . "Song of Solomon")))

(define %scripture-books
	;; (name . slug), longest name first so "1 John" wins over "John" and
	;; "Song of Solomon" is never truncated to "Song".
	(sort
	 (append
	  (map (lambda (book) (cons (book-display-name book) (book-slug book)))
			 bible-books)
	  (filter-map
	   (lambda (alias)
		 (let ((book (book-by-display-name (cdr alias))))
		   (and book (cons (car alias) (book-slug book)))))
	   %scripture-book-aliases))
	 (lambda (a b) (> (string-length (car a)) (string-length (car b))))))

(define (word-char? c)
	(or (char-alphabetic? c) (char-numeric? c)))

(define (range-separator? c)
	(or (char=? c #\-) (char=? c #\x2013)))

(define (scan-digits text i)
	"Return two values: the integer of the digit run at I (or #f) and its end."
	(let loop ((j i))
		(if (and (< j (string-length text))
				 (char-numeric? (string-ref text j)))
			(loop (+ j 1))
			(if (= j i)
				(values #f i)
				(values (string->number (substring text i j)) j)))))

(define (match-book-at text i)
	"Return two values: the slug of a book name starting at I (or #f) and its end."
	(let loop ((entries %scripture-books))
		(if (null? entries)
			(values #f i)
			(let* ((entry (car entries))
				   (name (car entry))
				   (end (+ i (string-length name))))
				(if (and (starts-with-at? text i name)
						 (or (>= end (string-length text))
							 (not (word-char? (string-ref text end)))))
					(values (cdr entry) end)
					(loop (cdr entries)))))))

(define (scripture-link label anchor)
	`(a (@ (href ,(string-append %scripture-base-url "#" anchor))) ,label))

(define (chapter-anchor slug chapter)
	(string-append slug "-" (number->string chapter)))

(define (verse-anchor slug chapter verse)
	(string-append slug "-" (number->string chapter) "-" (number->string verse)))

(define (match-reference-at text i)
	"Try to read a scripture reference starting at I.
Returns two values: a list of SXML nodes for it (or #f) and the index just past
the match. Both ends of a range become their own link, so either end of
\"Genesis 1:1-3\" can be followed to the verse it names."
	(let-values (((slug book-end) (match-book-at text i)))
		(if (not slug)
			(values #f i)
			;; The book name must be followed by a single space and a chapter.
			(let ((sep-end (let loop ((j book-end))
							 (if (and (< j (string-length text))
									  (char=? (string-ref text j) #\space))
								 (loop (+ j 1))
								 j))))
				(if (= sep-end book-end)
					(values #f i)
					(let-values (((chapter chapter-end) (scan-digits text sep-end)))
						(if (not chapter)
							(values #f i)
							(let* ((book-label (substring text i book-end))
								   (head-label (substring text i chapter-end)))
								(if (and (< chapter-end (string-length text))
										 (char=? (string-ref text chapter-end) #\:))
									;; Book chapter:verse, optionally a range.
									(let-values (((verse verse-end)
												  (scan-digits text (+ chapter-end 1))))
										(if (not verse)
											;; A colon that ends a clause ("since Romans 2:")
											;; rather than introducing a verse -- still a
											;; perfectly good chapter reference.
											(match-chapter-range text i chapter-end slug
																 (chapter-anchor slug chapter)
																 head-label book-label)
											(let ((anchor (verse-anchor slug chapter verse))
												  (label (substring text i verse-end)))
												(match-verse-range text i verse-end slug
																   chapter anchor label))))
									;; Book chapter, optionally a chapter range.
									(let ((anchor (chapter-anchor slug chapter)))
										(match-chapter-range text i chapter-end slug
															 anchor head-label
															 book-label)))))))))))

(define (match-verse-range text start verse-end slug chapter anchor label)
	"Extend a matched verse into a range if one follows, else emit a single link."
	(if (and (< verse-end (string-length text))
			 (range-separator? (string-ref text verse-end)))
		(let-values (((first second-end) (scan-digits text (+ verse-end 1))))
			(if (not first)
				(values (list (scripture-link label anchor)) verse-end)
				(if (and (< second-end (string-length text))
						 (char=? (string-ref text second-end) #\:))
					;; Cross-chapter: "John 15:18-16:4"
					(let-values (((second verse2-end) (scan-digits text (+ second-end 1))))
						(if (not second)
							(values (list (scripture-link label anchor)) verse-end)
							(values (list (scripture-link label anchor)
										  (string (string-ref text verse-end))
										  (scripture-link
										   (substring text (+ verse-end 1) verse2-end)
										   (verse-anchor slug first second)))
									verse2-end)))
					;; Within one chapter: "Genesis 1:1-3"
					(values (list (scripture-link label anchor)
								  (string (string-ref text verse-end))
								  (scripture-link
								   (substring text (+ verse-end 1) second-end)
								   (verse-anchor slug chapter first)))
							second-end))))
		(values (list (scripture-link label anchor)) verse-end)))

(define (match-chapter-range text start chapter-end slug anchor label book-label)
	"Extend a matched chapter into a chapter range if one follows."
	(if (and (< chapter-end (string-length text))
			 (range-separator? (string-ref text chapter-end)))
		(let-values (((second second-end) (scan-digits text (+ chapter-end 1))))
			(if (or (not second)
					;; A verse follows, so this was not a chapter range.
					(and (< second-end (string-length text))
						 (char=? (string-ref text second-end) #\:)))
				(values (list (scripture-link label anchor)) chapter-end)
				(values (list (scripture-link label anchor)
							  (string (string-ref text chapter-end))
							  (scripture-link
							   (substring text (+ chapter-end 1) second-end)
							   (chapter-anchor slug second)))
						second-end)))
		(values (list (scripture-link label anchor)) chapter-end)))

(define (linkify-scripture-string text)
	"Split TEXT into a list of plain strings and scripture link nodes."
	(let ((len (string-length text)))
		(let loop ((i 0) (plain-start 0) (nodes '()))
			(define (flush end)
				(if (= plain-start end)
					nodes
					(cons (substring text plain-start end) nodes)))
			(cond
			 ((>= i len) (reverse (flush len)))
			 ;; Inline code spans are not a node type in this renderer -- backticks
			 ;; survive as literal text -- so skip over them here instead.
			 ((char=? (string-ref text i) #\`)
			  (let ((close (string-index text #\` (+ i 1))))
				(if close
					(loop (+ close 1) plain-start nodes)
					(loop (+ i 1) plain-start nodes))))
			 ((not (or (= i 0) (not (word-char? (string-ref text (- i 1))))))
			  (loop (+ i 1) plain-start nodes))
			 (else
			  (let-values (((matched end) (match-reference-at text i)))
				(if matched
					(loop end end (append (reverse matched) (flush i)))
					(loop (+ i 1) plain-start nodes))))))))

(define %scripture-opaque-tags
	;; Nodes whose contents must never be touched: attribute lists (their values
	;; are URLs, not prose), existing links (nesting an <a> is invalid), code, raw
	;; passthrough, and headings (add-heading-anchors wraps those in an <a>
	;; afterwards, which would nest too).
	'(@ a code pre script style raw doctype h1 h2 h3 h4 h5 h6))

(define (linkify-scripture-node node)
	"Return a list of nodes replacing NODE, linking any scripture references."
	(match node
	 ((? string? text) (linkify-scripture-string text))
	 (((? symbol? tag) rest ...)
	  (if (memq tag %scripture-opaque-tags)
		  (list node)
		  (list (cons tag (append-map linkify-scripture-node rest)))))
	 ((items ...) (list (append-map linkify-scripture-node items)))
	 (else (list node))))

(define (linkify-scripture nodes)
	(append-map linkify-scripture-node nodes))

(define (attribute-node? node)
	"True if NODE is an SXML attribute list, e.g. (@ (id \"x\"))."
	(and (pair? node) (eq? '@ (car node))))

(define (explicit-heading-id content)
	"Return the id set by a {#id} marker on a heading, or #f when absent."
	(and (pair? content)
			 (attribute-node? (car content))
			 (let ((pair (assq 'id (cdr (car content)))))
				 (and pair (cadr pair)))))

(define (contains-link? node)
	"True if NODE contains an anchor element anywhere inside it."
	(match node
	 (('a rest ...) #t)
	 ((? string?) #f)
	 (((? symbol?) rest ...) (any contains-link? rest))
	 ((items ...) (any contains-link? items))
	 (else #f)))

(define (add-heading-anchors node)
	"Recursively process nodes to add anchor links to heading tags (h1-h6).
A heading carrying an explicit {#id} keeps that id; otherwise the id is derived
from the heading text. A heading that already contains a link carries its id on
the heading element instead, since nesting an <a> inside an <a> is invalid."
	(match node
	 (((? (lambda (tag) (memq tag '(h1 h2 h3 h4 h5 h6))) tag) content ...)
	  (let* ((explicit (explicit-heading-id content))
				 (body (if (and (pair? content) (attribute-node? (car content)))
									 (cdr content)
									 content))
				 (id (or explicit (text->id (text-from-sxml `(,tag ,@body))))))
	   (if (any contains-link? body)
		   `(,tag (@ (id ,id)) ,@body)
		   `(,tag (a (@ (id ,id) (href ,(string-append "#" id)) (class "list-item-internal-link"))
			    ,@body)))))
	 ((items ...)
	  (map add-heading-anchors items))
	 (else node)))

(define* (md->html input-port #:optional (output-port (current-output-port)) (full-page? #f)
	#:key (head `((meta (@ (charset "UTF-8")))
							(meta (@ (name "viewport") (content "width=device-width, initial-scale=1")))
							(link (@ (rel "stylesheet")
									 (href "/shared/styles/openword-theme.css")))
							(title "Page")))
			(add-heading-anchors? #t)
			(scripture-links? #t)
			(frontmatter-title? #f)
			(extra-body-prefix '())
			(extra-body-suffix '()))
	"Read markdown from INPUT-PORT, skip YAML-style frontmatter, and write HTML to OUTPUT-PORT.
If FULL-PAGE? is true, wrap in a complete HTML document structure with DOCTYPE, head, and body.
HEAD is a list of SXML elements to include in the head tag.
If ADD-HEADING-ANCHORS? is true (default), wrap heading tags with clickable anchor links.
If FRONTMATTER-TITLE? is true, prepend an h1 from the frontmatter 'title' field.
EXTRA-BODY-PREFIX is a list of SXML nodes prepended before the content (e.g. a backlink header)."
	(let* ((lines (read-lines input-port))
				 (fm (parse-frontmatter lines))
				 (content-lines (drop-frontmatter lines))
				 (nodes (parse-markdown content-lines))
				 (title-node
					(and frontmatter-title?
							 (assq-ref fm 'title)
							 `(h1 ,(assq-ref fm 'title))))
				 (body-nodes (append
										 extra-body-prefix
										 (if title-node (list title-node) '())
										 nodes
										 extra-body-suffix))
				 ;; A page opts out with "scripture-links: false" in its frontmatter --
				 ;; the generated Bible pages do, since linking scripture to itself
				 ;; would add tens of thousands of self-references.
				 (link-scripture? (and scripture-links?
															 (not (equal? (assq-ref fm 'scripture-links) "false"))))
				 (linked-nodes (if link-scripture? (linkify-scripture body-nodes) body-nodes))
				 (processed-nodes (if add-heading-anchors? (add-heading-anchors linked-nodes) linked-nodes)))
		(if full-page?
				(let ((page `((doctype html)
							(html (@ (lang "en"))
								(head ,@head)
								(body ,@processed-nodes)))))
					(for-each (lambda (node) (sxml->html node output-port)) page))
				(sxml->html processed-nodes output-port))))
