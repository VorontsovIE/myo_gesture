(ns myo-sniff.events
  (:require [cheshire.core :as json]
            [clojure.core.async :as a :refer [go >! <! >!! <!!]]))

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
   (map flatten)
   (map (partial reduce +))
  ))

(map #(Math/abs %) (range 2))

(->>
 (slurp "myo.log")
 clojure.string/split-lines
 (into [] group-events-xform)
 ;;remove-duplicates
 ;; remove-between-locks
 ;; (filter #(-> % :type (= "emg")))
 (take 30)
 clojure.pprint/pprint
 ;;(map #(concat [(Long. (:timestamp %))] (:emg %)))
 ;;(write-csv "a.sher.csv" headers)
 )


