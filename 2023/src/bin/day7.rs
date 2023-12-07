use aoc2023::read_input;
use nom::branch::alt;
use nom::character::complete::{char, digit1, multispace1, space1};
use nom::combinator::{map, map_res, value};
use nom::multi::{many_m_n, separated_list1};
use nom::sequence::separated_pair;
use nom::IResult;
use std::cmp::Ordering;
use std::collections::HashMap;

fn main() {
    let input = read_input(7);
    let (_, hands) = parse_hands(&input).unwrap();

    println!("Part 1: {}", part_1(hands));

    let (_, hands_with_jokers) = parse_hands_with_jokers(&input).unwrap();
    println!("Part 2: {}", part_2(hands_with_jokers));
}

fn part_1(mut hands: Vec<Hand>) -> u64 {
    hands.sort();

    hands
        .iter()
        .enumerate()
        .map(|(idx, hand)| (idx as u64 + 1) * hand.bet)
        .sum()
}

fn part_2(mut hands: Vec<HandWithJokers>) -> u64 {
    hands.sort();

    hands
        .iter()
        .enumerate()
        .map(|(idx, hand)| (idx as u64 + 1) * hand.bet)
        .sum()
}

#[derive(Debug, Clone)]
struct Hand {
    cards: Vec<Card>,
    bet: u64,
}

impl Hand {
    fn derive_type(&self) -> HandType {
        let buckets: HashMap<Card, u64> =
            self.cards.iter().fold(HashMap::new(), |mut acc, card| {
                *acc.entry(*card).or_default() += 1;
                acc
            });

        match buckets.len() {
            5 => HandType::HighCard,
            4 => HandType::OnePair,
            3 => {
                if buckets.values().any(|v| *v == 3) {
                    HandType::ThreeKind
                } else {
                    HandType::TwoPair
                }
            }
            2 => {
                if buckets.values().any(|v| *v == 4) {
                    HandType::FourKind
                } else {
                    HandType::FullHouse
                }
            }
            _ => HandType::FiveKind,
        }
    }

    fn raw_score(&self) -> u64 {
        self.cards
            .iter()
            .map(|c| *c as u64)
            .fold(0u64, |acc, score| acc * 100 + score)
    }
}

impl PartialEq for Hand {
    fn eq(&self, other: &Self) -> bool {
        if self.derive_type() == other.derive_type() {
            self.raw_score() == other.raw_score()
        } else {
            false
        }
    }
}

impl Eq for Hand {}

impl PartialOrd for Hand {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

impl Ord for Hand {
    fn cmp(&self, other: &Self) -> Ordering {
        let hand_cmp = self.derive_type().cmp(&other.derive_type());
        if hand_cmp != Ordering::Equal {
            return hand_cmp;
        }

        self.raw_score().cmp(&other.raw_score())
    }
}

#[derive(Debug, Clone, Copy, PartialOrd, PartialEq, Ord, Eq)]
enum HandType {
    HighCard = 1,
    OnePair = 2,
    TwoPair = 3,
    ThreeKind = 4,
    FullHouse = 5,
    FourKind = 6,
    FiveKind = 7,
}

#[derive(Debug, Clone, Copy, PartialOrd, PartialEq, Ord, Eq, Hash)]
enum Card {
    Two = 0,
    Three = 1,
    Four = 2,
    Five = 3,
    Six = 4,
    Seven = 5,
    Eight = 6,
    Nine = 7,
    Ten = 8,
    Jack = 9,
    Queen = 10,
    King = 11,
    Ace = 12,
}

fn parse_hands(input: &str) -> IResult<&str, Vec<Hand>> {
    separated_list1(multispace1, parse_hand)(input)
}

fn parse_hand(input: &str) -> IResult<&str, Hand> {
    map(
        separated_pair(parse_cards, space1, parse_num),
        |(cards, bet)| Hand { cards, bet },
    )(input)
}

fn parse_cards(input: &str) -> IResult<&str, Vec<Card>> {
    many_m_n(5, 5, parse_card)(input)
}

fn parse_num(input: &str) -> IResult<&str, u64> {
    map_res(digit1, |ds: &str| ds.parse())(input)
}

fn parse_card(input: &str) -> IResult<&str, Card> {
    alt((
        value(Card::Two, char('2')),
        value(Card::Three, char('3')),
        value(Card::Four, char('4')),
        value(Card::Five, char('5')),
        value(Card::Six, char('6')),
        value(Card::Seven, char('7')),
        value(Card::Eight, char('8')),
        value(Card::Nine, char('9')),
        value(Card::Ten, char('T')),
        value(Card::Jack, char('J')),
        value(Card::Queen, char('Q')),
        value(Card::King, char('K')),
        value(Card::Ace, char('A')),
    ))(input)
}

#[derive(Debug, Clone)]
struct HandWithJokers {
    cards: Vec<CardWithJoker>,
    bet: u64,
}

impl HandWithJokers {
    fn derive_type(&self) -> HandType {
        let mut buckets: HashMap<CardWithJoker, u64> =
            self.cards.iter().fold(HashMap::new(), |mut acc, card| {
                *acc.entry(*card).or_default() += 1;
                acc
            });

        let jokers = buckets.remove(&CardWithJoker::Joker).unwrap_or(0);

        match (buckets.len(), jokers) {
            (5, _) => HandType::HighCard,
            (4, _) => HandType::OnePair,
            (3, 0) => {
                if buckets.values().any(|v| *v == 3) {
                    HandType::ThreeKind
                } else {
                    HandType::TwoPair
                }
            }
            (3, _) => {
                // 3 misc + 2 jokers OR
                // 1 pair + 2 misc + 1 joker
                HandType::ThreeKind
            }
            (2, 0) => {
                if buckets.values().any(|v| *v == 4) {
                    HandType::FourKind
                } else {
                    HandType::FullHouse
                }
            }
            (2, 1) => {
                // 2 pair + joker => full house
                // 3kind + misc + joker => 4kind
                if buckets.values().any(|v| *v == 3) {
                    HandType::FourKind
                } else {
                    HandType::FullHouse
                }
            }
            (2, _) => {
                // 1 pair + 1 misc + 2 jokers OR
                // 2 misc + 3 jokers
                HandType::FourKind
            }
            _ => HandType::FiveKind,
        }
    }

