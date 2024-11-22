(use-modules (scripts lib html))

(render-template "Papa"
                 `((header
                            (div (@ (id "header"))
                                (span (@ (id "header-sitemap"))
                                    (a (@ (id "header-sitemap-link")
                                         (href "https://sitemap.ursinia.net"))
                                        #\↤ " " (code "sitemap")))))
                        (h1
                            (a (@ (id "title")
                                  (href "#title")
                                  (class "list-item-internal-link"))
                               "Papa"))
                        (div
                          (img (@ (src "/shared/images/papa-bear.png")
                                  (alt "Imposing Father Bear in Dramatic Mountain Landscape: An imposing father bear in a more rugged and dramatic mountain landscape. The terrain is harsher, with larger rocks and dramatic cliffs. The bear is mightier, with darker, more defined fur and a more powerful stance. His gaze is intensely protective, surveying the vast landscape under a stormy sky, adding to the wild, untamed nature of the scene."))))
                        (div
                            (h2 "Maybe a " (a (@ (href "/blog"))
                                              "blog"))
                        (div
                            (h2 "Check out " (a (@ (href "/theology"))
                                                "what I believe")))
                        (div
                            (h2 "Interesting Media I have come across:")
                            (ul
                                ,(map-in-order (lambda (link)
                                               (let ([href (car link)]
                                                     [text (cdr link)])
                                                    `(li (a (@ (href ,href))
                                                            ,text))))
                                       '(["/books" . "Books"]
                                         ["/readings" . "Readings"]
                                         ["/links" . "Links"])))))))
