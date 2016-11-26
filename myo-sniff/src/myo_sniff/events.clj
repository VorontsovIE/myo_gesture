(ns myo-sniff.events
  (:require [cheshire.core :as json]
            [clojure.core.async :as a :refer [go >! <! >!! <!!]]
            [clojure.java.io :as io]))

(defn remove-duplicates
  [xs]
  (->>
   xs
   (group-by :timestamp)
   vals
   (map first)))

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
   (buffer conj-slice 10)
   (buffer conj-slide 3)
   (map flat-one-level)
   (map (partial into []))
   (map (partial reduce sum-vec))
   ))

(defn predict
  [vec]
  (Thread/sleep 100)
  (->>
   (rand-int 3)
   {0 "a"
    1 "b"
    2 "n"}))

(defn start-consumer
  []
  (let [g-chan (a/chan 10 group-events-xform)
        r-chan (a/chan 10)]
    (a/go-loop []
      (if-let [grouped (<! g-chan)]
        (do
          (>! r-chan (predict grouped))
          (recur))
        (do
          (a/close! r-chan)
          (prn :g-loop-closed))))
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
            (.close w)))))
    [g-chan r-chan]))

(comment (let [[input-chan _] (start-consumer)]
   (->>
    (slurp "myo.log")
    clojure.string/split-lines
    (a/onto-chan input-chan)
    )))

(comment (->>
  (slurp "myo.log")
  clojure.string/split-lines
  (take 100)
  (into [] group-events-xform)
  ;;remove-duplicates
  ;; remove-between-locks
  ;; (filter #(-> % :type (= "emg")))
  (take 30)
  clojure.pprint/pprint
  ;;(map #(concat [(Long. (:timestamp %))] (:emg %)))
  ;;(write-csv "a.sher.csv" headers)
  ))



