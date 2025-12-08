(ns day8
  (:require [clojure.math :as math]
            [clojure.set :as sets]
            [clojure.string :as str]))

(defn parse-point [s]
  (mapv parse-long (str/split s #",")))

(defn parse-lines [lines]
  (mapv parse-point lines))

(defn parse-input [input]
  (parse-lines (str/split-lines input)))

(defn distance [[lx ly lz] [rx ry rz]]
  (+ (math/pow (- lx rx) 2)
     (math/pow (- ly ry) 2)
     (math/pow (- lz rz) 2)))

(defn make-edges [points]
  (let [points (vec points)
        len (count points)]
    (->> (for [l (range len)
               r (range (inc l) len)
               :let [lp (get points l)
                     rp (get points r)]]
           [#{lp rp} (distance lp rp)])
         (sort-by second)
         (mapv first))))

(defn make-forest [points]
  (set (map (fn [v] #{v}) points)))

(defn find-tree [forest point]
  (first (filter #(contains? % point) forest)))

(defn find-trees [forest lp rp]
  (let [lt (find-tree forest lp)
        rt (find-tree forest rp)]
    (when (not (identical? lt rt))
      [lt rt])))

(defn merge-trees [forest trees]
  (if-let [[lt rt] trees]
    (let [new-tree (sets/union lt rt)
          new-forest (disj forest lt rt)]
      (conj new-forest new-tree))
    forest))

(defn kruskals
  ([forest edges] (kruskals forest edges Long/MAX_VALUE))
  ([forest edges limit]
   (loop [forest forest
          edges edges
          iter-count 0
          last-edge nil]
     (let [edge (first edges)]
       (if (or
             (= 1 (count forest))
             (= iter-count limit)
             (nil? edge))
         [forest last-edge]
         (let [trees (find-trees forest (first edge) (second edge))
               new-forest (merge-trees forest trees)]
           (recur new-forest (rest edges) (inc iter-count) edge)))))))

(defn part1 [forest edges limit]
  (let [[forest _] (kruskals forest edges limit)
        forest (vec forest)
        sorted (sort-by count forest)]
    (reduce * (map count (take-last 3 sorted)))))

(defn part2 [forest edges]
  (let [[_ last-conn] (kruskals forest edges)]
    (* (get (first last-conn) 0) (get (second last-conn) 0))))

(defn -main []
  (let [input (slurp "inputs/day8")
        points (parse-input input)
        forest (make-forest points)
        edges (make-edges points)]
    (println "Part 1:" (part1 forest edges 1000))
    (println "Part 2:" (part2 forest edges))))

