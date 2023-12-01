use std::fs::File;
use std::io::{BufRead, BufReader};

pub fn read_input(day: u8) -> Vec<String> {
    let file = File::open(format!("inputs/day{day}.txt")).unwrap();
    let rdr = BufReader::new(file);

    rdr.lines().map(|l| l.unwrap()).collect()
}
