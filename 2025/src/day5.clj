(ns day5
  (:require clojure.string))

(defn parse-range [line]
  (vec (map parse-long (clojure.string/split line #"-"))))

(defn parse-input [input]
  (let [lines (clojure.string/split-lines input)
        [range-lines ids] (split-with #(not= % "") lines)
        ranges (map parse-range range-lines)
        ids (map parse-long (rest ids))]
    [ranges ids]))

(defn range-contains? [[low high] value]
  (and (<= low value) (<= value high)))

(defn ranges-contain? [ranges value]
  (boolean (some #(range-contains? % value) ranges)))

(defn part1 [ranges values]
  (count (filter (partial ranges-contain? ranges) values)))

(defn merge-ranges [ranges]
  (let [sorted-ranges (sort-by first ranges)]
    (reduce (fn [merged [rlow rhigh :as right]]
              (let [prefix (pop merged)
                    [llow lhigh] (peek merged)]
                (if (<= rlow lhigh)
                  (conj prefix [llow (max lhigh rhigh)])
                  (conj merged right))))
            [(first sorted-ranges)] (rest sorted-ranges))))

(defn part2 [ranges]
  (let [merged (merge-ranges ranges)]
    (reduce + (map (fn [[min max]] (inc (- max min))) merged))))

(defn -main []
  (let [input (slurp "inputs/day5")
        [ranges ids] (parse-input input)]
    (println "Part 1:" (part1 ranges ids))
    (println "Part 2:" (part2 ranges))))
