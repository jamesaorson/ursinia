(use-modules (scripts lib html))

(render-template "Papa"
                 `((header
                     (div (@ (id "header"))
                          (span (@ (id "header-sitemap"))
                                (a (@ (id "header-back-link")
                                      (href "/sitemap"))
                                   #\↤ " " (code "sitemap")))))
                   (h1
                     (a (@ (id "title")
                           (href "#title")
                           (class "list-item-internal-link"))
                        "Papa"))
                   (div
                     (h2 (a (@ (href "./todo")
                               (class "list-item-internal-link"))
                            "Todo tracker")))
                   (div
                     (img (@ (src "/shared/images/papa-bear.png")
                             (height 200)
                             (alt "Imposing Father Bear in Dramatic Mountain Landscape: An imposing father bear in a more rugged and dramatic mountain landscape. The terrain is harsher, with larger rocks and dramatic cliffs. The bear is mightier, with darker, more defined fur and a more powerful stance. His gaze is intensely protective, surveying the vast landscape under a stormy sky, adding to the wild, untamed nature of the scene."))))
                   (div
                     (h3 "My " (a (@ (href "./blog"))
                                       "blog"))
                     (h3 "My " (a (@ (href "./devlog"))
                                       "devlog"))
                     (div
                       (h3 "Check out " (a (@ (href "./theology"))
                                           "what I believe")))
                     (div
                       (h3 "My library of content:")
                       (ul
                         ,(map-in-order (lambda (link)
                                          (let ([href (car link)]
                                                [text (cdr link)])
                                            `(li (a (@ (href ,href))
                                                    ,text))))
                                        '(["./omscs" . "Computer Science Master's"]
                                          ["./readings" . "Reading Library"]
                                         )))))))
