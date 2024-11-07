(ns fodok-crawler.core)

(require '[clj-http.client :as client]
         '[clojure.xml :as xml]
         '[clojure.zip :as zip]
         '[clojure.data.csv :as csv]
         '[clojure.java.io :as io])

(defn zip-str [s]
  (zip/xml-zip 
      (xml/parse (java.io.ByteArrayInputStream. (.getBytes s)))))

(def response (client/get "https://fodok.jku.at/fodok/forschungseinheit_typo3.xsql?FE_ID=348&xml-stylesheet=none"))


(def content (let [data (xml/parse 
          (java.io.ByteArrayInputStream. (.getBytes (get response :body))))]
(get-in data [:content 1 :content 0 :content])))


(defn get_publications [content_map]
  (let [_,_,content] (:content content_map)
    content))


(defn get_specific_contents [content type_of_content]
  (get (first (filter #(= (get %1 :tag) type_of_content) content)) :content)
  )




(def talks (get_specific_contents content :VORTRAGSTYPEN))
(def publications (get_specific_contents content :PUBLIKATIONSTYPEN))
(def research_projcets (get_specific_contents content :FORSCHUNGSPROJEKTTYPEN))

(let [tags (xml/element :foo {:foo-attr "foo value"}
             (xml/element :bar {:bar-attr "bar value"}
               (xml/element :baz {} "The baz value")))]
  (with-open [out-file (io/writer "foo.xml")]
    (xml/emit tags out-file)))
