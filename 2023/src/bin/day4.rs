use aoc2023::read_input;
use nom::bytes::complete::tag;
use nom::character::complete::{digit1, newline, space1};
use nom::combinator::{map, map_res};
use nom::multi::separated_list1;
use nom::sequence::{delimited, pair, preceded, tuple};
use nom::IResult;

fn main() {
    let lines = read_input(4);

    println!("Part 1: {}", part_1(&lines));
    println!("Part 2: {}", part_2(&lines));
}
fn part_1(lines: &str) -> u32 {
    let (_, cards) = parse_cards(lines).unwrap();

    let mut total = 0;

    for card in cards {
        let mut points = 0;
        for have in card.have_nums {
            if card.winning_nums.contains(&have) {
                if points == 0 {
                    points = 1;
                } else {
                    points *= 2;
                }
            }
        }

        total += points;
    }

    total
}

fn part_2(lines: &str) -> usize {
    let (_, cards) = parse_cards(lines).unwrap();

    let mut ids: Vec<_> = cards.iter().map(|c| c.id).collect();
    let mut memo: Vec<Vec<u32>> = Vec::new();
    memo.push(Vec::new());

    for card in cards {
        let mut matches = 0;
        for have in card.have_nums {
            if card.winning_nums.contains(&have) {
                matches += 1;
            }
        }

        let mut gets = Vec::new();
        for i in 1..=matches {
            gets.push(card.id + i);
        }
        memo.push(gets);
    }

    let mut total = 0;

    while let Some(id) = ids.pop() {
        total += 1;
        for get in &memo[id as usize] {
            ids.push(*get);
        }
    }

    total
}

#[derive(Debug, Clone)]
struct Card {
    id: u32,
    winning_nums: Vec<u32>,
    have_nums: Vec<u32>,
}

fn parse_cards(input: &str) -> IResult<&str, Vec<Card>> {
    separated_list1(newline, parse_card)(input)
}

fn parse_card(input: &str) -> IResult<&str, Card> {
    map(
        tuple((
            delimited(pair(tag("Card"), space1), parse_num, tag(":")),
            preceded(space1, parse_num_list),
            preceded(delimited(space1, tag("|"), space1), parse_num_list),
        )),
        |(id, wins, haves)| Card {
            id,
            winning_nums: wins,
            have_nums: haves,
        },
    )(input)
}

fn parse_num_list(input: &str) -> IResult<&str, Vec<u32>> {
    separated_list1(space1, parse_num)(input)
}

fn parse_num(input: &str) -> IResult<&str, u32> {
    map_res(digit1, |s: &str| s.parse())(input)
}

#[cfg(test)]
mod tests {
    use crate::{part_1, part_2};
    use indoc::indoc;

    const TEST_INPUT: &str = indoc! {"
        Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53
        Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19
        Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1
        Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83
        Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36
        Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11
    "};

    #[test]
    fn test_part1() {
        assert_eq!(13, part_1(TEST_INPUT));
    }

    #[test]
    fn test_part2() {
        assert_eq!(30, part_2(TEST_INPUT));
    }
}
