(ns fodok-crawler.core
  (:gen-class)
  (:require
   [fodok-crawler.util :as util]
   [fodok-crawler.doi :as doi]
   [clj-http.client :as client]
   [clojure.java.shell :as shell]))

;; Example usage:
(defn destructure_publication [publication-row]
  (util/ds publication-row
           {:title    :TITEL
            :authors  :AUTOREN_ZITAT
            :year     :ERSCHEINUNGSJAHR
            :citation :ZITAT_DE
            :id       :PUB_ID}))

(defn destructure-talk [talk_row]
  (util/ds talk_row
           {:title    :TITEL
            :date     :DATUM
            :id       :V_ID
            :person   :PERSONEN_ZITAT
            :citation :ZITAT_DE}))

(defn destructure-reasearch-project [rp_row]
  (util/ds rp_row
           {:name   :BEZEICHNUNG
            :person :PERSONEN_ZITAT
            :start  :ANFANG
            :end    :ENDE}))

(defn destructure-scs [scs_row]
  (util/ds scs_row
           {:name :TITEL
            :person :PERSONEN_ZITAT
            :id :SCS_ID
            :start :ANFANG
            :end :ENDE}))

(defn destructure-type [type_of_content, content]
  (let [destructure_fun (case type_of_content
                          :VORTRAGSTYPEN destructure-talk
                          :PUBLIKATIONSTYPEN destructure_publication
                          :FORSCHUNGSPROJEKTTYPEN destructure-reasearch-project
                          :SCSTYPEN destructure-scs)
        type_title (-> content :content first :content first)
        rows (-> content :content (nth 2) :content)]
    (map #(-> % destructure_fun
              (assoc :type type_title)) rows)))

(defn destructure_types [type_of_content content]
  (map #(destructure-type type_of_content %) content))

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
                               doi/map-doi-to-publications)))

(def research_projcets (future (->>
                                content
                                deref
                                (get_specific_contents :FORSCHUNGSPROJEKTTYPEN))))

(def scs (future (->>
                  content
                  deref
                  (get_specific_contents :SCSTYPEN)
                  doi/map_place_to_scs)))

(doi/map_place_to_scs (deref scs))

(doi/map_additional_data_to_talks (deref talks))
(defn -main [& _args]
  (util/write-csv "data/publications.csv" (deref publications) [:authors :title :year :type :citation :doi])
  (util/write-csv "data/talks.csv" (deref talks) [:title :date :type :id :person :citation :invited-by :original-title :place])
  (util/write-csv "data/research_projcets.csv" (deref research_projcets) [:name :type :start :end])
  (util/write-csv "data/scs.csv" (deref scs) [:name :type :start :end :person :place])
  (println (shell/sh "ruby" "src/latextify/latextify.rb")))
