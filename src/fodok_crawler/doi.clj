(ns fodok-crawler.doi
  (:require
   [clj-http.client :as client]
   [fodok-crawler.util :as util]))

(defn- url [id]
  (format "https://fodok.jku.at/fodok/publikation.xsql?PUB_ID=%s&xml-stylesheet=none" id))

(defn- get-publication-doi [publication]
  (let [{:keys [id]} publication]
    (->> id
         url
         client/get
         util/parse_to_xml
         (util/filter-for-tag :DOI))))

(defn map-doi-to-publications [publications]
  (map (fn [publication]
         (assoc publication :doi (get-publication-doi publication))) publications))

(defn- scs-url [id]
  (format "https://fodok.jku.at/fodok/sc_service.xsql?SCS_ID=%s&xml-stylesheet=none" id))

(defn- get-scs-place [scs]
  (let [{:keys [id]} scs]
    (->> id
         scs-url
         client/get
         util/parse_to_xml
         (util/filter-for-tag :STANDORT))))

(defn map_place_to_scs [scss]
  (map (fn [scs]
         (assoc scs :place (get-scs-place scs))) scss))

(defn- talk_url [id]
  (format "https://fodok.jku.at/fodok/vortrag.xsql?V_ID=%s&xml-stylesheet=none" id))

(defn get-talk-info [talk]
  (let [{:keys [id]} talk
        content (-> id
                    talk_url
                    client/get
                    util/parse_to_xml)]
    {:invited-by (util/filter-for-tag :EINGELADEN_VON content)
     :place (util/filter-for-tag :STANDORT content)
     :original-title (util/filter-for-tag :ORIGINAL_TITEL content)}))

(defn map_additional_data_to_talks [talks]
  (map #(merge % (get-talk-info %)) talks))

(defn- rp_url [id]
  (format "	https://fodok.jku.at/fodok/forschungsprojekt.xsql?FP_ID=%s&xml-stylesheet=none" id))

(defn get-rp-info [rp]
  (let [{:keys [id]} rp
        content (-> id
                    rp_url
                    client/get
                    util/parse_to_xml)]
    {:invited-by (util/filter-for-tag :EINGELADEN_VON content)
     :place (util/filter-for-tag :STANDORT content)
     :original-title (util/filter-for-tag :ORIGINAL_TITEL content)}))

(defn map_additional_data_to_rp [rp]
  (map #(merge % (get-rp-info %)) rp))
