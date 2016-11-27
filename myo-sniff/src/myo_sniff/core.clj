(ns myo-sniff.core
  (:require [gniazdo.core :as ws]
            [clojure.java.io :as io]
            [cheshire.core :as json]
            [clojure.string :as str]
            [clojure.core.async :as a]

            [myo-sniff.events :as e]
            [myo-sniff.web :as web]))

(defn foo
  "I don't do a whole lot."
  [x]
  (println x "Hello, World!"))

(defonce writer (atom nil))

(defn open-writer!
  [file append?]
  (when-not @writer
    (reset! writer (io/writer file :append append?))))

(defn close-writer!
  []
  (when @writer
    (.close @writer)
    (reset! writer nil)))

(defn put-file
  []
  (if-let [w @writer]
    (fn [data]
      (.write w (str data "\n")))
    (throw (Exception. "Writer is closed."))))

(defn put-chan
  [chan]
  (fn [data]
    (a/go (a/>! chan data))))

(defn ->command
  [name params]
  (json/encode ["command" (merge {:command name :myo 0} params)]))

(def stream-emg->enabled (->command "set_stream_emg" {:type "enabled"}))
(def locking-policy->none (->command "set_locking_policy" {:type "none"}))

(defn socket
  [on-receive]
  (ws/connect
   "ws://127.0.0.1:10138/myo/3"
   :on-receive on-receive))

(defn start!
  [folder id]
  (let [file (str "../samples/" folder "/" id ".log")
        _ (open-writer! file false)
        [input-ch _] (e/start-consumer e/predict-endpoint 15)
        socket (socket (put-file))]
    ;;(ws/send-msg socket locking-policy->none)
    (ws/send-msg socket stream-emg->enabled)
    [socket input-ch]))

(defn stop!
  [[socket input-ch]]
  (ws/close socket)
  (Thread/sleep 100)
  (close-writer!)
  (a/close! input-ch))

(comment (let [token (start! "seq" "r-b-c-a-5s-ilya-2")]
   (Thread/sleep (* 20 1000))
   (stop! token)))

(defn start-web!
  [endpoint]
  (let [[input-ch out-ch] (e/start-consumer endpoint 15)
        server (web/websocket-consumer out-ch)
        socket (socket (put-chan input-ch))]
    (ws/send-msg socket stream-emg->enabled)
    [socket input-ch]))

(defn stop-web!
  [[socket input-ch]]
  (ws/close socket)
  (Thread/sleep 100)
  (a/close! input-ch))

'(let [token (start-web! e/predict-endpoint)]
  (Thread/sleep (* 15 1000))
  (stop! token))

'(let [token (start-web! e/learn-endpoint)]
   (Thread/sleep (* 30 1000))
   (stop! token))
