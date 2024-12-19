const std = @import("std");

pub fn run(allocator: std.mem.Allocator, input: []const u8) !void {
    var field = try Field.parse(allocator, input);
    defer field.deinit();

    std.debug.print("Part 1: {d}\n", .{try part1(allocator, &field)});
    std.debug.print("Part 2: {d}\n", .{try part2(allocator, &field)});
}

fn part1(allocator: std.mem.Allocator, field: *const Field) !usize {
    var seen = std.AutoHashMap(Point, void).init(allocator);
    defer seen.deinit();

    var point_sets = field.points.valueIterator();
    while(point_sets.next()) |ps| {
        for (0.., ps.items) |i, left| {
            for (ps.items[i+1..]) |right| {
                for (left.antinodes(right)) |antinode| {
                    if (antinode.x >= 0 and antinode.x < field.width and antinode.y >= 0 and antinode.y < field.height) {
                        try seen.put(antinode, {});
                    }
                }
            }
        }
    }

    return seen.count();
}

fn part2(allocator: std.mem.Allocator, field: *const Field) !usize {
    var seen = std.AutoHashMap(Point, void).init(allocator);
    defer seen.deinit();

    var point_sets = field.points.valueIterator();
    while(point_sets.next()) |ps| {
        for (0.., ps.items) |i, left| {
            for (ps.items[i+1..]) |right| {
                var resonant_antinodes = try left.resonant_antinodes(right, allocator, field.width, field.height);
                defer resonant_antinodes.deinit();

                for (resonant_antinodes.items) |antinode| {
                    try seen.put(antinode, {});
                }
            }
        }
    }

    return seen.count();
}

const Point = struct {
    x: isize,
    y: isize,

    fn antinodes(self: Point, other: Point) [2]Point {
        const dx = other.x - self.x;
        const dy = other.y - self.y;

        return [2]Point {
            .{.x = self.x - dx, .y = self.y - dy},
            .{.x = other.x + dx, .y = other.y + dy},
        };
    }

    fn resonant_antinodes(self: Point, other: Point, allocator: std.mem.Allocator, width: isize, height: isize) !std.ArrayList(Point) {
        var points = std.ArrayList(Point).init(allocator);
        errdefer points.deinit();

        try points.append(self);
        try points.append(other);

        const dx = other.x - self.x;
        const dy = other.y - self.y;

        var cx = other.x;
        var cy = other.y;

        while (true) {
            cx += dx;
            cy += dy;

            if (cx < 0 or cx >= width or cy < 0 or cy >= height) {
                break;
            }

            try points.append(.{.x = cx, .y = cy});
        }

        cx = self.x;
        cy = self.y;

        while (true) {
            cx -= dx;
            cy -= dy;

            if (cx < 0 or cx >= width or cy < 0 or cy >= height) {
                break;
            }

            try points.append(.{.x = cx, .y = cy});
        }

        return points;
    }
};

const Field = struct {
    points: std.AutoHashMap(u8, std.ArrayList(Point)),
    width: isize,
    height: isize,

    fn parse(allocator: std.mem.Allocator, input: []const u8) !Field {
        var points = std.AutoHashMap(u8, std.ArrayList(Point)).init(allocator);
        errdefer {
            var point_sets = points.valueIterator();
            while(point_sets.next()) |ps| {
                ps.deinit();
            }

            points.deinit();
        }

        var lines = std.mem.splitScalar(u8, input, '\n');
        var y: isize = 0;
        var width: isize = 0;
        while(lines.next()) |line| {
            var x: isize = 0;
            for (line) |c| {
                if (c == '.') {
                    x += 1;
                    continue;
                }

                var entry = try points.getOrPut(c);
                if (!entry.found_existing) {
                    entry.value_ptr.* = std.ArrayList(Point).init(allocator);
                }

                try entry.value_ptr.append(.{.x = x, .y = y});
                x += 1;
            }
            y += 1;
            width = @max(width, x);
        }

        return Field {.points = points, .width = width, .height = y};
    }

    fn deinit(self: *Field) void {
        var point_sets = self.points.valueIterator();
        while(point_sets.next()) |ps| {
            ps.deinit();
        }

        self.points.deinit();
        self.* = undefined;
    }
};

const testInput =
    \\............
    \\........0...
    \\.....0......
    \\.......0....
    \\....0.......
    \\......A.....
    \\............
    \\............
    \\........A...
    \\.........A..
    \\............
    \\............
;

test "part1" {
    var field = try Field.parse(std.testing.allocator, testInput);
    defer field.deinit();

    const answer = try part1(std.testing.allocator, &field);
    try std.testing.expect(answer == 14);
}

test "part2" {
    var field = try Field.parse(std.testing.allocator, testInput);
    defer field.deinit();

    const answer = try part2(std.testing.allocator, &field);
    try std.testing.expect(answer == 34);
}
