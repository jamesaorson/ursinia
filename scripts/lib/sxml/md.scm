;; Copyright (C) 2026

(define-module (scripts lib sxml md)
	#:use-module (scripts lib sxml html)
	#:use-module (ice-9 rdelim)
	#:use-module (srfi srfi-13)
	#:export (md->html))

(define (starts-with? s prefix)
	(and (>= (string-length s) (string-length prefix))
			 (string=? (substring s 0 (string-length prefix)) prefix)))

(define (blank-line? s)
	(string-null? (string-trim-both s)))

(define (read-lines port)
	(let loop ((lines '()))
		(let ((line (read-line port 'concat)))
			(if (eof-object? line)
					(reverse lines)
					(loop (cons line lines))))))

(define (drop-frontmatter lines)
	(if (and (pair? lines) (string=? (car lines) "---"))
			(let skip ((rest (cdr lines)))
				(cond
				 ((null? rest) '())
				 ((string=? (car rest) "---") (cdr rest))
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
							(list (string->symbol (string-append "h" (number->string i))) text))
						#f))))

(define (unordered-list-item-text line)
	(if (and (>= (string-length line) 2)
					 (let ((c (string-ref line 0)))
						 (or (char=? c #\-) (char=? c #\*) (char=? c #\+)))
					 (char=? (string-ref line 1) #\space))
			(string-trim (substring line 2 (string-length line)))
			#f))

(define (ordered-list-item-text line)
	(let scan-digits ((i 0))
		(if (and (< i (string-length line)) (char-numeric? (string-ref line i)))
				(scan-digits (+ i 1))
				(if (and (> i 0)
								 (< (+ i 1) (string-length line))
								 (char=? (string-ref line i) #\.)
								 (char=? (string-ref line (+ i 1)) #\space))
						(string-trim (substring line (+ i 2) (string-length line)))
						#f))))

(define (list-node type items)
	(cons type (map (lambda (item) (list 'li item)) items)))

(define (parse-markdown lines)
	(let loop ((rest lines)
						 (blocks '())
						 (paragraph-lines '())
						 (list-type #f)
						 (list-items '())
						 (in-code? #f)
						 (code-lines '()))
		(define (flush-paragraph blocks paragraph-lines)
			(if (null? paragraph-lines)
					blocks
					(cons (list 'p (string-join (reverse paragraph-lines) " ")) blocks)))
		(define (flush-list blocks list-type list-items)
			(if (or (not list-type) (null? list-items))
					blocks
					(cons (list-node list-type (reverse list-items)) blocks)))
		(define (flush-code blocks code-lines)
			(if (null? code-lines)
					blocks
					(cons (list 'pre (list 'code (string-join (reverse code-lines) "\n")))
								blocks)))

		(if (null? rest)
				(reverse
				 (flush-code
					(flush-list
					 (flush-paragraph blocks paragraph-lines)
					 list-type list-items)
					code-lines))
				(let* ((line (car rest))
							 (trimmed (string-trim-both line))
							 (heading (and (not in-code?) (heading-line->node trimmed)))
							 (ul-item (and (not in-code?) (unordered-list-item-text trimmed)))
							 (ol-item (and (not in-code?) (ordered-list-item-text trimmed)))
							 (is-fence (starts-with? trimmed "```")))
					(cond
					 (in-code?
						(if is-fence
								(loop (cdr rest)
											(flush-code blocks code-lines)
											paragraph-lines
											list-type
											list-items
											#f
											'())
								(loop (cdr rest)
											blocks
											paragraph-lines
											list-type
											list-items
											#t
											(cons line code-lines))))
					 (is-fence
						(loop (cdr rest)
									(flush-list
									 (flush-paragraph blocks paragraph-lines)
									 list-type
									 list-items)
									'()
									#f
									'()
									#t
									'()))
					 ((blank-line? trimmed)
						(loop (cdr rest)
									(flush-list
									 (flush-paragraph blocks paragraph-lines)
									 list-type
									 list-items)
									'()
									#f
									'()
									#f
									code-lines))
					 (heading
						(loop (cdr rest)
									(cons heading
												(flush-list
												 (flush-paragraph blocks paragraph-lines)
												 list-type
												 list-items))
									'()
									#f
									'()
									#f
									code-lines))
					 (ul-item
						(if (eq? list-type 'ul)
								(loop (cdr rest)
											blocks
											'()
											'ul
											(cons ul-item list-items)
											#f
											code-lines)
								(loop (cdr rest)
											(flush-list
											 (flush-paragraph blocks paragraph-lines)
											 list-type
											 list-items)
											'()
											'ul
											(list ul-item)
											#f
											code-lines)))
					 (ol-item
						(if (eq? list-type 'ol)
								(loop (cdr rest)
											blocks
											'()
											'ol
											(cons ol-item list-items)
											#f
											code-lines)
								(loop (cdr rest)
											(flush-list
											 (flush-paragraph blocks paragraph-lines)
											 list-type
											 list-items)
											'()
											'ol
											(list ol-item)
											#f
											code-lines)))
					 (else
						(loop (cdr rest)
									(flush-list blocks list-type list-items)
									(cons trimmed paragraph-lines)
									#f
									'()
									#f
									code-lines)))))))

(define* (md->html input-port #:optional (output-port (current-output-port)))
	"Read markdown from INPUT-PORT, skip YAML-style frontmatter, and write HTML to OUTPUT-PORT."
	(let* ((lines (read-lines input-port))
				 (content-lines (drop-frontmatter lines))
				 (nodes (parse-markdown content-lines)))
		(sxml->html nodes output-port)))
