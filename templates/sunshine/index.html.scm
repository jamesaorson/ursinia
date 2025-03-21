(use-modules (scripts lib html))

(render-template "Sunshine"
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
                        "Sunshine"))
                   (div
                     (img (@ (src "/shared/images/sunshine-bear.png")
                             (alt "Delightful Baby Bear in Magical Meadow: A more delightful and enchanting baby bear in a lush, magical meadow. The scene is brighter and more colorful, with a greater variety of wildflowers and vibrant butterflies. The baby bear is fluffier, with sparkling, more expressive eyes, capturing a sense of wonder and playfulness. The meadow radiates with an almost fairy-tale-like charm under a brighter, sunnier sky."))))))

