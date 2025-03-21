(use-modules (scripts lib html))

(render-template "Ursinia - Home"
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
                        "Home"))
                   (div
                     (h2 "What is going on these days?")
                     (p "The New Year has rolled around and we wanted to create some predictions for this coming year. It is a fun one, what with a US presidential election, a pandemic on the books, and multiple looming viruses."
                        (h3 "First-Order Predictions (Very high-level events with little effect from us)")
                        (ul
                          (li "The Orsons will have a beautiful home birth in the Spring")
                          (li "Donald Trump will become president for a second non-consecutive term"))
                        (h3 "Second-Order Predictions (High-level events with effect from us)")
                        (ul (li (em "Under Construction")))
                        (h3 "Third-Order Predictions (Events with direct effect from us)")
                        (ul (li (em "Under Construction"))))
                     (h2 "Are you lost? Check out the " (a (@ (href "/sitemap"))
                                                           "Sitemap")))))

