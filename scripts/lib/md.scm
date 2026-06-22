;; Copyright (C) 2026

(define-module (scripts lib md)
	#:use-module (scripts lib sxml html)
	#:use-module (ice-9 rdelim)
	#:use-module (ice-9 match)
	#:use-module (srfi srfi-11)
	#:use-module (srfi srfi-13)
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
				 (let ((key (string-trim-right (substring line 0 colon-pos)))
							 (val (string-trim (substring line (+ colon-pos 1)))))
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
						(let ((text (string-trim (substring line (+ i 1) (string-length line)))))
							(cons (string->symbol (string-append "h" (number->string i)))
										(parse-inline text)))
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

(define (parse-markdown lines)
	(let loop ((rest lines)
						 (blocks '())
						 (paragraph-lines '())
						 (in-code? #f)
						 (code-lines '()))
		(define (flush-paragraph blocks paragraph-lines)
			(if (null? paragraph-lines)
					blocks
					(cons (cons 'p (parse-inline (string-join (reverse paragraph-lines) " ")))
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

(define (text->id text)
	"Convert text to a URL-friendly ID (lowercase, spaces to hyphens)."
	(string-downcase
	 (string-map
	  (lambda (c)
	   (if (char-set-contains? char-set:whitespace c)
		   #\-
		   c))
	  text)))

(define (add-heading-anchors node)
	"Recursively process nodes to add anchor links to heading tags (h1-h6)."
	(match node
	 (((? (lambda (tag) (memq tag '(h1 h2 h3 h4 h5 h6))) tag) content ...)
	  (let* ((text (text-from-sxml `(,tag ,@content)))
		 (id (text->id text)))
	   `(,tag (a (@ (id ,id) (href ,(string-append "#" id)) (class "list-item-internal-link"))
		    ,@content))))
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
			(frontmatter-title? #f)
			(extra-body-prefix '()))
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
										 nodes))
				 (processed-nodes (if add-heading-anchors? (add-heading-anchors body-nodes) body-nodes)))
		(if full-page?
				(let ((page `((doctype html)
							(html (@ (lang "en"))
								(head ,@head)
								(body ,@processed-nodes)))))
					(for-each (lambda (node) (sxml->html node output-port)) page))
				(sxml->html processed-nodes output-port))))
