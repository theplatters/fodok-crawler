(ns fodok-crawler.core
  (:gen-class))

(require '[clj-http.client :as client]
         '[clojure.xml :as xml]
         '[clojure.data.csv :as csv]
         '[clojure.java.io :as io])

(defn parse_to_xml [response]
  (-> response
      :body
      .getBytes
      java.io.ByteArrayInputStream.
      xml/parse
      (get-in [:content 1 :content 0 :content])))

(defn filter_for_tag [tag content]
  (->> content
       (filter #(= (:tag %) tag))
       first
       :content
       first))

(defn destructure_publication [publication_row]
  (let [content (:content publication_row)]
    {:title (filter_for_tag :TITEL content)
     :authors (filter_for_tag :AUTOREN_ZITAT content)
     :year (filter_for_tag :ERSCHEINUNGSJAHR content)
     :citation (filter_for_tag :ZITAT_DE content)
     :id (filter_for_tag :PUB_ID content)}))

(defn destructure_talk [talk_row]
  (let [content (:content talk_row)]
    {:title (filter_for_tag :TITEL content)
     :date (filter_for_tag :DATUM content)}))

(defn destructure_reasearch_project [rp_row]
  (let [content (:content rp_row)]
    {:name (filter_for_tag :BEZEICHNUNG content)}))

(defn destructure_type [type_of_content, content]
  (let [destructure_fun (case type_of_content
                          :VORTRAGSTYPEN destructure_talk
                          :PUBLIKATIONSTYPEN destructure_publication
                          :FORSCHUNGSPROJEKTTYPEN destructure_reasearch_project)
        type_title (-> content :content first :content first)
        rows (-> content :content (nth 2) :content)]
    (map #(assoc (destructure_fun %1) :type type_title) rows)))

(defn write-csv [path row-data columns]
  (let [headers (map name columns)
        rows (mapv #(mapv % columns) row-data)]
    (with-open [file (io/writer path)]
      (csv/write-csv file (cons headers rows)))))

(defn destructure_types [type_of_content content]
  (map #(destructure_type type_of_content %) content))

(defn get_specific_contents [type_of_content content]
  (->> content
       (filter #(= (:tag %) type_of_content))
       first
       :content
       (destructure_types type_of_content)
       flatten))

(def content
  (-> "https://fodok.jku.at/fodok/forschungseinheit_typo3.xsql?FE_ID=348&xml-stylesheet=none"
      client/get
      parse_to_xml))

(def talks (future (get_specific_contents :VORTRAGSTYPEN content)))

(def publications (future (get_specific_contents :PUBLIKATIONSTYPEN content)))

(def research_projcets (future (get_specific_contents :FORSCHUNGSPROJEKTTYPEN content)))

(defn -main [& args]
  (write-csv "publications.csv" (deref publications) [:authors :title :year :publication_type :citation])
  (write-csv "talks.csv" (deref talks) [:title :date])
  (write-csv "research_projcets.csv" (deref research_projcets) [:name]))
