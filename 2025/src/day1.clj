(ns day1
  (:require [clojure.string]))

(defn parse-cmd [line]
  (let [dir (subs line 0 1)
        num (parse-long (subs line 1))]
    (if (= dir "R") num (- num))))

(defn parse-cmds [lines]
  (map parse-cmd (clojure.string/split-lines lines)))

(defn part1 [cmds]
  (count
    (filter zero? (reductions (fn [acc val] (mod (+ acc val) 100)) 50 cmds))))

(defn expand [cmd]
  (repeat (abs cmd) (compare cmd 0)))

(defn part2 [cmds]
  (let [expanded (flatten (map expand cmds))]
    (part1 expanded)))

(defn -main []
  (let [lines (slurp "inputs/day1")
        cmds (parse-cmds lines)]
    (println "Part 1:" (part1 cmds))
    (println "Part 2:" (part2 cmds))))
