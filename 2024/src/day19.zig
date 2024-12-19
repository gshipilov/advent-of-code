const std = @import("std");

pub fn run(allocator: std.mem.Allocator, input: []const u8) !void {
    std.debug.print("Part 1: {d}\n", .{try part1(allocator, input)});
    std.debug.print("Part 2: {d}\n", .{try part2(allocator, input)});
}

fn part1(allocator: std.mem.Allocator, input: []const u8) !usize {
    var parsed = try parseInput(allocator, input);
    defer {
        parsed.towels.deinit();
        parsed.patterns.deinit();
    }

    var total: usize = 0;
    for (parsed.patterns.items) |pattern| {
        if (try countPatternOptions(allocator, pattern, parsed.towels.items) > 0) {
            total += 1;
        }
    }

    return total;
}

fn part2(allocator: std.mem.Allocator, input: []const u8) !usize {
    var parsed = try parseInput(allocator, input);
    defer {
        parsed.towels.deinit();
        parsed.patterns.deinit();
    }

    var total: usize = 0;
    for (parsed.patterns.items) |pattern| {
        total += try countPatternOptions(allocator, pattern, parsed.towels.items);
    }

    return total;
}

fn countPatternOptions(allocator: std.mem.Allocator, pattern: []const u8, towels: []const []const u8) !usize {
    var table = try allocator.alloc(usize, pattern.len + 1);
    defer allocator.free(table);

    table[0] = 0;

    for (1..pattern.len + 1) |pi| {
        table[pi] = 0;

        const pattern_ss = pattern[0..pi];

        for (towels) |towel| {
            if (std.mem.endsWith(u8, pattern_ss, towel)) {
                if (towel.len == pattern_ss.len) {
                    table[pi] += 1;
                }

                table[pi] += table[pattern_ss.len - towel.len];
            }
        }
    }

    return table[pattern.len];
}

fn parseInput(allocator: std.mem.Allocator, input: []const u8) !struct {towels: std.ArrayList([]const u8), patterns: std.ArrayList([]const u8)} {
    var lines = std.mem.splitScalar(u8, input, '\n');

    var towels = std.ArrayList([]const u8).init(allocator);
    errdefer towels.deinit();

    const towel_line = lines.next().?;
    var towel_iter = std.mem.tokenize(u8, towel_line, ", ");
    while(towel_iter.next()) |towel| {
        try towels.append(towel);
    }

    _ = lines.next();

    var patterns = std.ArrayList([]const u8).init(allocator);
    errdefer patterns.deinit();

    while(lines.next()) |pattern| {
        try patterns.append(pattern);
    }

    return .{.towels = towels, .patterns = patterns};
}

const testInput =
    \\r, wr, b, g, bwu, rb, gb, br
    \\
    \\brwrr
    \\bggr
    \\gbbr
    \\rrbgbr
    \\ubwu
    \\bwurrg
    \\brgr
    \\bbrgwb
;

test "part 1" {
    try std.testing.expect(try part1(std.testing.allocator, testInput) == 6);
}

test "part 2" {
    try std.testing.expect(try part2(std.testing.allocator, testInput) == 16);
}
