(ns myo-sniff.core
  (:require [gniazdo.core :as ws]
            [clojure.java.io :as io]
            [cheshire.core :as json]
            [clojure.string :as str]
            [clojure.core.async :as a]

            [myo-sniff.events :as e]))

(defn foo
  "I don't do a whole lot."
  [x]
  (println x "Hello, World!"))

(defonce writer (atom nil))

(defn open-writer!
  [file]
  (when-not @writer
    (reset! writer (io/writer file))))

(defn close-writer!
  []
  (when @writer
    (.close @writer)
    (reset! writer nil)))

(defn on-receive-fn
  [chan]
  (fn [data]
    (a/go (a/>! chan data)))
  #_(if-let [w @writer]
    (fn [data]
      (.write w (str data "\n")))
    (throw (Exception. "Writer is closed."))))

(comment
  (open-writer! "myo.log")
  (.write @writer "halo!")
  (close-writer!))

(defn ->command
  [name params]
  (json/encode ["command" (merge {:command name :myo 0} params)]))

(def stream-emg->enabled (->command "set_stream_emg" {:type "enabled"}))
(def locking-policy->none (->command "set_locking_policy" {:type "none"}))

(comment
  (let [file "myo.log"
        _ (open-writer! file)
        socket (ws/connect "ws://127.0.0.1:10138/myo/3"
                           :on-receive (on-receive-fn file))]
    ;;(ws/send-msg socket locking-policy->none)
    (ws/send-msg socket stream-emg->enabled)
    (Thread/sleep (* 10 1000))
    (ws/close socket)
    (close-writer!)))


(defn start!
  []
  (let [file "a-b-n-rand-30s.log"
        _ (open-writer! file)
        [input-ch _] (e/start-consumer)
        socket (ws/connect "ws://127.0.0.1:10138/myo/3"
                           :on-receive (on-receive-fn input-ch))]
    ;;(ws/send-msg socket locking-policy->none)
    (ws/send-msg socket stream-emg->enabled)
    [socket input-ch]))

(defn stop!
  [[socket input-ch]]
  (ws/close socket)
  (Thread/sleep 100)
  (close-writer!)
  (a/close! input-ch))

(comment (let [token (start!)]
   (Thread/sleep (* 10 1000))
   (stop! token)))

;; (def token (start!))
;; (stop! token)

(defn write-csv
  [file headers data]
  (spit file (str (str/join "," headers) "\n"))
  (with-open [w (io/writer file :append true)]
   (doseq [row data]
     (.write w (str (str/join "," row) "\n")))))

(def headers
  (->>
  (range 1 9)
  (map #(str "emg" %))
  (into [])
  (concat ["timestamp"])))

