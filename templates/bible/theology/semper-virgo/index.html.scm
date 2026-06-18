(use-modules (scripts lib content-index))

(let ((script-dir (dirname (car (command-line)))))
	(call-with-input-file (string-append script-dir "/body.md")
		(lambda (body-port)
			(render-section-directory-index "Theology" "bible" "/bible/theology" body-port))))