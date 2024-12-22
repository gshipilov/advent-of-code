const std = @import("std");

pub fn run(allocator: std.mem.Allocator, input: []const u8) !void {
    var grid = try Grid.parse(allocator, input);
    defer grid.deinit();

    std.debug.print("Part 1: {d}\n", .{try findCheatSaves(allocator, &grid, 2, 100)});
    std.debug.print("Part 2: {d}\n", .{try findCheatSaves(allocator, &grid, 20, 100)});
}

fn findCheatSaves(allocator: std.mem.Allocator, grid: *const Grid, max_cheat_len: usize, target_distance: usize) !usize {
    var distances = try countDistances(allocator, grid);
    defer distances.deinit();

    var cheats = try countCheats(allocator, grid.start, &distances, max_cheat_len);
    defer cheats.deinit();

    const maxDist = distances.get(grid.start).?;
    var total: usize = 0;

    var ents = cheats.iterator();
    while (ents.next()) |ent| {
        const cheatDist = ent.value_ptr.*;
        if (cheatDist > maxDist) {
            continue;
        }
        if (maxDist - cheatDist >= target_distance) {
            total += 1;
        }
    }

    return total;
}

fn countDistances(allocator: std.mem.Allocator, grid: *const Grid) !std.AutoHashMap(Point, usize) {
    var result = std.AutoHashMap(Point, usize).init(allocator);
    errdefer result.deinit();

    var seen = std.AutoHashMap(Point, void).init(allocator);
    defer seen.deinit();

    var current = grid.end;
    var dist: usize = 0;

    outer: while (true) {
        try result.put(current, dist);
        try seen.put(current, {});

        if (std.meta.eql(current, grid.start)) {
            break;
        }

        dist += 1;

        for (current.neighbors(1)) |neighbor| {
            if (grid.cell(neighbor)) |nct| {
                if (nct == .Space) {
                    if (seen.contains(neighbor)) {
                        continue;
                    } else {
                        current = neighbor;
                        continue :outer;
                    }
                }
            }
        }
    }

    return result;
}

fn countCheats(allocator: std.mem.Allocator, start: Point, distances: *const std.AutoHashMap(Point, usize), max_cheat_len: usize) !std.AutoHashMap(Cheat, usize) {
    const maxDistance = distances.get(start).?;

    var cheats = std.AutoHashMap(Cheat, usize).init(allocator);
    errdefer cheats.deinit();

    var ents = distances.iterator();
    while (ents.next()) |ent| {
        var neighbors = try ent.key_ptr.manhattan_neighbors(allocator, max_cheat_len);
        defer neighbors.deinit();

        for (neighbors.items) |neighbor| {
            if (distances.get(neighbor)) |neighbor_distance| {
                const cheat = Cheat{ .start = ent.key_ptr.*, .end = neighbor };
                const mhd = @abs(ent.key_ptr.*.x - neighbor.x) + @abs(ent.key_ptr.*.y - neighbor.y);
                try cheats.put(cheat, maxDistance - ent.value_ptr.* + neighbor_distance + mhd);
            }
        }
    }

    return cheats;
}

const Cheat = struct {
    start: Point,
    end: Point,

    pub fn format(
        self: Cheat,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;

        try writer.print("{s} -> {s}", .{ self.start, self.end });
    }
};

const Point = struct {
    x: isize,
    y: isize,

    fn neighbors(self: Point, dist: isize) [4]Point {
        return [4]Point{
            .{ .x = self.x, .y = self.y - dist }, // Up
            .{ .x = self.x + dist, .y = self.y }, // Right
            .{ .x = self.x, .y = self.y + dist }, // Down
            .{ .x = self.x - dist, .y = self.y }, // Left
        };
    }

    fn manhattan_neighbors(self: Point, allocator: std.mem.Allocator, dist: usize) !std.ArrayList(Point) {
        var result = std.ArrayList(Point).init(allocator);
        errdefer result.deinit();

        var dy: isize = @as(isize, @intCast(dist)) * -1;
        while (dy <= dist) : (dy += 1) {
            const dxlim: isize = @as(isize, @intCast(dist)) - @as(isize, @intCast(@abs(dy)));
            var dx = dxlim * -1;
            while (dx <= dxlim) : (dx += 1) {
                if (dy == 0 and dx == 0) {
                    continue;
                }

                try result.append(Point{ .x = self.x + dx, .y = self.y + dy });
            }
        }

        return result;
    }

    pub fn format(
        self: Point,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;

        try writer.print("({d}, {d})", .{ self.x, self.y });
    }
};

const CellType = enum {
    Space,
    Wall,
};

const Row = std.ArrayList(CellType);

const Grid = struct {
    rows: std.ArrayList(Row),
    width: isize,
    height: isize,
    start: Point,
    end: Point,

    const Self = @This();

    fn parse(allocator: std.mem.Allocator, input: []const u8) !Self {
        var rows = std.ArrayList(Row).init(allocator);
        errdefer {
            for (rows.items) |row| {
                row.deinit();
            }
            rows.deinit();
        }

        var lines = std.mem.splitScalar(u8, input, '\n');
        var start: Point = undefined;
        var end: Point = undefined;

        var y: isize = 0;
        while (lines.next()) |line| {
            var row = Row.init(allocator);
            errdefer row.deinit();

            var x: isize = 0;
            for (line) |c| {
                switch (c) {
                    '.' => try row.append(.Space),
                    '#' => try row.append(.Wall),
                    'S' => {
                        start = .{ .x = x, .y = y };
                        try row.append(.Space);
                    },
                    'E' => {
                        end = .{ .x = x, .y = y };
                        try row.append(.Space);
                    },
                    else => unreachable,
                }
                x += 1;
            }
            try rows.append(row);
            y += 1;
        }

        return .{ .rows = rows, .width = @intCast(rows.items[0].items.len), .height = @intCast(rows.items.len), .start = start, .end = end };
    }

    fn deinit(self: *Self) void {
        for (self.rows.items) |row| {
            row.deinit();
        }
        self.rows.deinit();
        self.* = undefined;
    }

    fn cell(self: *const Self, point: Point) ?CellType {
        if (point.x < 0 or point.x >= self.width or point.y < 0 or point.y >= self.height) {
            return null;
        }

        return self.rows.items[@intCast(point.y)].items[@intCast(point.x)];
    }
};
