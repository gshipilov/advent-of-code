use aoc2023::read_input;
use std::collections::HashSet;

fn main() {
    let input = read_input(10);
    let (tiles, start) = parse_grid(&input);
    let loop_tiles = find_loop(&tiles, start);

    println!("Part 1: {}", part_1(&loop_tiles));
    println!("Part 2: {}", part_2(&tiles, &loop_tiles));
}

fn part_1(loop_tiles: &HashSet<(usize, usize)>) -> usize {
    loop_tiles.len() / 2 + loop_tiles.len() % 2
}

fn part_2(tiles: &[Vec<Tile>], loop_tiles: &HashSet<(usize, usize)>) -> usize {
    let north_tiles: HashSet<Tile> =
        HashSet::from_iter([Tile::Vertical, Tile::NEBend, Tile::WNBend]);

    let mut out = 0;

    for (y, line) in tiles.iter().enumerate() {
        let mut inside = false;
        for (x, tile) in line.iter().enumerate() {
            if loop_tiles.contains(&(x, y)) {
                if north_tiles.contains(tile) {
                    inside = !inside;
                }
                continue;
            }

            if inside {
                out += 1;
            }
        }
    }

    out
}

fn parse_grid(input: &str) -> (Vec<Vec<Tile>>, (usize, usize)) {
    let rowlen = input.lines().next().unwrap().len();
    let mut tiles = vec![vec![Tile::Ground; rowlen + 2]];
    let mut start = (0, 0);

    for (y, line) in input.lines().enumerate() {
        let mut row = vec![Tile::Ground];
        for (x, c) in line.chars().enumerate() {
            let tile = match c {
                'S' => {
                    start = (x + 1, y + 1); // take padding into account
                    Tile::Ground
                }
                '.' => Tile::Ground,
                '|' => Tile::Vertical,
                '-' => Tile::Horizontal,
                'L' => Tile::NEBend,
                'J' => Tile::WNBend,
                '7' => Tile::WSBend,
                'F' => Tile::SEBend,
                _ => unreachable!(),
            };
            row.push(tile);
        }

        row.push(Tile::Ground);
        tiles.push(row);
    }

    replace_start(&mut tiles, start);

    (tiles, start)
}

fn find_loop(tiles: &[Vec<Tile>], start: (usize, usize)) -> HashSet<(usize, usize)> {
    let mut seen = HashSet::new();
    let mut current = start;

    loop {
        seen.insert(current);
        let tile = tiles[current.1][current.0];
        let conns = tile.connections(current.0, current.1);
        let n_opt = conns.iter().find(|v| !seen.contains(v));

        if let Some(&nc) = n_opt {
            current = nc;
        } else {
            break;
        }
    }

    seen
}

fn replace_start(tiles: &mut [Vec<Tile>], start: (usize, usize)) {
    let sx = start.0;
    let sy = start.1;

    let top = tiles[sy - 1][sx].connections(sx, sy - 1).contains(&start);
    let right = tiles[sy][sx + 1].connections(sx + 1, sy).contains(&start);
    let bottom = tiles[sy + 1][sx].connections(sx, sy + 1).contains(&start);
    let left = tiles[sy][sx - 1].connections(sx - 1, sy).contains(&start);

    let actual_start = match (top, right, bottom, left) {
        (true, true, false, false) => Tile::NEBend,
        (true, false, true, false) => Tile::Vertical,
        (true, false, false, true) => Tile::WNBend,
        (false, true, true, false) => Tile::SEBend,
        (false, true, false, true) => Tile::Horizontal,
        (false, false, true, true) => Tile::WSBend,
        _ => unreachable!(),
    };

    tiles[sy][sx] = actual_start;
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
enum Tile {
    Ground,
    Vertical,
    Horizontal,
    NEBend,
    WNBend,
    WSBend,
    SEBend,
}

impl Tile {
    fn connections(&self, x: usize, y: usize) -> Vec<(usize, usize)> {
        match self {
            Tile::Ground => Vec::new(),
            Tile::Vertical => vec![(x, y - 1), (x, y + 1)],
            Tile::Horizontal => vec![(x - 1, y), (x + 1, y)],
            Tile::NEBend => vec![(x, y - 1), (x + 1, y)],
            Tile::WNBend => vec![(x - 1, y), (x, y - 1)],
            Tile::WSBend => vec![(x - 1, y), (x, y + 1)],
            Tile::SEBend => vec![(x, y + 1), (x + 1, y)],
        }
    }
}

#[cfg(test)]
mod tests {
    use crate::{find_loop, parse_grid, part_1, part_2};
    use indoc::indoc;

    #[test]
    fn test_parse_a() {
        let input = indoc! {"
            .....
            .S-7.
            .|.|.
            .L-J.
            .....
        "};

        let (grid, start) = parse_grid(input);

        println!("Start: {start:?}");
        for line in &grid {
            println!("{line:?}");
        }

        let l = find_loop(&grid, start);
        for coords in l {
            println!("{coords:?}");
        }
    }

    #[test]
    fn test_part_1() {
        let input = indoc! {"
            ..F7.
            .FJ|.
            SJ.L7
            |F--J
            LJ...
        "};

        let (tiles, start) = parse_grid(input);
        let loop_tiles = find_loop(&tiles, start);

        assert_eq!(8, part_1(&loop_tiles));
    }

    #[test]
    fn test_part_2_a() {
        let input = indoc! {"
            ..........
            .S------7.
            .|F----7|.
            .||....||.
            .||....||.
            .|L-7F-J|.
            .|..||..|.
            .L--JL--J.
            ..........
        "};

        let (tiles, start) = parse_grid(input);
        let loop_tiles = find_loop(&tiles, start);

        assert_eq!(4, part_2(&tiles, &loop_tiles));
    }

    #[test]
    fn test_part_2_b() {
        let input = indoc! {"
            .F----7F7F7F7F-7....
            .|F--7||||||||FJ....
            .||.FJ||||||||L7....
            FJL7L7LJLJ||LJ.L-7..
            L--J.L7...LJS7F-7L7.
            ....F-J..F7FJ|L7L7L7
            ....L7.F7||L7|.L7L7|
            .....|FJLJ|FJ|F7|.LJ
            ....FJL-7.||.||||...
            ....L---J.LJ.LJLJ...
        "};

        let (tiles, start) = parse_grid(input);
        let loop_tiles = find_loop(&tiles, start);

        assert_eq!(8, part_2(&tiles, &loop_tiles));
    }
}
