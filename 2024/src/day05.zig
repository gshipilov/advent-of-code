const std = @import("std");
const aoc = @import("lib.zig");

pub fn run(allocator: std.mem.Allocator, input: []const u8) !void {
    var parsed = try parseInput(allocator, input);
    defer {
        parsed.rules.deinit();
        aoc.deinitList(Update, parsed.updates);
    }

    std.debug.print("Part 1: {d}\n", .{try part1(allocator, &parsed.rules, parsed.updates.items)});
    std.debug.print("Part 2: {d}\n", .{try part2(allocator, &parsed.rules, parsed.updates.items)});
}

fn part1(allocator: std.mem.Allocator, rules: *const Rules, updates: []const Update) !usize {
    var total: usize = 0;

    for (updates) |update| {
        if (!try validateUpdate(allocator, rules, update.items)) {
            continue;
        }
        total += update.items[update.items.len / 2];
    }

    return total;
}

fn part2(allocator: std.mem.Allocator, rules: *const Rules, updates: []const Update) !usize {
    const Comparator = struct {
        fn lessThan(ctx: *const Rules, lhs: usize, rhs: usize) bool {
            if (ctx.values.get(lhs)) |rule| {
                for (rule.items) |rv| {
                    if (rv == rhs) {
                        return true;
                    }
                }
            }
            return false;
        }
    };

    var total: usize = 0;
    for (updates) |update| {
        if (try validateUpdate(allocator, rules, update.items)) {
            continue;
        }

        std.mem.sort(usize, update.items, rules, Comparator.lessThan);

        total += update.items[update.items.len / 2];
    }

    return total;
}

fn validateUpdate(allocator: std.mem.Allocator, rules: *const Rules, update: []const usize) !bool {
    var seen = std.AutoHashMap(usize, bool).init(allocator);
    defer seen.deinit();

    for (update) |page| {
        try seen.put(page, true);

        const rule = rules.values.get(page) orelse {
            continue;
        };

        for (rule.items) |rn| {
            if(seen.contains(rn)) {
                return false;
            }
        }
    }

    return true;
}

fn parseInput(allocator: std.mem.Allocator, input: []const u8) !struct {rules: Rules, updates: Updates} {
    var lines = std.mem.splitScalar(u8, input, '\n');

    var rules = Rules.init(allocator);
    errdefer rules.deinit();

    while(lines.next()) |line| {
        if (line.len == 0) {
            break;
        }

        var nums = std.mem.splitScalar(u8, line, '|');
        const first = try std.fmt.parseInt(usize, nums.next().?, 10);
        const second = try std.fmt.parseInt(usize, nums.next().?, 10);

        try rules.addRule(first, second);
    }

    var updates = Updates.init(allocator);
    errdefer aoc.deinitList(Update, updates);

    while(lines.next()) |line| {
        var update = Update.init(allocator);
        errdefer update.deinit();

        var nums = std.mem.splitScalar(u8, line, ',');
        while (nums.next()) |num_str| {
            const num = try std.fmt.parseInt(usize, num_str, 10);
            try update.append(num);
        }
        try updates.append(update);
    }

    return .{.rules = rules, .updates = updates};
}

const Update = std.ArrayList(usize);
const Updates = std.ArrayList(Update);

const Rules = struct {
    allocator: std.mem.Allocator,
    values: std.AutoHashMap(usize, std.ArrayList(usize)),

    const Self = @This();

    fn init(allocator: std.mem.Allocator) Self {
        const values = std.AutoHashMap(usize, std.ArrayList(usize)).init(allocator);

        return .{.allocator = allocator, .values = values};
    }

    fn deinit(self: *Self) void {
        var values = self.values.valueIterator();
        while (values.next()) |rule| {
            rule.deinit();
        }
        self.values.deinit();

        self.* = undefined;
    }

    fn addRule(self: *Self, first: usize, second: usize) !void {
        var entry = try self.values.getOrPut(first);
        if (!entry.found_existing) {
            var ruleList = std.ArrayList(usize).init(self.allocator);
            errdefer ruleList.deinit();

            try ruleList.append(second);

            entry.key_ptr.* = first;
            entry.value_ptr.* = ruleList;

            return;
        }

        try entry.value_ptr.append(second);
    }
};

const testInput =
    \\47|53
    \\97|13
    \\97|61
    \\97|47
    \\75|29
    \\61|13
    \\75|53
    \\29|13
    \\97|29
    \\53|29
    \\61|53
    \\97|53
    \\61|29
    \\47|13
    \\75|47
    \\97|75
    \\47|61
    \\75|61
    \\47|29
    \\75|13
    \\53|13
    \\
    \\75,47,61,53,29
    \\97,61,53,29,13
    \\75,29,13
    \\75,97,47,61,53
    \\61,13,29
    \\97,13,75,29,47
;

test "part 1" {
    var parsed = try parseInput(std.testing.allocator, testInput);
    defer {
        parsed.rules.deinit();
        aoc.deinitList(Update, parsed.updates);
    }

    const answer = try part1(std.testing.allocator, &parsed.rules, parsed.updates.items);
    std.debug.print("{d}\n", .{answer});
    try std.testing.expect(answer == 143);
}

test "part 2" {
    var parsed = try parseInput(std.testing.allocator, testInput);
    defer {
        parsed.rules.deinit();
        aoc.deinitList(Update, parsed.updates);
    }

    const answer = try part2(std.testing.allocator, &parsed.rules, parsed.updates.items);
    std.debug.print("{d}\n", .{answer});
    try std.testing.expect(answer == 123);
}
