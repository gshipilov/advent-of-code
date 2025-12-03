(ns day3
  (:require clojure.string))

(defn first-max-with-idx [vals]
  (let [vidx (map-indexed vector vals)]
    (reduce (fn [[idx val] [ni nv]]
              (if (> nv val)
                [ni nv]
                [idx val])) [0 0] vidx)))

(defn best-joltage [bank num-batteries]
  (loop [batteries bank
         remaining num-batteries
         joltage 0]
    (if (zero? remaining)
      joltage
      (let [n-remaining (dec remaining)
            left-side (drop-last n-remaining batteries)
            [max-idx max] (first-max-with-idx left-side)
            n-joltage (+ (* 10 joltage) max)]
        (recur (drop (inc max-idx) batteries) n-remaining n-joltage)))))

(defn sum-joltage [banks num-batteries]
  (reduce + (map #(best-joltage % num-batteries) banks)))

(defn part1 [banks]
  (sum-joltage banks 2))

(defn part2 [banks]
  (sum-joltage banks 12))

(defn parse-bank [line]
  (map (comp parse-long str) line))

(defn parse-banks [lines]
  (map parse-bank (clojure.string/split-lines lines)))

(defn -main []
  (let [lines (slurp "inputs/day3")
        banks (parse-banks lines)]
    (println "Part 1:" (part1 banks))
    (println "Part 2:" (part2 banks))))
