(ns fodok-crawler.util
  (:require
   [clojure.xml :as xml]))

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
