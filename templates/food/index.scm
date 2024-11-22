(use-modules (scripts lib html))

(render-template "Ursinia - Food"
                 `((header
                     (div (@ (id "header"))
                          (span (@ (id "header-sitemap"))
                                (a (@ (id "header-sitemap-link")
                                      (href "https://sitemap.ursinia.net"))
                                   #\↤ " " (code "sitemap")))))
                   (h1
                     (a (@ (id "title")
                           (href "#title")
                           (class "list-item-internal-link"))
                        "Recipes"))
                   (div (ul ,(map-in-order (lambda (link)
                                             (let ([id (car link)]
                                                   [text (cdr link)])
                                               `(li (a (@ (id ,id)
                                                          (href ,(format #f "/~a" id)))
                                                       ,text))))
                                           '(["banana-bread" . "Banana Bread"]
                                             ["beef-chili" . "Beef Chili"]
                                             ["biscuits" . "Biscuits"]
                                             ["candy-cane-cookies" . "Candy Cane Cookies"]
                                             ["cashew-cheese" . "Cashew Cheese"]
                                             ["chanterelle-sauce" . "Chanterelle Sauce"]
                                             ["chikn-alfredo" . "Chi'k'n Alfredo"]
                                             ["chocolate-syrup" . "Chocolate Syrup"]
                                             ["cookie-dough-balls" . "Cookie Dough Balls"]
                                             ["french-onion-soup" . "French Onion Soup"]
                                             ["frozen-custard" . "Frozen Custard"]
                                             ["gingerbread-cookies" . "Gingerbread Cookies"]
                                             ["instant-pot-spaghetti" . "Instant Pot Spaghetti"]
                                             ["lasagna" . "Lasagna"]
                                             ["macadamia-nut-cookies" . "Macadamia Nut Cookies"]
                                             ["mapo-tofu" . "Mapo Tofu"]
                                             ["pbj-thumbprint-cookies" . "Peanut Butter and Jelly Thumbprint Cookies"]
                                             ["pumpkin-pie" . "Pumpkin Pie"]
                                             ["roasted-artichoke" . "Roasted Artichoke"]
                                             ["shepherds-pie" . "Shepherd's Pie"]
                                             ["spicy-fried-chicken-tofu-sandwich" . "Spicy Fried Chicken Tofu Sandwich"]
                                             ["spinach-artichoke-dip" . "Spinach Artichoke Dip"]
                                             ["st-lucia-buns" . "St. Lucia Buns"]
                                             ["sugar-cookies" . "Sugar Cookies"]))))))

