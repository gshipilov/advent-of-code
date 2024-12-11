const std = @import("std");

pub fn run(allocator: std.mem.Allocator, input: []const u8) !void {
    var memo = std.AutoHashMap(BlinkKey, usize).init(allocator);
    defer memo.deinit();


    std.debug.print("Part 1: {d}\n", .{try expand(input, 25, &memo)});
    std.debug.print("Part 2: {d}\n", .{try expand(input, 75, &memo)});
}

fn expand(input: []const u8, blinks: usize, memo: *std.AutoHashMap(BlinkKey, usize)) !usize {
    var nums = std.mem.tokenize(u8, input, " \n");
    var total: usize = 0;
    while(nums.next()) |num_str| {
        const num = try std.fmt.parseInt(usize, num_str, 10);
        total += try countStones(blinks, num, memo);
    }

    return total;
}

const BlinkKey = struct {
    blinks: usize,
    num: usize,
};

fn countStones(blinks: usize, num: usize, memo: *std.AutoHashMap(BlinkKey, usize)) !usize {
    if (memo.get(.{.blinks = blinks, .num = num})) |found| {
        return found;
    }

    if (blinks == 0) {
        return 1;
    }

    var result: usize = 0;
    if (num == 0) {
        result = try countStones(blinks - 1, 1, memo);
    } else if (digits(num) % 2 == 0) {
        const mult = std.math.powi(usize, 10, digits(num) / 2) catch unreachable;

        result += try countStones(blinks - 1, num / mult, memo);
        result += try countStones(blinks - 1, num % mult, memo);
    } else {
        result = try countStones(blinks - 1, num * 2024, memo);
    }

    try memo.put(.{.blinks = blinks, .num = num}, result);

    return result;
}

fn digits(num: usize) usize {
    return std.math.log10(num) + 1;
}

test "part 1" {
    var memo = std.AutoHashMap(BlinkKey, usize).init(std.testing.allocator);
    defer memo.deinit();

    const answer = try expand("125 17", 25, &memo);
    std.debug.print("\nAnswer: {d}\n", .{answer});
    try std.testing.expect(answer == 55312);
}
