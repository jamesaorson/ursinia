(use-modules (scripts lib html))

(render-template "Ursinia - Papa - Todo"
                 `((header
                     (div (@ (id "header"))
                          (span (@ (id "header-back"))
                                (a (@ (id "header-back-link")
                                      (href "https://papa.ursinia.net"))
                                   #\↤ " " (code "papa")))))
                   (div
                     (section
                        (h2 "Daily Tasks"))
                     (section
                        (h2 "Day to Day - December 2024")
                        (ol (li (div (h3 (a (@ (id "december-05-2024")
                                               (href "#december-05-2024"))
                                            "December 5, 2024"))
                                     (ul
                                        (li (span (input (@ (type "checkbox"))) " Some task 2...")))))
                            (li (div (h3 (a (@ (id "december-04-2024")
                                               (href "#december-04-2024"))
                                            "December 4, 2024"))
                                     (ul
                                        (li (span (input (@ (type "checkbox")
                                                            (checked #t))) " Some task..."))))))))))
