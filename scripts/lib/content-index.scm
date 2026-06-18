(define-module (scripts lib content-index)
  #:use-module (scripts lib html)
  #:use-module (scripts lib dirs)
  #:use-module (ice-9 ftw)
  #:use-module (srfi srfi-13)
  #:export (render-section-directory-index))

(define (script-dir)
  (let ((path (dirname (car (command-line)))))
    (if (string-prefix? "/" path)
        path
        (string-append (getcwd) "/" path))))

(define (path->url path)
  (let ((templates-prefix (string-append (getcwd) "/templates")))
    (if (string-prefix? templates-prefix path)
        (substring path (string-length templates-prefix))
        "/")))

(define (indexed-subdirs dir)
  (filter (lambda (name)
            (file-exists? (string-append dir "/" name "/index.html.scm")))
          (list-subdirs dir)))

(define (md-stem filename)
  (substring filename 0 (- (string-length filename) 3)))

(define (md-file->link-item url-prefix dir filename)
  (let* ((stem (md-stem filename))
         (url (string-append url-prefix "/" stem))
         (title (or (read-frontmatter-title (string-append dir "/" filename)) stem)))
    `(li (a (@ (href ,url)) ,title))))

(define (subdir->link-item url-prefix dir)
  `(li (a (@ (href ,(string-append url-prefix "/" dir)))
          ,(dir-name->display-name dir))))

(define-public (render-section-directory-index section-title pagename section-root-url)
  (let* ((dir (script-dir))
         (url-prefix (path->url dir))
         (is-root? (string=? url-prefix section-root-url))
         (display-name (if is-root?
                           section-title
                           (dir-name->display-name (basename dir))))
         (parent-dir (dirname dir))
         (back-href (if is-root? "/bible" (path->url parent-dir)))
         (back-label (if is-root? "bible" (basename parent-dir)))
         (subdirs (indexed-subdirs dir))
         (md-files (list-md-files dir))
         (items (append (map (lambda (subdir) (subdir->link-item url-prefix subdir)) subdirs)
                        (map (lambda (filename) (md-file->link-item url-prefix dir filename)) md-files))))
    (render-template (string-append "Ursinia - Bible - " display-name) pagename
                     `((header
                         (div (@ (id "header"))
                              (span (@ (id "header-back"))
                                    (a (@ (id "header-back-link")
                                          (href ,back-href))
                                       ,(string #\x21a4) " " (code ,back-label)))))
                       (h1
                         (a (@ (id "title")
                               (href "#title")
                               (class "list-item-internal-link"))
                            ,display-name))
                       (div
                         (ul ,@items))))))