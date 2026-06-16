;; Copyright (C) 2026

(define-module (scripts lib sxml test md)
	#:use-module (scripts lib sxml md)
	#:use-module (ice-9 ftw)
	#:use-module (ice-9 format)
	#:use-module (ice-9 textual-ports)
	#:use-module (srfi srfi-1)
	#:use-module (srfi srfi-13)
	#:export (md/test
						md/regenerate-fixtures))

(define (directory? path)
	(and (file-exists? path)
			 (eq? 'directory (stat:type (stat path)))))

(define (md-file? path)
	(string-suffix? ".md" path))

(define (md->html-fixture-path md-path)
	(string-append (substring md-path 0 (- (string-length md-path) 3)) ".html"))

(define (collect-md-files dir)
	(let* ((entries (scandir dir (lambda (name)
																 (and (not (string=? name "."))
																			(not (string=? name ".."))))))
				 (paths (map (lambda (name) (string-append dir "/" name)) entries)))
		(append-map (lambda (path)
									(cond
									 ((directory? path) (collect-md-files path))
									 ((md-file? path) (list path))
									 (else '())))
								paths)))

(define (render-md-file path)
	(call-with-input-file path
		(lambda (input-port)
			(call-with-output-string
				(lambda (output-port)
					(md->html input-port output-port))))))

(define* (md/test #:optional
													 (root "scripts/lib/sxml/test/md")
													 (output-port (current-output-port)))
	"Render each markdown fixture in ROOT and compare it with its matching .html file.
Returns #t on success and #f if any fixture fails."
	(let* ((md-files (sort (collect-md-files root) string<?))
				 (passed 0)
				 (failed 0))
		(for-each
		 (lambda (md-path)
			 (let* ((html-path (md->html-fixture-path md-path))
							(actual (render-md-file md-path))
							(expected (and (file-exists? html-path)
														 (call-with-input-file html-path get-string-all))))
				 (cond
					((not expected)
					 (set! failed (+ failed 1))
					 (format output-port "FAIL ~a (missing coordinated html fixture ~a)~%"
									 md-path html-path))
					((string=? actual expected)
					 (set! passed (+ passed 1))
					 (format output-port "PASS ~a~%" md-path))
					(else
					 (set! failed (+ failed 1))
					 (format output-port "FAIL ~a (render output differs from ~a)~%"
									 md-path html-path)))))
		 md-files)
		(format output-port "Fixtures: ~d passed, ~d failed~%" passed failed)
		(= failed 0)))

(define* (md/regenerate-fixtures #:optional
																(root "scripts/lib/sxml/test/md")
																(output-port (current-output-port)))
	"Render each markdown fixture in ROOT and overwrite its coordinated .html file."
	(let ((md-files (sort (collect-md-files root) string<?)))
		(for-each
		 (lambda (md-path)
			(let* ((html-path (md->html-fixture-path md-path))
						 (actual (render-md-file md-path)))
				(call-with-output-file html-path
					(lambda (port)
						(display actual port)))
				(format output-port "WROTE ~a~%" html-path)))
		 md-files)
		(format output-port "Regenerated ~d fixture file(s)~%" (length md-files))))

(define (main)
	(let* ((args (cdr (command-line)))
				 (mode (if (pair? args) (car args) "test")))
		(cond
		 ((string=? mode "--regenerate")
			(md/regenerate-fixtures)
			(exit 0))
		 ((string=? mode "test")
			(if (md/test)
					(exit 0)
					(exit 1)))
		 (else
			(format (current-error-port)
						"Unknown mode: ~a (expected: test | --regenerate)~%"
						mode)
			(exit 2)))))

(main)
