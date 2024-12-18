const std = @import("std");

pub fn run(allocator: std.mem.Allocator, input: []const u8) !void {
    std.debug.print("Part 1: {d}\n", .{(try part1(allocator, input, 1024, 71))});

    const p2_point = try part2(allocator, input, 1024, 71);
    std.debug.print("Part 2: {d},{d}\n", .{p2_point.x, p2_point.y});
}

fn part1(allocator: std.mem.Allocator, input: []const u8, falls: usize, comptime dim: comptime_int) !usize {
    var g = Grid(dim){};

    var points = try parseInput(allocator, input);
    defer points.deinit();
    
    g.corrupt(points.items[0..falls]);

    return (try dijkstra(dim, allocator, &g, .{.x = 0, .y = 0}, .{.x = dim - 1, .y = dim - 1})).?;
}

fn part2(allocator: std.mem.Allocator, input: []const u8, start: usize, comptime dim: comptime_int) !Point {
    var points = try parseInput(allocator, input);
    defer points.deinit();

    for(start..(points.items.len - 1)) |lim| {
        var g = Grid(dim){};

        g.corrupt(points.items[0..lim]);

        if (try dijkstra(dim, allocator, &g, .{.x = 0, .y = 0}, .{.x = dim - 1, .y = dim - 1})) |_| {
            continue;
        } else {
            return points.items[lim - 1];
        }
    }

    unreachable;
}

fn compareCost(ctx: *std.AutoHashMap(Point, usize), a: Point, b: Point) std.math.Order {
    const ac = ctx.get(a) orelse std.math.maxInt(usize);
    const bc = ctx.get(b) orelse std.math.maxInt(usize);

    return std.math.order(ac, bc);
}

fn dijkstra(comptime dim: comptime_int, allocator: std.mem.Allocator, grid: *const Grid(dim), start: Point, end: Point) !?usize {
    var ctx = std.AutoHashMap(Point, usize).init(allocator);
    defer ctx.deinit();

    try ctx.put(start, 0);

    var queue = std.PriorityQueue(Point, *std.AutoHashMap(Point, usize), compareCost).init(allocator, &ctx);
    defer queue.deinit();

    try queue.add(start);
    while (queue.removeOrNull()) |point| {
        const point_cost = ctx.get(point).?;

        for (point.neighbors()) |neighbor| {
            if (grid.cell(neighbor)) |nc| {
                if (nc == .Corrupt) {
                    continue;
                }

                if (ctx.get(neighbor)) |neighbor_cost| {
                    if (neighbor_cost <= point_cost + 1) {
                        continue;
                    }

                    try ctx.put(neighbor, point_cost + 1);
                    try queue.update(neighbor, neighbor);
                } else {
                    try ctx.put(neighbor, point_cost + 1);
                    try queue.add(neighbor);
                }

                if (std.meta.eql(neighbor, end)) {
                    return ctx.get(neighbor).?;
                }
            }
        }
    }

    return null;
}

const Cell = enum {
    Free,
    Corrupt,
};

const Point = struct {
    x: isize,
    y: isize,

    fn neighbors(self: *const Point) [4]Point {
        return [4]Point {
            .{.x = self.x, .y = self.y - 1}, // Up
            .{.x = self.x + 1, .y = self.y}, // Right
            .{.x = self.x, .y = self.y + 1}, // Down
            .{.x = self.x - 1, .y = self.y}, // Left
        };
    }

    fn parse(line: []const u8) !Point {
        var parts = std.mem.splitScalar(u8, line, ',');

        return .{
            .x = try std.fmt.parseInt(isize, parts.next().?, 10),
            .y = try std.fmt.parseInt(isize, parts.next().?, 10),
        };
    }
};

fn Grid(comptime dim: comptime_int) type {
    return struct {
        cells: [dim][dim]Cell = [_][dim]Cell {[_]Cell{.Free} ** dim} ** dim,
        dim: usize = dim,

        const Self = @This();

        fn corrupt(self: *Self, points: []Point) void {
            for (points) |point| {
                self.cells[@intCast(point.y)][@intCast(point.x)] = .Corrupt;
            }
        }

        fn cell(self: *const Self, point: Point) ?Cell {
            if (point.x < 0 or point.x >= dim or point.y < 0 or point.y >= dim) {
                return null;
            }

            return self.cells[@intCast(point.y)][@intCast(point.x)];
        }
    };
}

fn parseInput(allocator: std.mem.Allocator, input: []const u8) !std.ArrayList(Point) {
    var result = std.ArrayList(Point).init(allocator);
    errdefer result.deinit();

    var lines = std.mem.splitScalar(u8, input, '\n');
    while(lines.next()) |line| {
        try result.append(try Point.parse(line));
    }

    return result;
}

const testInput =
    \\5,4
    \\4,2
    \\4,5
    \\3,0
    \\2,1
    \\6,3
    \\2,4
    \\1,5
    \\0,6
    \\3,3
    \\2,6
    \\5,1
    \\1,2
    \\5,5
    \\2,5
    \\6,5
    \\1,4
    \\0,4
    \\6,4
    \\1,1
    \\6,1
    \\1,0
    \\0,5
    \\1,6
    \\2,0
;

test "part 1" {
    const answer = try part1(std.testing.allocator, testInput, 12, 7);
    try std.testing.expect(answer == 22);
}

test "part 2" {
    const answer = try part2(std.testing.allocator, testInput, 0, 7);
    try std.testing.expect(std.meta.eql(answer, .{.x = 6, .y = 1}));
}
