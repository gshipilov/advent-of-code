(ns day4
  (:require clojure.string))

(defn parse-cell [c]
  (if (= c \@) :roll :blank))

(defn parse-grid [input]
  (->> (clojure.string/split-lines input)
       (mapv #(mapv parse-cell %))))

(defn get-cell [grid x y]
  (get (get grid y :blank) x :blank))

(defn neighbors [grid x y]
  (for [dy [-1 0 1]
        dx [-1 0 1]
        :when (not= dx dy 0)]
    (get-cell grid (+ x dx) (+ y dy))))

(defn count-neighbor-rolls [grid x y]
  (get (frequencies (vec (neighbors grid x y))) :roll 0))

(defn reachable? [grid x y]
  (and
    (= (get-cell grid x y) :roll)
    (< (count-neighbor-rolls grid x y) 4)))

(defn part1 [grid]
  (let [height (count grid)
        width (count (get grid 0))]
    (count (for [y (range height)
                 x (range width)
                 :when (reachable? grid x y)]
             1))))

(defn update-row [grid y]
  (let [row (map-indexed vector (get grid y))]
    (reduce (fn [[nrow ms] [x value]]
              (if
                (reachable? grid x y)
                [(conj nrow :blank) (inc ms)]
                [(conj nrow value) ms])) [[] 0] row)))

(defn update-grid [grid]
  (let [ys (range (count grid))]
    (reduce (fn [[ngrid ms] y]
              (let [[nrow rms] (update-row grid y)]
                [(conj ngrid nrow) (+ ms rms)])) [[] 0] ys)))

(defn part2 [grid]
  (loop [total-mods 0
         grid grid]
    (let [[ngrid mods] (update-grid grid)]
      (if (zero? mods)
        total-mods
        (recur (+ total-mods mods) ngrid)))))

(defn -main []
  (let [input (slurp "inputs/day4")
        grid (parse-grid input)]
    (println "Part 1:" (part1 grid))
    (println "Part 2:" (part2 grid))))
