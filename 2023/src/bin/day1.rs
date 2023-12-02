use aoc2023::read_input_lines;

fn digits(line: &str) -> Vec<u32> {
    line.chars()
        .filter(|c| c.is_ascii_digit())
        .map(|c| c.to_digit(10).unwrap())
        .collect()
}

fn part_1(lines: &[String]) -> u32 {
    lines
        .iter()
        .map(|s| digits(s))
        .map(|v| v.first().unwrap() * 10 + v.last().unwrap())
        .sum()
}

fn digits_text(line: &str) -> Vec<u32> {
    let mut out = Vec::new();

    for (i, c) in line.chars().enumerate() {
        if c.is_ascii_digit() {
            out.push(c.to_digit(10).unwrap());
            continue;
        }

        const PAT_NUM: [(&str, u32); 10] = [
            ("zero", 0),
            ("one", 1),
            ("two", 2),
            ("three", 3),
            ("four", 4),
            ("five", 5),
            ("six", 6),
            ("seven", 7),
            ("eight", 8),
            ("nine", 9),
        ];

        for (pat, num) in PAT_NUM {
            if line[i..].starts_with(pat) {
                out.push(num);
                break;
            }
        }
    }

    out
}

fn part_2(lines: &[String]) -> u32 {
    lines
        .iter()
        .map(|s| digits_text(s))
        .map(|v| v.first().unwrap() * 10 + v.last().unwrap())
        .sum()
}

fn main() {
    let lines = read_input_lines(1);

    println!("Part 1: {}", part_1(&lines));
    println!("Part 2: {}", part_2(&lines));
}
