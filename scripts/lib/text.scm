;; Copyright (C) 2026
;;
;; Small text helpers shared by the markdown renderer and the modules that need
;; to agree with it on anchor ids. This lives apart from (scripts lib md) so the
;; Bible book table can derive slugs the renderer's own way without the two
;; modules importing each other.

(define-module (scripts lib text)
  #:use-module (srfi srfi-14)
  #:export (text->id))

(define (text->id text)
  "Convert text to a URL-friendly ID (lowercase, spaces to hyphens)."
  (string-downcase
   (string-map
    (lambda (c)
      (if (char-set-contains? char-set:whitespace c)
          #\-
          c))
    text)))
