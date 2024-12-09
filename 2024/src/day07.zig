const std = @import("std");
const aoc = @import("lib.zig");

pub fn run(allocator: std.mem.Allocator, input: []const u8) !void {
    var calibrations = try parseInput(allocator, input);
    defer {
        for (calibrations.items) |*calibration| {
            calibration.deinit();
        }
        calibrations.deinit();
    }

    std.debug.print("Part 1: {d}\n", .{try part1(allocator, calibrations.items)});
    std.debug.print("Part 2: {d}\n", .{try part2(allocator, calibrations.items)});
}

fn part1(allocator: std.mem.Allocator, calibrations: []const Calibration) !usize {
    var opSet = try buildOps(allocator, &[_]Op {addOp, multOp}, calibrations);
    defer {
        var values = opSet.valueIterator();
        while (values.next()) |value| {
            for (value.items) |inner| {
                inner.deinit();
            }

            value.deinit();
        }

        opSet.deinit();
    }

    var result: usize = 0;
    for (calibrations) |calibration| {
        if (calibration.check(&opSet.get(calibration.nums.items.len).?)) {
            result += calibration.target;
        }
    }

    return result;
}

fn part2(allocator: std.mem.Allocator, calibrations: []const Calibration) !usize {
    var opSet = try buildOps(allocator, &[_]Op {addOp, multOp, concatOp}, calibrations);
    defer {
        var values = opSet.valueIterator();
        while (values.next()) |value| {
            for (value.items) |inner| {
                inner.deinit();
            }

            value.deinit();
        }

        opSet.deinit();
    }

    var result: usize = 0;
    for (calibrations) |calibration| {
        if (calibration.check(&opSet.get(calibration.nums.items.len).?)) {
            result += calibration.target;
        }
    }

    return result;
}


const Calibration = struct {
    target: usize,
    nums: std.ArrayList(usize),

    fn deinit(self: *Calibration) void {
        self.nums.deinit();

        self.* = undefined;
    }

    fn check(self: *const Calibration, opList: *const std.ArrayList(OpList)) bool {
        for (opList.items) |opl| {
            if (Calibration.checkOne(self.nums.items, opl.items, self.target)) {
                return true;
            }
        }
        return false;
    }

    fn checkOne(nums: []const usize, ops: []const Op, target: usize) bool {
        var lhs = nums[0];
        for (0.., nums[1..]) |i, rhs| {
            lhs = ops[i](lhs, rhs);

            if (lhs > target) {
                return false;
            }
        }

        return target == lhs;
    }
};

fn parseInput(allocator: std.mem.Allocator, input: []const u8) !std.ArrayList(Calibration) {
    var result = std.ArrayList(Calibration).init(allocator);
    errdefer {
        for (result.items) |*calibration| {
            calibration.deinit();
        }
        result.deinit();
    }

    var lines = std.mem.splitScalar(u8, input, '\n');
    while(lines.next()) |line| {
        var parts = std.mem.splitScalar(u8, line, ':');
        const target = try std.fmt.parseInt(usize, parts.next().?, 10);

        var nums = std.ArrayList(usize).init(allocator);
        errdefer nums.deinit();

        var numIter = std.mem.tokenizeScalar(u8, parts.next().?, ' ');
        while(numIter.next()) |num_str| {
            try nums.append(try std.fmt.parseInt(usize, num_str, 10));
        }

        try result.append(Calibration {.target = target, .nums = nums});
    }

    return result;
}

fn buildOps(allocator: std.mem.Allocator, ops: []const Op, calibrations: []const Calibration) !std.AutoHashMap(usize, std.ArrayList(OpList)) {
    var result = std.AutoHashMap(usize, std.ArrayList(OpList)).init(allocator);
    errdefer {
        var values = result.valueIterator();
        while (values.next()) |value| {
            value.deinit();
        }

        result.deinit();
    }

    for (calibrations) |calibration| {
        const num_ops = calibration.nums.items.len;
        const entry = try result.getOrPut(num_ops);
        if (!entry.found_existing) {
            entry.value_ptr.* = try buildOpsInner(allocator, ops, num_ops - 1);
        }
    }

    return result;
}

fn buildOpsInner(allocator: std.mem.Allocator, ops: []const Op, len: usize) !std.ArrayList(OpList) {
    if (len == 0) {
        var result = std.ArrayList(OpList).init(allocator);
        errdefer aoc.deinitList(OpList, result);

        try result.append(OpList.init(allocator));
        return result;
    }

    const lists = try buildOpsInner(allocator, ops, len - 1);
    defer lists.deinit();

    var result = std.ArrayList(OpList).init(allocator);
    errdefer aoc.deinitList(OpList, result);

    for (lists.items) |list| {
        defer list.deinit();

        for (ops) |op| {
            var nl = try aoc.cloneList(Op, allocator, &list);
            errdefer nl.deinit();

            try nl.append(op);
            try result.append(nl);
        }
    }

    return result;
}

const Op = *const fn(l: usize, r: usize) usize;
const OpList = std.ArrayList(Op);

fn addOp(l: usize, r: usize) usize {
    return l + r;
}

fn multOp(l: usize, r: usize) usize {
    return l * r;
}

fn concatOp(l: usize, r: usize) usize {
    const pow = std.math.log10(r);
    const nl = l * (std.math.powi(usize, 10, pow + 1) catch unreachable);

    return nl + r;
}

const testInput =
    \\190: 10 19
    \\3267: 81 40 27
    \\83: 17 5
    \\156: 15 6
    \\7290: 6 8 6 15
    \\161011: 16 10 13
    \\192: 17 8 14
    \\21037: 9 7 18 13
    \\292: 11 6 16 20
;

test "part1" {
    var calibrations = try parseInput(std.testing.allocator, testInput);
    defer {
        for (calibrations.items) |*calibration| {
            calibration.deinit();
        }
        calibrations.deinit();
    }

    try std.testing.expect(try part1(std.testing.allocator, calibrations.items) == 3749);
}

test "part2" {
    var calibrations = try parseInput(std.testing.allocator, testInput);
    defer {
        for (calibrations.items) |*calibration| {
            calibration.deinit();
        }
        calibrations.deinit();
    }

    try std.testing.expect(try part2(std.testing.allocator, calibrations.items) == 11387);
}
