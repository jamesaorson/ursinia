(use-modules (scripts lib html))

(render-template "Ursinia - Home"
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
                        "Home"))
                   (div
                     (h2 "What is going on these days?")
                     (p "The New Year has rolled around and we wanted to create some predictions for this coming year. It is a fun one, what with a US presidential election, a pandemic on the books, and multiple looming viruses."
                        (h3 "Predictions")
                        (ul
                          (li "Mama will be pregnant by end-of-year")
                          (li "My work stock will breach $100 a share")))
                     (h2 "Are you lost? Check out the " (a (@ (href "https://sitemap.ursinia.net"))
                                                           "Sitemap")))))

