(ns day6
  (:require clojure.string))

(defn parse-number-line-p1 [line]
  (mapv parse-long (clojure.string/split (clojure.string/trim line) #"\s+")))

(defn parse-op-line [line]
  (mapv (fn [op]
          (case op
            "+" +
            "*" *)) (clojure.string/split line #"\s+")))

(defn parse-input-p1 [input]
  (let [lines (clojure.string/split-lines input)
        nums (mapv parse-number-line-p1 (butlast lines))
        ops (parse-op-line (last lines))]
    [nums ops]))

(defn compute-cols [nums ops]
  (for [col (range (count ops))]
    (let [values (map #(get % col) nums)]
      (apply (get ops col) values))))

(defn part1 [input]
  (reduce + (apply compute-cols input)))

(defn parse-input-p2 [input]
  (let [lines (clojure.string/split-lines input)
        nums (butlast lines)
        ops (parse-op-line (last lines))]
    [nums ops]))

(defn read-col [nums col]
  (map #(get % col) nums))

(defn col-to-num [nums col]
  (let [values (read-col nums col)]
    (->> (apply str values)
         (clojure.string/trim)
         (parse-long))))

(defn group-nums [nums]
  (->> (range (count (first nums)))
       (map #(col-to-num nums %))
       (partition-by nil?)
       (remove #(every? nil? %))))

(defn solve-problems [[nums ops]]
  (let [groups (group-nums nums)]
    (map #(apply %2 %1) groups ops)))

(defn part2 [input]
  (reduce + (solve-problems input)))

(defn -main []
  (let [input (slurp "inputs/day6")
        p1-input (parse-input-p1 input)
        p2-input (parse-input-p2 input)]
    (println "Part 1:" (part1 p1-input))
    (println "Part 2:" (part2 p2-input))))