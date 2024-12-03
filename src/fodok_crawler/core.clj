(ns fodok-crawler.core
  (:gen-class))

(require '[clj-http.client :as client]
         '[clojure.data.csv :as csv]
         '[clojure.java.io :as io]
         '[fodok-crawler.util :as util]
         '[fodok-crawler.doi :as doi]
         '[clojure.java.shell :as shell])

(defn ds [row tag-mapping]
  (let [content (:content row)]
    (into {}
          (map (fn [[key tag]]
                 [key (util/filter_for_tag tag content)])
               tag-mapping))))

;; Example usage:
(defn destructure_publication [publication_row]
  (ds publication_row
      {:title    :TITEL
       :authors  :AUTOREN_ZITAT
       :year     :ERSCHEINUNGSJAHR
       :citation :ZITAT_DE
       :id       :PUB_ID}))

(defn destructure_talk [talk_row]
  (ds talk_row
      {:title    :TITEL
       :date     :DATUM
       :id       :V_ID
       :person   :PERSONEN_ZITAT
       :citation :ZITAT_DE}))

(defn destructure_reasearch_project [rp_row]
  (ds rp_row
      {:name   :BEZEICHNUNG
       :person :PERSONEN_ZITAT
       :start  :ANFANG
       :end    :ENDE}))

(defn destructure_scs [scs_row]
  (ds scs_row
      {:name :TITEL
       :person :PERSONEN_ZITAT
       :start :ANFANG
       :end :ENDE}))

(defn destructure_type [type_of_content, content]
  (let [destructure_fun (case type_of_content
                          :VORTRAGSTYPEN destructure_talk
                          :PUBLIKATIONSTYPEN destructure_publication
                          :FORSCHUNGSPROJEKTTYPEN destructure_reasearch_project
                          :SCSTYPEN destructure_scs)
        type_title (-> content :content first :content first)
        rows (-> content :content (nth 2) :content)]
    (map #(-> % destructure_fun
              (assoc :type type_title)) rows)))

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

(def content (future
               (-> "https://fodok.jku.at/fodok/forschungseinheit_typo3.xsql?FE_ID=348&xml-stylesheet=none"
                   client/get
                   util/parse_to_xml)))

(def talks (future (->>
                    content
                    deref
                    (get_specific_contents :VORTRAGSTYPEN))))

(def publications (future (->> content
                               deref
                               (get_specific_contents :PUBLIKATIONSTYPEN)
                               doi/map_doi_to_publications)))

(def research_projcets (future (->>
                                content
                                deref
                                (get_specific_contents :FORSCHUNGSPROJEKTTYPEN))))

(def scs (future (->>
                  content
                  deref
                  (get_specific_contents :SCSTYPEN))))

(defn -main [& _args]
  (write-csv "data/publications.csv" (deref publications) [:authors :title :year :type :citation :doi])
  (write-csv "data/talks.csv" (deref talks) [:title :date :type :id :person :citation])
  (write-csv "data/research_projcets.csv" (deref research_projcets) [:name :type :start :end])
  (write-csv "data/scs.csv" (deref scs) [:name :type :start :end :person])
  (println (shell/sh "ruby" "src/latextify/latextify.rb")))
