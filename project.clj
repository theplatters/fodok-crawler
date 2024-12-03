(defproject fodok-crawler "0.1.0-SNAPSHOT"
  :description "FIXME: write description"
  :url "http://example.com/FIXME"
  :license {:name "EPL-2.0 OR GPL-2.0-or-later WITH Classpath-exception-2.0"
            :url "https://www.eclipse.org/legal/epl-2.0/"}
  :dependencies [[org.clojure/clojure "1.11.1"] [clj-http "3.12.3"] [org.clojure/data.csv "1.1.0"]]
  :repl-options {:init-ns fodok-crawler.core}
  :plugins [[cider/cider-nrepl "0.42.1"]]
  :main fodok-crawler.core
  :aot [fodok-crawler.core])
