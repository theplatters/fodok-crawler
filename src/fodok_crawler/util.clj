(ns fodok-crawler.util
  (:require
   [clojure.data.csv :as csv]
   [clojure.java.io :as io]
   [clojure.xml :as xml]))

(defn parse_to_xml [response]
  (-> response
      :body
      .getBytes
      java.io.ByteArrayInputStream.
      xml/parse
      (get-in [:content 1 :content 0 :content])))

(defn filter-for-tag [tag content]
  (->> content
       (filter #(= (:tag %) tag))
       first
       :content
       first))

(defn ds [row tag-mapping]
  (let [content (:content row)]
    (into {}
          (map (fn [[key tag]]
                 [key (filter-for-tag tag content)])
               tag-mapping))))

(defn write-csv [path row-data columns]
  (let [headers (map name columns)
        rows (mapv #(mapv % columns) row-data)]
    (with-open [file (io/writer path)]
      (csv/write-csv file (cons headers rows)))))
