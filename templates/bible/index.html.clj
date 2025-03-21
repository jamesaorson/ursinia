(ns templates.bible.index.html
  (:require '[hiccup2.core :as h]))

(defn html-page-template [title head body lang]
  [[:doctype "html"]
   [:html {:lang lang}
    (into [:head [:title title]] head)
    (into [:body] body)]])

(defn html-page
  "Returns the HTML string."
  [title body & {:keys [head lang]
                 :or {head [] lang "en"}}]
  (let [sxml (when body
               (html-page-template title head body lang))]
    (h/html sxml)))

(defn render-template
  "Renders the HTML page and prints it to stdout."
  [title body & {:keys [head]
                 :or {head [[:meta {:charset "utf-8"}]
                            [:meta {:name "viewport"
                                    :content "width=device-width, initial-scale=1"}]
                            [:link {:rel "icon"
                                    :type "image/x-icon"
                                    :href "/shared/favicons/favicon.ico"}]
                            [:link {:rel "stylesheet"
                                    :href "/shared/styles/openword-theme.css"}]
                            [:link {:rel "stylesheet"
                                    :href "/styles/main.css"}]]}}]
  (let [html-str (html-page title body :head head)]
    (println html-str)))


(defn -main [& _args]
  (render-template "Ursinia - Bible"
                   (h/html
                    [:div#header
                     [:span#header-sitemap
                      [:a#header-back-link {:href "/sitemap"} "↤ " [:code "sitemap"]]]
                     [:h1 [:a#title.list-item-internal-link {:href "#title"} "Bible"]]
                     [:div
                      [:p "In Ursinia, we hold the Bible to be the standard by which we organize and guide our lives. We believe the Bible to be the infallible Word of God, intended to be interpreted by those He has blessed with His Holy Spirit. Naturally, we like to read the Bible then. Any bible-related content we want to host will go here, from open theological discussions, to custom bible reading plans, We are here to help you in reading and knowing God's word."]]
                     [:div
                      [:ul
                       (map (fn [link]
                                       (let [href (first link)
                                             text (second link)]
                                         [:li [:a {:href href} text]]))
                                     [["versions" "Full Text Bibles"]
                                      ["reading-plans" "Bible Reading Plans"]
                                      ["christian-resources" "Other Christian Resources"]])]]])))
