(use-modules (scripts lib html))

(render-template "Ursinia - Todo"
                 `((header
                     (div (@ (id "header"))
                          (span (@ (id "header-sitemap"))
                                (a (@ (id "header-back-link")
                                      (href "https://sitemap.ursinia.net"))
                                   #\↤ " " (code "sitemap")))))
                   (div
                     (h2 (@ (id "nov-17-2024"))
                         (a (@ (href "#nov-17-2024"))
                            "November 17, 2024"))
                     (h3 (@ (id "nov-17-2024-papa")
                            (class "papa"))
                         (a (@ (href "#nov-17-2024-papa"))
                            "Papa Tasks"))
                     (ul (@ (class "todo-list"))
                         (li "Sabbath")))))

