use aoc2023::read_input;
use std::collections::HashSet;

fn main() {
    let input = read_input(11);

    println!("Part 1: {}", part_1(&input));
    println!("Part 2: {}", part_2(&input, 1_000_000));
}

fn part_1(input: &str) -> usize {
    let galaxies = find_galaxies(input, 2);

    find_distance(&galaxies)
}

fn part_2(input: &str, expand_factor: usize) -> usize {
    let galaxies = find_galaxies(input, expand_factor);

    find_distance(&galaxies)
}

fn find_distance(galaxies: &[(usize, usize)]) -> usize {
    galaxies
        .iter()
        .enumerate()
        .flat_map(|(i, &galaxy)| {
            galaxies[i..]
                .iter()
                .map(move |&other| manhattan_distance(galaxy, other))
        })
        .sum()
}

fn manhattan_distance(p: (usize, usize), q: (usize, usize)) -> usize {
    p.0.abs_diff(q.0) + p.1.abs_diff(q.1)
}

fn find_galaxies(input: &str, expand_factor: usize) -> Vec<(usize, usize)> {
    let expand_factor = expand_factor - 1;

    let input_chars: Vec<Vec<char>> = input.lines().map(|line| line.chars().collect()).collect();

    let mut rows_to_expand: HashSet<usize> = HashSet::from_iter(0..input_chars.len());
    let mut cols_to_expand: HashSet<usize> = HashSet::from_iter(0..input_chars[0].len());

    for (row, line) in input_chars.iter().enumerate() {
        for (col, &c) in line.iter().enumerate() {
            if c != '.' {
                rows_to_expand.remove(&row);
                cols_to_expand.remove(&col);
            }
        }
    }

    let mut galaxies = Vec::new();

    let mut row_extra = 0;
    for (row, line) in input_chars.iter().enumerate() {
        if rows_to_expand.contains(&row) {
            row_extra += expand_factor;
        }

        let mut col_extra = 0;
        for (col, &c) in line.iter().enumerate() {
            if cols_to_expand.contains(&col) {
                col_extra += expand_factor;
            }

            if c == '#' {
                galaxies.push((row + row_extra, col + col_extra))
            }
        }
    }

    galaxies
}

#[cfg(test)]
mod tests {
    use crate::{part_1, part_2};
    use indoc::indoc;

    const TEST_INPUT: &str = indoc! {"
        ...#......
        .......#..
        #.........
        ..........
        ......#...
        .#........
        .........#
        ..........
        .......#..
        #...#.....
    "};

    #[test]
    fn test_part_1() {
        assert_eq!(374, part_1(TEST_INPUT));
    }

    #[test]
    fn test_part_2() {
        assert_eq!(1030, part_2(TEST_INPUT, 10));
        assert_eq!(8410, part_2(TEST_INPUT, 100));
    }
}
