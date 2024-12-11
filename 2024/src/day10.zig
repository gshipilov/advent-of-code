const std = @import("std");

pub fn run(allocator: std.mem.Allocator, input: []const u8) !void {
    var grid = try Grid.init(allocator, input);
    defer grid.deinit();

    std.debug.print("Part 1: {d}\n", .{try part1(&grid)});
    std.debug.print("Part 2: {d}\n", .{try part2(&grid)});
}

fn part1(grid: *const Grid) !usize {
    var total: usize = 0;

    var trailheads = grid.trailheads();
    while(trailheads.next()) |trailhead| {
        total += try grid.computeTrailScore(trailhead);
    }

    return total;
}

fn part2(grid: *const Grid) !usize {
    var total: usize = 0;

    var trailheads = grid.trailheads();
    while(trailheads.next()) |trailhead| {
        var trails = try grid.findTrails(trailhead);
        defer {
            for (trails.items) |trail| {
                trail.deinit();
            }

            trails.deinit();
        }

        total += trails.items.len;
    }

    return total;
}

const Dir = enum {
    Up,
    Right,
    Down,
    Left,

    fn dx(self: Dir) isize {
        return switch (self) {
            .Up, .Down => 0,
            .Right => 1,
            .Left => -1,
        };
    }

    fn dy(self: Dir) isize {
        return switch (self) {
            .Left, .Right => 0,
            .Up => -1,
            .Down => 1,
        };
    }

    fn values() [4]Dir {
        return [_]Dir {.Up, .Right, .Down, .Left};
    }
};

const Coord = struct {
    x: isize,
    y: isize,

    fn move(self: Coord, dx: isize, dy: isize) Coord {
        return .{.x = self.x + dx, .y = self.y + dy};
    }
};

const Path = std.ArrayList(Coord);

fn HashSet(comptime T: type) type {
    return std.AutoHashMap(T, void);
}

const Grid = struct {
    allocator: std.mem.Allocator,
    width: isize,
    height: isize,

    grid: std.ArrayList(std.ArrayList(u8)),

    const Self = @This();

    fn init(allocator: std.mem.Allocator, input: []const u8) !Self {
        var width: isize = 0;
        var height: isize = 0;

        var grid = std.ArrayList(std.ArrayList(u8)).init(allocator);
        errdefer {
            for (grid.items) |row| {
                row.deinit();
            }

            grid.deinit();
        }

        var lines = std.mem.splitScalar(u8, input, '\n');
        while(lines.next()) |line| {
            var row = std.ArrayList(u8).init(allocator);
            errdefer row.deinit();

            for (line) |char| {
                try row.append(char - '0');
            }

            try grid.append(row);
            height += 1;
        }
        width = @intCast(grid.items[0].items.len);

        return .{.allocator = allocator, .width = width, .height = height, .grid = grid};
    }

    fn deinit(self: *Self) void {
        for (self.grid.items) |row| {
            row.deinit();
        }
        self.grid.deinit();

        self.* = undefined;
    }

    fn trailheads(self: *const Self) TrailheadIter {
        return .{.grid = self};
    }

    fn computeTrailScore(self: *const Self, coord: Coord) !usize {
        var ends = HashSet(Coord).init(self.allocator);
        defer ends.deinit();

        var trails = try self.findTrails(coord);
        defer {
            for (trails.items) |path| {
                path.deinit();
            }
            trails.deinit();
        }

        for (trails.items) |trail| {
            try ends.put(trail.getLast(), {});
        }

        return ends.count();
    }

    fn findTrails(self: *const Self, coord: Coord) !std.ArrayList(Path) {
        const init_path = [0]Coord{};
        return try self.findTrailsInner(coord, &init_path) orelse std.ArrayList(Path).init(self.allocator);
    }

    fn findTrailsInner(self: *const Self, coord: Coord, path: []Coord) !?std.ArrayList(Path) {
        for (path) |seen| {
            if (std.meta.eql(coord, seen)) {
                return null;
            }
        }

        var result = std.ArrayList(Path).init(self.allocator);
        errdefer {
            for (result.items) |p| {
                p.deinit();
            }

            result.deinit();
        }

        var new_path = std.ArrayList(Coord).init(self.allocator);
        defer new_path.deinit();

        try new_path.appendSlice(path);
        try new_path.append(coord);

        const this_cell = self.cell(coord) orelse return null;

        if (this_cell == 9) {
            try result.append(try new_path.clone());
            return result;
        }

        for (Dir.values()) |dir| {
            const next_coord = coord.move(dir.dx(), dir.dy());
            const next_cell = self.cell(next_coord) orelse continue;

            if (next_cell != this_cell + 1) {
                continue;
            }

            var result_paths = try self.findTrailsInner(next_coord, new_path.items) orelse continue;
            defer {
                for (result_paths.items) |p| {
                    p.deinit();
                }
                result_paths.deinit();
            }

            for (result_paths.items) |rp| {
                try result.append(try rp.clone());
            }
        }

        return result;
    }

    fn cell(self: *const Self, coord: Coord) ?u8 {
        if (coord.x < 0 or coord.x >= self.width or coord.y < 0 or coord.y >= self.height) {
            return null;
        }

        return self.grid.items[@intCast(coord.y)].items[@intCast(coord.x)];
    }
};

const TrailheadIter = struct {
    grid: *const Grid,
    x: isize = 0,
    y: isize = 0,
    done: bool = false,

    fn next(self: *TrailheadIter) ?Coord {
        while(true) {
            defer self.x += 1;

            if (self.done) {
                return null;
            }

            if (self.x >= self.grid.width) {
                self.x = 0;
                self.y += 1;
            }

            if (self.y >= self.grid.height) {
                self.done = true;
                return null;
            }

            const coord = Coord {.x = self.x, .y = self.y};
            if (self.grid.cell(coord)) |cell| {
                if (cell == 0) {
                    return coord;
                }
            } else {
                return null;
            }
        }
    }
};

const testInput =
    \\89010123
    \\78121874
    \\87430965
    \\96549874
    \\45678903
    \\32019012
    \\01329801
    \\10456732
;

test "part 1" {
    var grid = try Grid.init(std.testing.allocator, testInput);
    defer grid.deinit();

    const answer = try part1(&grid);
    std.debug.print("\nAnswer: {d}\n", .{answer});
    try std.testing.expect(answer == 36);
}

test "part 2" {
    var grid = try Grid.init(std.testing.allocator, testInput);
    defer grid.deinit();

    const answer = try part2(&grid);
    std.debug.print("\nAnswer: {d}\n", .{answer});
    try std.testing.expect(answer == 81);
}
