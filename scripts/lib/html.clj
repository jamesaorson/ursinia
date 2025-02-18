(ns scripts.lib.html
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
