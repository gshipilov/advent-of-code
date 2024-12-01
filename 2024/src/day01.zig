const std = @import("std");

pub fn run(allocator: std.mem.Allocator, input: []const u8) !void {
    std.debug.print("Part 1: {any}\n", .{try part1(allocator, input)});
    std.debug.print("Part 2: {any}\n", .{try part2(allocator, input)});
}

fn part1(allocator: std.mem.Allocator, input: []const u8) !isize {
    const lists = try parseInput(allocator, input);
    defer {
        lists.left.deinit();
        lists.right.deinit();
    }

    var total: isize = 0;
    for (lists.left.items, lists.right.items) |lv, rv| {
        const diff: isize = @intCast(@abs(lv - rv));
        total += diff;
    }

    return total;
}

fn part2(allocator: std.mem.Allocator, input: []const u8) !isize {
    const lists = try parseInput(allocator, input);
    defer {
        lists.left.deinit();
        lists.right.deinit();
    }

    var total: isize = 0;
    for (lists.left.items) |lv| {
        var count: isize = 0;
        for (lists.right.items) |rv| {
            if (lv == rv) {
                count += 1;
            } else if (rv > lv) {
                break;
            }
        }
        total += lv * count;
    }

    return total;
}

fn parseInput(allocator: std.mem.Allocator, input: []const u8) !struct { left: std.ArrayList(isize), right: std.ArrayList(isize) } {
    var left = std.ArrayList(isize).init(allocator);
    var right = std.ArrayList(isize).init(allocator);

    errdefer {
        left.deinit();
        right.deinit();
    }

    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        var tokens = std.mem.tokenizeScalar(u8, line, ' ');
        const ln = try std.fmt.parseInt(isize, tokens.next().?, 10);
        const rn = try std.fmt.parseInt(isize, tokens.next().?, 10);

        try left.append(ln);
        try right.append(rn);
    }

    std.mem.sort(isize, left.items, {}, std.sort.asc(isize));
    std.mem.sort(isize, right.items, {}, std.sort.asc(isize));

    return .{
        .left = left,
        .right = right,
    };
}

const testInput =
    \\3   4
    \\4   3
    \\2   5
    \\1   3
    \\3   9
    \\3   3
;

test "part1" {
    const answer = part1(std.testing.allocator, testInput);
    try std.testing.expect(try answer == 11);
}

test "part2" {
    const answer = part2(std.testing.allocator, testInput);
    try std.testing.expect(try answer == 31);
}
