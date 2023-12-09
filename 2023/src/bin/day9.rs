use aoc2023::read_input;
use std::convert::Infallible;
use std::str::FromStr;

fn main() {
    let input = read_input(9);
    let seqs: Vec<Seq> = input.lines().flat_map(|l| l.parse()).collect();

    println!("Part 1: {}", part_1(&seqs));
    println!("Part 2: {}", part_2(&seqs));
}

fn part_1(seqs: &[Seq]) -> i64 {
    seqs.iter().map(|s| s.next_num()).sum()
}

fn part_2(seqs: &[Seq]) -> i64 {
    seqs.iter().map(|s| s.prev_num()).sum()
}

struct Seq(Vec<i64>);

impl Seq {
    fn next_num(&self) -> i64 {
        if self.0.iter().all(|&v| v == 0) {
            return 0;
        }

        let ns = self.next_seq();
        let next_num = ns.next_num();

        *self.0.last().unwrap() + next_num
    }

    fn prev_num(&self) -> i64 {
        if self.0.iter().all(|&v| v == 0) {
            return 0;
        }

        let ns = self.next_seq();
        let prev_num = ns.prev_num();

        *self.0.first().unwrap() - prev_num
    }

    fn next_seq(&self) -> Self {
        let nums: Vec<i64> = self.0.windows(2).map(|ns| ns[1] - ns[0]).collect();

        Seq(nums)
    }
}

impl FromStr for Seq {
    type Err = Infallible;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let nums: Vec<i64> = s.split(' ').flat_map(|s| s.parse::<i64>()).collect();

        Ok(Seq(nums))
    }
}

#[cfg(test)]
mod tests {
    use crate::{part_1, part_2, Seq};
    use indoc::indoc;

    const TEST_INPUT: &str = indoc! {"
        0 3 6 9 12 15
        1 3 6 10 15 21
        10 13 16 21 30 45
    "};

    #[test]
    fn test_part_1() {
        let seqs: Vec<Seq> = TEST_INPUT.lines().flat_map(|l| l.parse()).collect();

        assert_eq!(114, part_1(&seqs));
    }

    #[test]
    fn test_part_2() {
        let seqs: Vec<Seq> = TEST_INPUT.lines().flat_map(|l| l.parse()).collect();

        assert_eq!(2, part_2(&seqs));
    }
}
