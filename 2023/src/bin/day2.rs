use aoc2023::read_input;
use nom::branch::alt;
use nom::bytes::complete::tag;
use nom::character::complete::{digit1, newline, space1};
use nom::combinator::{map, map_res, value};
use nom::multi::separated_list1;
use nom::sequence::{preceded, separated_pair};
use nom::IResult;
use std::collections::HashMap;

fn main() {
    let input = read_input(2);

    let (_, games) = parse_games(&input).unwrap();

    println!("Part 1: {}", part_1(&games));
    println!("Part 2: {}", part_2(&games));
}

fn part_1(games: &[Game]) -> u32 {
    let totals: HashMap<Color, u32> =
        HashMap::from([(Color::Red, 12), (Color::Green, 13), (Color::Blue, 14)]);

    let mut out = 0;

    for game in games {
        out += game.id;
        'rounds: for round in &game.rounds {
            for (num, color) in &round.picks {
                let total = totals.get(color).unwrap();

                if num > total {
                    out -= game.id;
                    break 'rounds;
                }
            }
        }
    }

    out
}

fn part_2(games: &[Game]) -> u32 {
    let mut total_power = 0;

    for game in games {
        let mut mins = HashMap::new();

        for round in &game.rounds {
            for (num, color) in &round.picks {
                let current = mins.entry(*color).or_insert(*num);
                if *current < *num {
                    *current = *num;
                }
            }
        }

        total_power += mins.values().product::<u32>();
    }

    total_power
}

#[derive(Debug, Clone, PartialEq, Eq)]
struct Game {
    id: u32,
    rounds: Vec<Round>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
struct Round {
    picks: Vec<(u32, Color)>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
enum Color {
    Red,
    Green,
    Blue,
}

fn parse_games(input: &str) -> IResult<&str, Vec<Game>> {
    separated_list1(newline, parse_game)(input)
}

fn parse_game(input: &str) -> IResult<&str, Game> {
    map(
        separated_pair(preceded(tag("Game "), parse_num), tag(": "), parse_rounds),
        |(id, rounds)| Game { id, rounds },
    )(input)
}

fn parse_rounds(input: &str) -> IResult<&str, Vec<Round>> {
    separated_list1(tag("; "), parse_round)(input)
}

fn parse_round(input: &str) -> IResult<&str, Round> {
    map(separated_list1(tag(", "), parse_pick), |picks| Round {
        picks,
    })(input)
}

fn parse_pick(input: &str) -> IResult<&str, (u32, Color)> {
    separated_pair(parse_num, space1, parse_color)(input)
}

fn parse_color(input: &str) -> IResult<&str, Color> {
    alt((
        value(Color::Red, tag("red")),
        value(Color::Green, tag("green")),
        value(Color::Blue, tag("blue")),
    ))(input)
}

fn parse_num(input: &str) -> IResult<&str, u32> {
    map_res(digit1, |ds: &str| ds.parse())(input)
}

#[cfg(test)]
mod tests {
    use crate::{parse_games, part_1, part_2};
    use indoc::indoc;

    const TEST_INPUT: &str = indoc! {"
        Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
        Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
        Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
        Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
        Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
    "};

    #[test]
    fn test_part_1() {
        let (_, games) = parse_games(TEST_INPUT).unwrap();

        assert_eq!(8, part_1(&games));
    }

    #[test]
    fn test_part_2() {
        let (_, games) = parse_games(TEST_INPUT).unwrap();

        assert_eq!(2286, part_2(&games));
    }
}
