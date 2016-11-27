(ns myo-sniff.web
  (:require [org.httpkit.server :refer [with-channel on-close] :as http]
            [clojure.core.async :as a]))

(def clients (atom #{}))

(defn app [req]
  (with-channel req channel
    (println channel "connected")
    (swap! clients conj channel)
    (on-close channel (fn [status]
                        (swap! clients disj channel)
                        (println channel "closed, status" status)))))

(defn broadcast
  [data]
  (doseq [client @clients]
    (http/send! client data)))

(defonce server (atom nil))

(defn stop-server []
  (when-not (nil? @server)
    (@server :timeout 100)
    (reset! server nil)))

(defn run-server
  []
  (http/run-server #'app {:port 8080}))

(defn start-server
  []
  (reset! server (run-server)))

(defn websocket-consumer
  [r-chan]
  (let [stop-server (run-server)]
    (a/go-loop []
      (if-let [result (a/<! r-chan)]
        (do
          (broadcast result)
          (recur))
        (do
          (prn :r-loop-closed)
          (stop-server :timeout 100))))))
