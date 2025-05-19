(use-modules (scripts lib html))

(render-template "Ursinia - Charter"
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
                        "Charter"))
                   (div
                     (div
                       (h3 "Maintain Order")
                       (p
                         "In life, there is a choice between order and chaos at most moments. God is the true being of order ("
                         (a (@ (href "/bible/versions/bsb/#1-corinthians"))
                            "1 Corinthians 14:33")
                         "), and His will is the only certain course for orderly action ("
                         (a (@ (href "/bible/versions/bsb/#john"))
                            "John 14:6")
                         "). Therefore, consult the Lord in all you do ("
                         (a (@ (href "/bible/versions/bsb/#proverbs"))
                            "Proverbs 3:5-6")
                         "), listening to the groans of the spirit ("
                         (a (@ (href "/bible/versions/bsb/#romans"))
                            "Romans 8:26")
                         "). As order is counter cultural, we are to be unashamed of the Gospel of Christ our Lord and God ("
                         (a (@ (href "/bible/versions/bsb#romans"))
                            "Romans 1:16")
                         ").")
                       (h3 "Through marriage")
                       (p
                         (a (@ (href "/papa"))
                            "Papa's")
                         " marriage to "
                         (a (@ (href "/mama"))
                            "Mama")
                         " demonstrates the profound mystery of Christ's love of the church ("
                         (a (@ (href "/bible/versions/bsb#ephesians"))
                            "Ephesians 5:31-32")
                         "). All that we do can be seen as a reflection of Christ and His love for the church. It is by this marriage that the Orson family was founded and continues to orient itself. Through this marriage, God continues to bless us with children, and may our quiver be full to the Lord's desire ("
                         (a (@ (href "/bible/versions/bsb#psalms"))
                            "Psalm 127:3-5")
                         ").")
                       (h3 "In Christ")
                       (p
                         "As we live, let our focus and effort be for Christ and His kingdom ("
                         (a (@ (href "/bible/versions/bsb#philippians"))
                            "Philippians 1:21-24")
                         "), and treat our lives as forfeit to Christ who redeemed us ("
                         (a (@ (href "/bible/versions/bsb#matthews"))
                            "Matthew 16:25")
                         "), not by our own works, but by the work of the Lord ("
                         (a (@ (href "/bible/versions/bsb#ephesians"))
                            "Ephesians 2:8-10")
                         ")."))
                     (div
                       (h2 "Where are we going?")
                       (h3 "Our Trajectory")
                       (p
                         "We are continually called to grow where we are planted ("
                         (a (@ (href "/bible/versions/bsb/#1-corinthians"))
                            "1 Corinthians 7:20-24")
                         "). God is the one who will uproot and plant us wherever His mission may be for our family. We are strangers in a strange land ("
                         (a (@ (href "/bible/versions/bsb#exodus"))
                            "Exodus 2:22")
                         ", "
                         (a (@ (href "/bible/versions/bsb#psalms"))
                            "Psalm 137:4")
                         ", "
                         (a (@ (href "/bible/versions/bsb#acts"))
                            "Acts 7:6")
                         "), with our hearts set upon eternity with Christ on the new Earth ("
                         (a (@ (href "/bible/versions/bsb#revelation"))
                            "Revelation 21:1-4")
                         ").")
                       (h3 "Our Calling")

                       (p
                         "We are to make disciples of all nations ("
                         (a (@ (href "/bible/versions/bsb#matthew"))
                            "Matthew 28:17-20")
                         "), and raise up children who are faithful to and love the Lord ("
                         (a (@ (href "/bible/versions/bsb#ephesians"))
                            "Ephesians 6:1-4")
                         "), not making our children bitter to their inheritance found in Christ alone ("
                         (a (@ (href "/bible/versions/bsb#colossians"))
                            "Colossians 3:18-24")
                         ", "
                         (a (@ (href "/bible/versions/bsb#ephesians"))
                            "Ephesians 1:11")
                         ", "
                         (a (@ (href "/bible/versions/bsb#hebrews"))
                            "Hebrews 9:14-15")
                         "). For it is God the Father who draws us to Christ, while we were wholly dead He gave us life ("
                         (a (@ (href "/bible/versions/bsb#john"))
                            "John 6:43-51")
                         ", "
                         (a (@ (href "/bible/versions/bsb#ephesians"))
                            "Ephesians 2:1-7")
                         ").")))

                   (div (@ (class "family-photoframe"))
                        (div
                          (a (@ (href "/papa"))
                             (img (@ (width "30%")
                                     (src "/shared/images/papa-bear.png")
                                     (alt "Imposing Father Bear in Dramatic Mountain Landscape: An imposing father bear in a more rugged and dramatic mountain landscape. The terrain is harsher, with larger rocks and dramatic cliffs. The bear is mightier, with darker, more defined fur and a more powerful stance. His gaze is intensely protective, surveying the vast landscape under a stormy sky, adding to the wild, untamed nature of the scene.")))))
                        (div
                          (span
                            (a (@ (href "/mama"))
                               (img (@ (width "20%")
                                       (src "/shared/images/mama-bear.png")
                                       (alt "Majestic Mother Bear in Enchanted Forest: A majestic mother bear in a dense, enchanting forest, accentuated with rich green foliage and towering ancient trees. She stands tall and proud, her brown fur more pronounced and her gaze deeply nurturing yet commanding. The forest is alive with vivid colors, and the sunlight creates a more dramatic effect, highlighting her protective aura."))))))
                        (div
                          (span
                            (a (@ (href "/sunshine"))
                               (img (@ (width "15%")
                                       (src "/shared/images/sunshine-bear.png")
                                       (alt "Delightful Baby Bear in Magical Meadow: A more delightful and enchanting baby bear in a lush, magical meadow. The scene is brighter and more colorful, with a greater variety of wildflowers and vibrant butterflies. The baby bear is fluffier, with sparkling, more expressive eyes, capturing a sense of wonder and playfulness. The meadow radiates with an almost fairy-tale-like charm under a brighter, sunnier sky.")))))
                          (span
                            (a (@ (href "/harmony"))
                               (img (@ (width "15%")
                                       (src "/shared/images/harmony-bear.png")
                                       (alt "A serene baby bear representing the concept of 'harmony', depicted in a tranquil forest clearing by a gentle stream. The scene is imbued with the peacefulness of a quick and natural birth. This baby bear is unique, with soft, shimmering fur that seems to radiate light, symbolizing purity and a swift entrance into the world. The bear is emerging from the water, symbolizing the birth pool, surrounded by soft, glowing light and delicate forest flowers, embodying a moment of peaceful harmony in nature.")))))))))

