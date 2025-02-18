(use-modules (scripts lib html))

(render-template "Ursinia - Bible"
                 `((header
                     (div (@ (id "header"))
                          (span (@ (id "header-sitemap"))
                                (a (@ (id "header-back-link")
                                      (href "https://sitemap.ursinia.net"))
                                   #\↤ " " (code "sitemap")))))
                   (h1
                     (a (@ (id "title")
                           (href "#title")
                           (class "list-item-internal-link"))
                        "Bible"))
                   (div
                     (p
                       "In Ursinia, we hold the Bible to be the standard by which we organize and guide our lives. We believe the Bible to be the infallible Word of God, intended to be interpreted by those He has blessed with His Holy Spirit. Naturally, we like to read the Bible then. Any bible-related content we want to host will go here, from open theological discussions, to custom bible reading plans, We are here to help you in reading and knowing God's word."))
                   (div (ul ,(map-in-order (lambda (link)
                                             (let ([href (car link)]
                                                   [text (cdr link)])
                                               `(li (a (@ (href ,href))
                                                       ,text))))
                                           '(["/versions" . "Full Text Bibles"]
                                             ["/reading-plans" . "Bible Reading Plans"]
                                             ["/christian-resources" . "Other Christian Resources"]))))))

