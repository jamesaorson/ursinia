(define-module (scripts lib html)
  #:export (render-template))

(use-modules (scripts lib sxml html))

(define (html-page-template title head body lang)
  `((doctype "html")
    (html (@ (lang ,lang))
          (head (title ,title)
                ,@head)
          (body ,@body))))

(define* (html-page title body
                    #:key
                    (head '())
                    (lang "en")
                    (sxml (and body (html-page-template title head body lang))))
  (lambda (port)
    (sxml->html sxml port)))

(define* (render-template title body
                           #:key (head '((link (@ (rel "icon")
                                                  (type "image/x-icon")
                                                  (href "/shared/favicons/favicon.ico")))
                                         (link (@ (rel "stylesheet")
                                                  (href "/shared/styles/openword-theme.css")))
                                         (link (@ (rel "stylesheet")
                                                  (href "/styles/main.css")))))
                                (port (current-output-port)))
  (format port
          "~a~%"
          (call-with-output-string (html-page title body #:head head))))