    fn raw_score(&self) -> u64 {
        self.cards
            .iter()
            .map(|c| *c as u64)
            .fold(0u64, |acc, score| acc * 100 + score)
    }
}

impl PartialEq for HandWithJokers {
    fn eq(&self, other: &Self) -> bool {
        if self.derive_type() == other.derive_type() {
            self.raw_score() == other.raw_score()
        } else {
            false
        }
    }
}

impl Eq for HandWithJokers {}

impl PartialOrd for HandWithJokers {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

impl Ord for HandWithJokers {
    fn cmp(&self, other: &Self) -> Ordering {
        let hand_cmp = self.derive_type().cmp(&other.derive_type());
        if hand_cmp != Ordering::Equal {
            return hand_cmp;
        }

        self.raw_score().cmp(&other.raw_score())
    }
}

#[derive(Debug, Clone, Copy, PartialOrd, PartialEq, Ord, Eq, Hash)]
enum CardWithJoker {
    Joker = 0,
    Two = 1,
    Three = 2,
    Four = 3,
    Five = 4,
    Six = 5,
    Seven = 6,
    Eight = 7,
    Nine = 8,
    Ten = 9,
    Queen = 10,
    King = 11,
    Ace = 12,
}

fn parse_hands_with_jokers(input: &str) -> IResult<&str, Vec<HandWithJokers>> {
    separated_list1(multispace1, parse_hand_with_joker)(input)
}

fn parse_hand_with_joker(input: &str) -> IResult<&str, HandWithJokers> {
    map(
        separated_pair(parse_cards_with_joker, space1, parse_num),
        |(cards, bet)| HandWithJokers { cards, bet },
    )(input)
}

fn parse_cards_with_joker(input: &str) -> IResult<&str, Vec<CardWithJoker>> {
    many_m_n(5, 5, parse_card_with_joker)(input)
}

fn parse_card_with_joker(input: &str) -> IResult<&str, CardWithJoker> {
    alt((
        value(CardWithJoker::Joker, char('J')),
        value(CardWithJoker::Two, char('2')),
        value(CardWithJoker::Three, char('3')),
        value(CardWithJoker::Four, char('4')),
        value(CardWithJoker::Five, char('5')),
        value(CardWithJoker::Six, char('6')),
        value(CardWithJoker::Seven, char('7')),
        value(CardWithJoker::Eight, char('8')),
        value(CardWithJoker::Nine, char('9')),
        value(CardWithJoker::Ten, char('T')),
        value(CardWithJoker::Queen, char('Q')),
        value(CardWithJoker::King, char('K')),
        value(CardWithJoker::Ace, char('A')),
    ))(input)
}

#[cfg(test)]
mod tests {
    use crate::{parse_hands, parse_hands_with_jokers, part_1, part_2};
    use indoc::indoc;

    const TEST_INPUT: &str = indoc! {"
        32T3K 765
        T55J5 684
        KK677 28
        KTJJT 220
        QQQJA 483
    "};

    #[test]
    fn test_part1() {
        let (_, hands) = parse_hands(TEST_INPUT).unwrap();

        assert_eq!(6440, part_1(hands));
    }

    #[test]
    fn test_part2() {
        let (_, hands) = parse_hands_with_jokers(TEST_INPUT).unwrap();

        assert_eq!(5905, part_2(hands));
    }
}
