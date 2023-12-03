use aoc2023::read_input_lines;
use std::collections::HashMap;

fn main() {
    let lines = read_input_lines(3);

    let mut chars: Vec<Vec<char>> = Vec::new();
    for line in lines {
        chars.push(line.chars().collect());
    }

    println!("Part 1: {}", part_1(&chars));
    println!("Part 2: {}", part_2(&chars));
}

fn part_1(chars: &[Vec<char>]) -> u32 {
    let mut sum = 0;

    for (y, line) in chars.iter().enumerate() {
        let mut current_number = 0;
        let mut seen_symbol = false;
        for (x, c) in line.iter().enumerate() {
            if c.is_ascii_digit() {
                if !seen_symbol {
                    seen_symbol = has_symbol_neighbor(chars, y, x);
                }
                current_number *= 10;
                current_number += c.to_digit(10).unwrap();
            }

            if !c.is_ascii_digit() || x == (line.len() - 1) {
                if seen_symbol {
                    sum += current_number;
                }
                current_number = 0;
                seen_symbol = false;
            }
        }
    }

    sum
}

fn part_2(chars: &[Vec<char>]) -> u32 {
    let mut candidates: HashMap<(usize, usize), Vec<u32>> = HashMap::new();

    for (y, line) in chars.iter().enumerate() {
        let mut current_number = 0;
        let mut star_pos = None;
        for (x, c) in line.iter().enumerate() {
            if c.is_ascii_digit() {
                if star_pos.is_none() {
                    star_pos = star_neighbor_position(chars, y, x);
                }
                current_number *= 10;
                current_number += c.to_digit(10).unwrap();
            }

            if !c.is_ascii_digit() || x == (line.len() - 1) {
                if let Some((sy, sx)) = star_pos {
                    let lst = candidates.entry((sy, sx)).or_default();
                    lst.push(current_number);
                }
                current_number = 0;
                star_pos = None;
            }
        }
    }

    let mut out = 0;

    for cs in candidates.values() {
        if cs.len() != 2 {
            continue;
        }
        out += cs[0] * cs[1];
    }

    out
}

fn has_symbol_neighbor(chars: &[Vec<char>], y: usize, x: usize) -> bool {
    let ymax = chars.len() as isize;
    let xmax = chars[0].len() as isize;

    for dy in -1..=1 {
        for dx in -1..=1 {
            if dy == 0 && dx == 0 {
                continue;
            }

            let ny = ((y as isize) + dy).clamp(0, ymax) as usize;
            let nx = ((x as isize) + dx).clamp(0, xmax) as usize;

            let other = chars.get(ny).and_then(|v| v.get(nx).copied());
            if let Some(oc) = other {
                if !oc.is_ascii_digit() && oc != '.' {
                    return true;
                }
            }
        }
    }

    false
}

fn star_neighbor_position(chars: &[Vec<char>], y: usize, x: usize) -> Option<(usize, usize)> {
    let ymax = chars.len() as isize;
    let xmax = chars[0].len() as isize;

    for dy in -1..=1 {
        for dx in -1..=1 {
            if dy == 0 && dx == 0 {
                continue;
            }

            let ny = ((y as isize) + dy).clamp(0, ymax) as usize;
            let nx = ((x as isize) + dx).clamp(0, xmax) as usize;

            let other = chars.get(ny).and_then(|v| v.get(nx).copied());
            if let Some('*') = other {
                return Some((ny, nx));
            }
        }
    }

    None
}

#[cfg(test)]
mod tests {
    use crate::{part_1, part_2};
    use indoc::indoc;

    const TEST_INPUT: &str = indoc! {"
        467..114..
        ...*......
        ..35..633.
        ......#...
        617*......
        .....+.58.
        ..592.....
        ......755.
        ...$.*....
        .664.598..
    "};

    #[test]
    fn test_part1() {
        let lines: Vec<String> = TEST_INPUT.lines().map(String::from).collect();

        let mut chars: Vec<Vec<char>> = Vec::new();
        for line in lines {
            chars.push(line.chars().collect());
        }

        assert_eq!(4361, part_1(&chars));
    }

    #[test]
    fn test_part_2() {
        let lines: Vec<String> = TEST_INPUT.lines().map(String::from).collect();

        let mut chars: Vec<Vec<char>> = Vec::new();
        for line in lines {
            chars.push(line.chars().collect());
        }

        assert_eq!(467835, part_2(&chars));
    }
}
