use aoc2023::read_input;
use nom::branch::alt;
use nom::bytes::complete::tag;
use nom::character::complete::{alphanumeric1, char, multispace1, newline};
use nom::combinator::{map, value};
use nom::multi::{many_till, separated_list1};
use nom::sequence::{delimited, separated_pair};
use nom::IResult;
use num::Integer;
use std::collections::HashMap;

fn main() {
    let input = read_input(8);
    let (_, (path, graph)) = parse_instructions(&input).unwrap();

    println!("Part 1: {}", part_1(&path, &graph));
    println!("Part 2: {}", part_2(&path, &graph));
}

fn part_1(path: &Path, graph: &Graph) -> usize {
    let mut current = &("AAA".to_string());

    for (count, step) in path.iter().cycle().enumerate() {
        if current == "ZZZ" {
            return count;
        }

        let edges = graph.get(current).unwrap();
        if *step == Direction::Left {
            current = &edges.0;
        } else {
            current = &edges.1;
        }
    }

    unreachable!()
}

fn part_2(path: &Path, graph: &Graph) -> usize {
    let mut currents: Vec<_> = graph
        .keys()
        .filter(|g| g.ends_with('A'))
        .cloned()
        .map(Some)
        .collect();

    let mut steps: HashMap<String, usize> = HashMap::new();

    for (count, step) in path.iter().cycle().enumerate() {
        let mut done = true;
        for current_opt in currents.iter_mut() {
            if let Some(current) = current_opt {
                done = false;
                if current.ends_with('Z') {
                    steps.insert(current.clone(), count);
                    current_opt.take();
                    continue;
                }
                let edges = graph.get(current).unwrap();
                if *step == Direction::Left {
                    *current = edges.0.to_string();
                } else {
                    *current = edges.1.to_string();
                }
            }
        }
        if done {
            break;
        }
    }

    steps.values().fold(1, |a, b| a.lcm(b))
}

type Path = Vec<Direction>;
type Graph = HashMap<String, (String, String)>;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum Direction {
    Left,
    Right,
}

fn parse_instructions(input: &str) -> IResult<&str, (Path, Graph)> {
    separated_pair(parse_path, multispace1, parse_graph)(input)
}

fn parse_path(input: &str) -> IResult<&str, Path> {
    let (rest, (path, _)) = many_till(parse_direction, newline)(input)?;
    Ok((rest, path))
}

fn parse_direction(input: &str) -> IResult<&str, Direction> {
    alt((
        value(Direction::Left, char('L')),
        value(Direction::Right, char('R')),
    ))(input)
}

fn parse_graph(input: &str) -> IResult<&str, Graph> {
    map(separated_list1(newline, parse_node), |nodes| {
        nodes
            .into_iter()
            .fold(HashMap::new(), |mut acc, (k, (l, r))| {
                acc.insert(k.to_string(), (l.to_string(), r.to_string()));
                acc
            })
    })(input)
}

fn parse_node(input: &str) -> IResult<&str, (&str, (&str, &str))> {
    separated_pair(
        alphanumeric1,
        tag(" = "),
        delimited(
            char('('),
            separated_pair(alphanumeric1, tag(", "), alphanumeric1),
            char(')'),
        ),
    )(input)
}

#[cfg(test)]
mod tests {
    use crate::{parse_instructions, part_1, part_2};
    use indoc::indoc;

    const TEST_INPUT_A: &str = indoc! {"
        RL
        
        AAA = (BBB, CCC)
        BBB = (DDD, EEE)
        CCC = (ZZZ, GGG)
        DDD = (DDD, DDD)
        EEE = (EEE, EEE)
        GGG = (GGG, GGG)
        ZZZ = (ZZZ, ZZZ)
    "};

    const TEST_INPUT_B: &str = indoc! {"
        LLR

        AAA = (BBB, BBB)
        BBB = (AAA, ZZZ)
        ZZZ = (ZZZ, ZZZ)
    "};

    const TEST_INPUT_C: &str = indoc! {"
        LR

        11A = (11B, XXX)
        11B = (XXX, 11Z)
        11Z = (11B, XXX)
        22A = (22B, XXX)
        22B = (22C, 22C)
        22C = (22Z, 22Z)
        22Z = (22B, 22B)
        XXX = (XXX, XXX)
    "};

    #[test]
    fn test_parse() {
        let (_, (path, graph)) = parse_instructions(TEST_INPUT_A).unwrap();

        println!("PATH: {path:?}");
        println!("GRAPH: {graph:?}");
    }

    #[test]
    fn test_part_1() {
        let (_, (path, graph)) = parse_instructions(TEST_INPUT_A).unwrap();
        assert_eq!(2, part_1(&path, &graph));

        let (_, (path, graph)) = parse_instructions(TEST_INPUT_B).unwrap();
        assert_eq!(6, part_1(&path, &graph));
    }

    #[test]
    fn test_part_2() {
        let (_, (path, graph)) = parse_instructions(TEST_INPUT_C).unwrap();
        assert_eq!(6, part_2(&path, &graph));
    }
}
