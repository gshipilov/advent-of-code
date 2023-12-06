use aoc2023::read_input;
use indicatif::{HumanCount, MultiProgress, ProgressBar, ProgressStyle};
use nom::bytes::complete::tag;
use nom::character::complete::{alpha1, digit1, newline, space1};
use nom::combinator::{map, map_res};
use nom::multi::separated_list1;
use nom::sequence::{pair, preceded, separated_pair, terminated, tuple};
use nom::IResult;
use std::ops::Range;
use std::thread;

fn main() {
    let input = read_input(5);

    println!("Part 1: {}", part_1(&input));
    println!("Part 2: {}", part_2(&input));
}

fn part_1(input: &str) -> u64 {
    let (_, (seeds, maps)) = parse_input(input).unwrap();

    let mut min = u64::MAX;
    for mut seed in seeds {
        for map in &maps {
            seed = map.mapped(seed);
        }

        min = min.min(seed);
    }
    min
}

fn part_2(input: &str) -> u64 {
    let (_, (seeds, maps)) = parse_input_2(input).unwrap();

    let mut handles = Vec::new();
    let mp = MultiProgress::new();
    let style = ProgressStyle::with_template(
        "[{elapsed_precise}] {bar:40.cyan/blue} {percent}% ({human_pos:>7}/{human_len:7}) {msg}",
    )
    .unwrap();

    for (thread, seed_range) in seeds.into_iter().enumerate() {
        let maps = maps.clone();
        let total = seed_range.end - seed_range.start;
        let pb = mp.add(ProgressBar::new(total));
        pb.set_style(style.clone());

        handles.push(thread::spawn(move || {
            pb.set_message(format!("Thread {:?} working... ", thread + 1));
            let mut min = u64::MAX;

            let mut processed = 1;
            let percent = total / 100;
            for mut seed in seed_range {
                for map in &maps {
                    seed = map.mapped(seed);
                }

                if processed % percent == 0 {
                    pb.inc(percent);
                    pb.set_message(format!("Thread {:?} min: {}", thread + 1, HumanCount(min)));
                }
                processed += 1;

                min = min.min(seed);
            }
            pb.finish_with_message(format!("Min value: {}", HumanCount(min)));

            min
        }));
    }

    let mut min = u64::MAX;
    for handle in handles {
        let other = handle.join().unwrap();
        min = min.min(other);
    }

    min
}

#[derive(Debug, Clone)]
struct RangeMap {
    mappings: Vec<Mapping>,
}

impl RangeMap {
    fn mapped(&self, num: u64) -> u64 {
        for range in &self.mappings {
            if let Some(out) = range.mapped(num) {
                return out;
            }
        }

        num
    }
}

#[derive(Debug, Clone, Copy)]
struct Mapping {
    src: u64,
    dest: u64,
    len: u64,
}

impl Mapping {
    fn mapped(&self, num: u64) -> Option<u64> {
        if num < self.src || num >= self.src + self.len {
            None
        } else {
            let diff = num - self.src;

            Some(self.dest + diff)
        }
    }
}

fn parse_input(input: &str) -> IResult<&str, (Vec<u64>, Vec<RangeMap>)> {
    pair(terminated(parse_seeds, tag("\n\n")), parse_range_maps)(input)
}

#[allow(clippy::type_complexity)]
fn parse_input_2(input: &str) -> IResult<&str, (Vec<Range<u64>>, Vec<RangeMap>)> {
    pair(terminated(parse_seeds_2, tag("\n\n")), parse_range_maps)(input)
}

fn parse_seeds(input: &str) -> IResult<&str, Vec<u64>> {
    preceded(tag("seeds: "), separated_list1(space1, parse_num))(input)
}

fn parse_seeds_2(input: &str) -> IResult<&str, Vec<Range<u64>>> {
    preceded(
        tag("seeds: "),
        separated_list1(
            space1,
            map(separated_pair(parse_num, space1, parse_num), |(a, b)| {
                a..(a + b)
            }),
        ),
    )(input)
}

fn parse_range_maps(input: &str) -> IResult<&str, Vec<RangeMap>> {
    separated_list1(newline, parse_range_map)(input)
}

fn parse_range_map(input: &str) -> IResult<&str, RangeMap> {
    map(
        preceded(
            pair(separated_pair(alpha1, tag("-to-"), alpha1), tag(" map:\n")),
            terminated(separated_list1(newline, parse_mapping), newline),
        ),
        |ranges: Vec<Mapping>| RangeMap { mappings: ranges },
    )(input)
}

fn parse_mapping(input: &str) -> IResult<&str, Mapping> {
    map(
        tuple((
            terminated(parse_num, space1),
            terminated(parse_num, space1),
            parse_num,
        )),
        |(dest, src, len)| Mapping { src, dest, len },
    )(input)
}

fn parse_num(input: &str) -> IResult<&str, u64> {
    map_res(digit1, |ds: &str| ds.parse())(input)
}

#[cfg(test)]
mod tests {
    use crate::{part_1, part_2};
    use indoc::indoc;

    const TEST_INPUT: &str = indoc! {"
        seeds: 79 14 55 13
        
        seed-to-soil map:
        50 98 2
        52 50 48
        
        soil-to-fertilizer map:
        0 15 37
        37 52 2
        39 0 15
        
        fertilizer-to-water map:
        49 53 8
        0 11 42
        42 0 7
        57 7 4
        
        water-to-light map:
        88 18 7
        18 25 70
        
        light-to-temperature map:
        45 77 23
        81 45 19
        68 64 13
        
        temperature-to-humidity map:
        0 69 1
        1 0 69
        
        humidity-to-location map:
        60 56 37
        56 93 4
    "};

    #[test]
    fn test_part_1() {
        assert_eq!(35, part_1(TEST_INPUT));
    }

    #[test]
    fn test_part_2() {
        assert_eq!(46, part_2(TEST_INPUT));
    }
}
