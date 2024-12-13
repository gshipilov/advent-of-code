const std = @import("std");

pub fn run(allocator: std.mem.Allocator, input: []const u8) !void {
    std.debug.print("Part 1: {d}\n", .{try part1(allocator, input)});
    std.debug.print("Part 2: {d}\n", .{try part2(allocator, input)});
}

fn part1(allocator: std.mem.Allocator, input: []const u8) !usize {
    const machines = try parseInput(allocator, input);
    defer machines.deinit();

    var total: isize = 0;

    for (machines.items) |machine| {
        if (solve(machine.tx, machine.ty, machine.a, machine.b)) |result| {
            total += result.ta * 3 + result.tb;
        }
    }

    return @intCast(total);
}

fn part2(allocator: std.mem.Allocator, input: []const u8) !usize {
    const machines = try parseInput(allocator, input);
    defer machines.deinit();

    const correction: isize = 10000000000000;

    var total: isize = 0;

    for (machines.items) |machine| {
        if (solve(correction + machine.tx, correction + machine.ty, machine.a, machine.b)) |result| {
            total += result.ta * 3 + result.tb;
        }
    }

    return @intCast(total);
}

const Button = struct {
    x: isize,
    y: isize,
};

const Machine = struct {
    a: Button,
    b: Button,
    tx: isize,
    ty: isize,
};

fn solve(tx: isize, ty: isize, a: Button, b: Button) ?struct {ta: isize, tb: isize} {
    // solve tb
    const numer: isize = a.y * tx - a.x * ty;
    const denom: isize = a.y * b.x - a.x * b.y;

    const tb = std.math.divExact(isize, numer,  denom) catch return null;

    // substitute tb to solve ta
    const ta = std.math.divExact(isize, (tx - b.x * tb), a.x) catch return null;

    return .{.ta = ta, .tb = tb};
}

fn parseInput(allocator: std.mem.Allocator, input: []const u8) !std.ArrayList(Machine) {
    var machines = std.ArrayList(Machine).init(allocator);
    errdefer machines.deinit();

    var chunks = std.mem.split(u8, input, "\n\n");
    while (chunks.next()) |chunk| {
        try machines.append(try parseMachine(chunk));
    }

    return machines;
}

fn parseMachine(input: []const u8) !Machine {
    var lines = std.mem.splitScalar(u8, input, '\n');
    const a = try parseButton(lines.next().?);
    const b = try parseButton(lines.next().?);
    const prize = try parsePrize(lines.next().?);

    return Machine {.a = a, .b = b, .tx = prize.tx, .ty = prize.ty};
}

fn parseButton(input: []const u8) !Button {
    var tokens = std.mem.tokenize(u8, input, "+,");
    // Discard prefix.
    _ = tokens.next(); // "Button A: X+"

    const x = try std.fmt.parseInt(isize, tokens.next().?, 10);

    _ = tokens.next(); // ", Y+"

    const y = try std.fmt.parseInt(isize, tokens.next().?, 10);

    return .{ .x = x, .y = y};
}

fn parsePrize(input: []const u8) !struct{tx: isize, ty: isize} {
    var tokens = std.mem.tokenize(u8, input, "=,");

    // Discard prefix.
    _ = tokens.next(); // "Prize: X="

    const tx = try std.fmt.parseInt(isize, tokens.next().?, 10);

    _ = tokens.next(); // ", Y="

    const ty = try std.fmt.parseInt(isize, tokens.next().?, 10);

    return .{.tx = tx, .ty = ty};
}

const testInput =
    \\Button A: X+94, Y+34
    \\Button B: X+22, Y+67
    \\Prize: X=8400, Y=5400
    \\
    \\Button A: X+26, Y+66
    \\Button B: X+67, Y+21
    \\Prize: X=12748, Y=12176
    \\
    \\Button A: X+17, Y+86
    \\Button B: X+84, Y+37
    \\Prize: X=7870, Y=6450
    \\
    \\Button A: X+69, Y+23
    \\Button B: X+27, Y+71
    \\Prize: X=18641, Y=10279
;

test "part1" {
    const answer = try part1(std.testing.allocator, testInput);
    std.debug.print("\nAnswer: {d}\n", .{answer});
    try std.testing.expect(answer == 480);
}
