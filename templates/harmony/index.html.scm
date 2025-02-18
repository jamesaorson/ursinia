(use-modules (scripts lib html))

(render-template "Harmony"
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
                        "Harmony"))
                   (div
                     (img (@ (src "/shared/images/harmony-bear.png")
                             (alt "A serene baby bear representing the concept of 'harmony', depicted in a tranquil forest clearing by a gentle stream. The scene is imbued with the peacefulness of a quick and natural birth. This baby bear is unique, with soft, shimmering fur that seems to radiate light, symbolizing purity and a swift entrance into the world. The bear is emerging from the water, symbolizing the birth pool, surrounded by soft, glowing light and delicate forest flowers, embodying a moment of peaceful harmony in nature."))))
                   (div
                     (h3 "April 10th, 2024 - 12:18pm")
                     (p "I was born today, sort of like this!")
                     (img (@ (src "/shared/images/harmony-bear-birth.png")
                             (height 500)
                             (alt "A serene baby bear representing the concept of 'harmony', depicted in a tranquil forest clearing by a gentle stream. The scene is imbued with the peacefulness of a quick and natural birth. This baby bear is unique, with soft, shimmering fur that seems to radiate light, symbolizing purity and a swift entrance into the world. The bear is emerging from the water, symbolizing the birth pool, surrounded by soft, glowing light and delicate forest flowers, embodying a moment of peaceful harmony in nature."))))))

