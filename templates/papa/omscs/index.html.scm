(use-modules (scripts lib html))

(render-template "OMSCS"
                 `((header
                     (div (@ (id "header"))
                          (span (@ (id "header-sitemap"))
                                (a (@ (id "header-back-link")
                                      (href "https://papa.ursinia.net"))
                                   #\↤ " " (code "papa")))))
                   (h1
                     (a (@ (id "title")
                           (href "#title")
                           (class "list-item-internal-link"))
                        "OMSCS"))
                  (div
                       (h2 "Important links:")
                       (ul
                         ,(map-in-order (lambda (link)
                                          (let ([href (car link)]
                                                [text (cdr link)])
                                            `(li (a (@ (href ,href))
                                                    ,text))))
                                        '(["https://omscscourseplanner.com" . "Course Planner"]))))
                   (div
                     (h2 (a (@ (id "gios") (href "#gios")
                               (class "list-item-internal-link"))
                            "[GIOS] Graduate Introduction to Operating Systems"))
                     (div
                       (h3 (a (@ (id "gios-links")
                           (href "#gios-links")
                           (class "list-item-internal-link"))
                        "[GIOS] Important links:"))
                       (ul
                         ,(map-in-order (lambda (link)
                                          (let ([href (car link)]
                                                [text (cdr link)])
                                            `(li (a (@ (href ,href))
                                                    ,text))))
                                        '(["https://beej.us/guide/bgnet" . "Beej's Guide to Network Programming - Using Internet Sockets"]
                                          ["https://teapowered.dev/assets/gios-mt.pdf" . "Midterm study guide"])))))))
