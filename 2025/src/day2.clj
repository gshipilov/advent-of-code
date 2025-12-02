(ns day2
  (:require [clojure.string]))

(defn same-halves [s]
  (let [mid (/ (count s) 2)
        left (subs s 0 mid)
        right (subs s mid)]
    (= left right)))

(defn valid-id? [id]
  (let [id-str (str id)]
    (not (and
           (zero? (mod (count id-str) 2))
           (same-halves id-str)))))

(defn valid-id2? [id]
  (or
    (< id 10)
    (let [id-str (str id)
          max-part (inc (quot (count id-str) 2))
          repeats? #(apply = (partition-all % id-str))]
      (not-any? repeats? (range 1 max-part)))))

(defn parse-range [s]
  (let [[start end] (map parse-long (clojure.string/split s #"-"))]
    (range start (inc end))))

(defn parse-ranges [s]
  (map parse-range (clojure.string/split s #",")))

(defn invalid-ids [pred ranges]
  (mapcat #(filter (complement pred) %) ranges))

(defn part1 [ranges]
  (reduce + (invalid-ids valid-id? ranges)))

(defn part2 [ranges]
  (reduce + (invalid-ids valid-id2? ranges)))

(defn -main []
  (let [lines (slurp "inputs/day2")
        ranges (parse-ranges lines)]
    (println "Part 1:" (part1 ranges))
    (println "Part 2:" (part2 ranges))))
