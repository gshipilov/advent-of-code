fn main() {
    println!(
        "Part 1: {}",
        solve(&[(62, 644), (73, 1023), (75, 1240), (65, 1023)])
    );
    println!("Part 2: {}", solve(&[(62_737_565, 644_102_312_401_023)]));
}

fn solve(input: &[(u64, u64)]) -> usize {
    input
        .iter()
        .copied()
        .map(|(time, distance)| (1..time).filter(|a| (a * (time - a)) > distance).count())
        .product()
}

#[cfg(test)]
mod tests {
    use crate::solve;

    #[test]
    fn test_part_1() {
        assert_eq!(288, solve(&[(7, 9), (15, 40), (30, 200)]));
    }

    #[test]
    fn test_part_2() {
        assert_eq!(71503, solve(&[(71530, 940200)]));
    }
}
