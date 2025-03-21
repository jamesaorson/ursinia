(use-modules (scripts lib html))

(render-template "Ursinia - Todo"
                 `((header
                     (div (@ (id "header"))
                          (span (@ (id "header-sitemap"))
                                (a (@ (id "header-back-link")
                                      (href "/sitemap"))
                                   #\↤ " " (code "sitemap")))))
                   (div
                     (h2 (@ (id "renovation"))
                         (a (@ (href "#renovation"))
                            "Undergoing renovation")))))
