(ns myo-sniff.events
  (:require [cheshire.core :as json]
            [clojure.core.async :as a :refer [go >! <! >!! <!!]]
            [clojure.java.io :as io]
            [org.httpkit.client :as http]
            [clojure.string :as str]

            [myo-sniff.web :as web]))

;; Settings

(def predict-endpoint "predict")
(def learn-endpoint "learn")

(defn exec-ml
  [vec endpoint]
  (let [q (->
           vec
           json/encode
           (str/replace #"\[" "%5B")
           (str/replace #"\]" "%5D"))
        url (str "http://localhost:8000/?" endpoint "=" q)
        {:keys [status headers body error] :as resp} @(http/get url)]
    (if error
      (println "Failed '" url "', exception: " error)
      (do
        (println "received " body)
        body))))

;; Need to use it, TODO: use in xform

(defn remove-duplicates
  [xs]
  (->>
   xs
   (group-by :timestamp)
   vals
   (map first)))

;; xform events pre-aggregation

(defn conj-slide
  [xs x limit]
  (let [xs* (if (= (count xs) limit)
              (into [] (rest xs))
              xs)]
    (conj xs* x)))

(defn conj-slice
  [xs x limit]
  (let [xs* (if (= (count xs) limit)
              []
              xs)]
    (conj xs* x)))

(defn buffer
  [conj-buffer size]
  (fn [xf]
    (let [buffer (volatile! [])]
      (fn
        ([] xf)
        ([result] (xf result))
        ([result input]
         (let [new-buffer (vswap! buffer conj-buffer input size)]
           (if (= size (count @buffer))
             (xf result new-buffer)
             result)))))))

(def flat-one-level (partial mapcat identity))

(defn sum-vec
  [xs1 xs2]
  (map + xs1 xs2))

(def group-events-xform
  (comp
   (map #(json/decode % true))
   (filter #(-> % first (= "event")))
   (map second)
   (filter #(-> % :type (= "emg")))
   (map :emg)
   (map (partial map #(Math/abs %)))
   (buffer conj-slice 30)
   (buffer conj-slide 3)
   (map flat-one-level)
   (map (partial into []))
   (map (partial reduce sum-vec))
   ))

#_(->>
 (slurp "myo.log")
 clojure.string/split-lines
 (into [] group-events-xform)
 (take 10)
 clojure.pprint/pprint)

;; xform letters post-aggregation

(def safe-inc (fnil inc 0))

(defn update-frequences
  [[dictionary result] new-letter threshold]
  (let [state* (update dictionary new-letter safe-inc)]
    (if-let [out-l (some (fn [[l fq]] (when (= fq threshold) l)) state*)]
      [{} out-l]
      [state* nil])))

(defn filter-letters
  [threshold]
  (fn [xf]
    (let [state (volatile! [{} nil])]
      (fn
        ([] xf)
        ([result] (xf result))
        ([result input]
         (let [[new-state out-l] (vswap! state update-frequences input threshold)]
           (if out-l
             (xf result out-l)
             result)))))))

;; input consumer

(defn start-consumer
  [endpoint letters-threshold]
  (let [g-chan (a/chan 10 group-events-xform)
        r-chan (a/chan 10 (filter-letters letters-threshold))]
    (a/go-loop []
      (if-let [grouped (<! g-chan)]
        (do
          (>! r-chan (exec-ml grouped endpoint))
          (recur))
        (do
          (a/close! r-chan)
          (prn :g-loop-closed))))
    [g-chan r-chan]))

;; dumb output to file consumer

(defn file-consumer
  [r-chan]
  (let [w (io/writer "out.txt")
        start (System/currentTimeMillis)]
    (a/go-loop []
      (if-let [result (<! r-chan)]
        (do
          (.write w (str result "\n"))
          (recur))
        (do
          (prn :r-loop-closed)
          (prn (str
                "Elapsed: "
                (/ (- (System/currentTimeMillis) start) 1000.0)
                " s"))
          (.close w))))))

;; for debug: input from file, to websocket

(defn run-file->websocket
  [file]
  (let [[input-chan r-chan] (start-consumer predict-endpoint 15)]
   (web/websocket-consumer r-chan)
   (Thread/sleep (* 5 1000))
   (->>
    (slurp file)
    clojure.string/split-lines
    (a/onto-chan input-chan))))

;; (run-file->websocket "myo.log")
