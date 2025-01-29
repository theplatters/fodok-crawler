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

(defn- scs_url [id]
  (format "https://fodok.jku.at/fodok/sc_service.xsql?SCS_ID=%s&xml-stylesheet=none" id))

(defn- get_scs_place [scs]
  (let [{:keys [id]} scs]
    (->> id
         scs_url
         client/get
         util/parse_to_xml
         (util/filter_for_tag :STANDORT))))

(defn map_place_to_scs [scss]
  (map (fn [scs]
         (assoc scs :place (get_scs_place scs))) scss))
