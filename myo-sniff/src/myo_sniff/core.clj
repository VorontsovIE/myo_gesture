(ns myo-sniff.core
  (:require [gniazdo.core :as ws]
            [clojure.java.io :as io]
            [cheshire.core :as json]))

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
  [file]
  (if-let [w @writer]
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
  (let [file "myo.log"
        _ (open-writer! file)
        socket (ws/connect "ws://127.0.0.1:10138/myo/3"
                           :on-receive (on-receive-fn file))]
    ;;(ws/send-msg socket locking-policy->none)
    (ws/send-msg socket stream-emg->enabled)
    socket))

(defn stop!
  [socket]
  (ws/close socket)
  (close-writer!))

#_(def token (start!))
