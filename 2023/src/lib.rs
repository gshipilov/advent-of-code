use std::fs::File;
use std::io::{BufRead, BufReader, Read};

pub fn read_input_lines(day: u8) -> Vec<String> {
    let file = File::open(format!("inputs/day{day}.txt")).unwrap();
    let rdr = BufReader::new(file);

    rdr.lines().map(|l| l.unwrap()).collect()
}

pub fn read_input(day: u8) -> String {
    let mut file = File::open(format!("inputs/day{day}.txt")).unwrap();
    let mut buf = String::new();
    file.read_to_string(&mut buf).unwrap();

    buf
}
