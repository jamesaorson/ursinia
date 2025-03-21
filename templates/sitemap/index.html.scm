(use-modules (scripts lib html))

(render-template "Sitemap"
                 `((h1 (a (@ (id "title")
                             (class "list-item-internal-link")
                             (href "#title"))
                          "Sitemap"))
                   (div (ul ,(map-in-order (lambda (link)
                                             `(li (a (@ (href ,(format #f "/~a"
                                                                       (string-downcase link))))
                                                     ,link)))
                                           '("Home"
                                             "Charter"
                                             "Bible"
                                             "Todo"
                                             "Food"
                                             "Papa"
                                             "Mama"
                                             "Sunshine"
                                             "Harmony"))))))

