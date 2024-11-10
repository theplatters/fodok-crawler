(ns fodok-crawler.doi
  (:require
   [clj-http.client :as client]
   [fodok-crawler.util :as util]))

(defn- url [id]
  (format "https://fodok.jku.at/fodok/publikation.xsql?PUB_ID=%s&xml-stylesheet=none" id))

(defn- get_publication_doi [publication]
  (let [{:keys [id]} publication]
    (->> id
         url
         client/get
         util/parse_to_xml
         (util/filter_for_tag :DOI))))

(defn map_doi_to_publications [publications]
  (map (fn [publication]
         (assoc publication :doi (get_publication_doi publication))) publications))

