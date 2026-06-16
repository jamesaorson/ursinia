(use-modules (scripts lib html)
             (ice-9 ftw))

(render-template "Ursinia - Bible - Scripture Readings" "scripture readings"
                 `((header
                     (div (@ (id "header"))
                          (span (@ (id "header-back"))
                                (a (@ (id "header-back-link")
                                      (href "/bible"))
                                   #\↤ " " (code "bible")))))
                   (h1
                     (a (@ (id "title")
                           (href "#title")
                           (class "list-item-internal-link"))
                        "Scripture Readings"))
                   (div (ul ,(map-in-order (lambda (link)
                                             (let ([href (car link)]
                                                   [text (cdr link)])
                                               `(li (a (@ (href ,href))
                                                       ,text))))
                                           '(["/bible/versions" . "Full Text Bibles"]
                                             ["/bible/reading-plans" . "Bible Reading Plans"]
                                             ["/bible/christian-resources" . "Other Christian Resources"]))))))

