const std = @import("std");
const aoc = @import("lib.zig");

pub fn run(allocator: std.mem.Allocator, input: []const u8) !void {
    std.debug.print("Part 1: {d}\n", .{try part1(allocator, input)});
    std.debug.print("Part 2: {d}\n", .{try part2(allocator, input)});
}

fn part1(allocator: std.mem.Allocator, input: []const u8) !usize {
    const parsed = try parseInput(allocator, input);
    var grid = parsed[0];
    var guard = parsed[1];
    defer grid.deinit();

    _ = guard.patrol(&grid);

    var total: usize = 1;
    for(grid.rows.items) |row| {
        for (row.items) |cell| {
            if (cell.visited()) {
                total += 1;
            }
        }
    }

    return total;
}

fn part2(allocator: std.mem.Allocator, input: []const u8) !usize {
    const parsed = try parseInput(allocator, input);
    var i_grid = parsed[0];
    var i_guard = parsed[1];
    defer i_grid.deinit();

    const total_rows = i_grid.rows.items.len;
    var loops: usize = 0;
    for (0..i_grid.rows.items.len) |y| {
        for (0..i_grid.rows.items[0].items.len) |x| {
            if (x == i_guard.xpos and (y == i_guard.ypos - 1 or y == i_guard.ypos)) {
                continue;
            }

            var grid = try i_grid.clone(allocator);
            defer grid.deinit();

            grid.rows.items[y].items[x] = Cell.obstacle();

            var guard = i_guard.clone();
            if (guard.patrol(&grid)) {
                loops += 1;
            }
        }

        std.debug.print("\r\x1B[2KFinished {d}/{d} rows.", .{y + 1, total_rows});
    }

    std.debug.print("\r\x1B[2K", .{});

    return loops;
}


const Dir = enum {
    Up,
    Right,
    Down,
    Left,

    fn next(self: Dir) Dir {
        return @enumFromInt(@intFromEnum(self) +% 1);
    }

    fn dx(self: Dir) isize {
        return switch(self) {
            .Up, .Down => 0,
            .Right => 1,
            .Left => -1,
        };
    }

    fn dy(self: Dir) isize {
        return switch(self) {
            .Left, .Right => 0,
            .Up => -1,
            .Down => 1,
        };
    }
};

const Cell = union(enum) {
    obstacle: void,
    space: [4]bool,

    fn obstacle() Cell {
        return .{.obstacle = {}};
    }

    fn space() Cell {
        return .{.space = [_]bool{false} ** 4};
    }

    fn visited(self: Cell) bool {
        switch (self) {
            .obstacle => return false,
            .space => |dirs| {
                for (dirs) |dir| {
                    if (dir) {
                        return true;
                    }
                }
                return false;
            }
        }
    }
};

const Guard = struct {
    xpos: isize,
    ypos: isize,
    dir: Dir,

    const Self = @This();

    fn clone(self: *const Self) Self {
        return .{.xpos = self.xpos, .ypos = self.ypos, .dir = self.dir};
    }

    fn patrol(self: *Self, grid: *Grid) bool {
        while(true) {
            const nx = self.xpos + self.dir.dx();
            const ny = self.ypos + self.dir.dy();

            const next_cell = grid.cell(nx, ny) orelse return false;
            const next_dir = self.dir.next();

            switch (next_cell.*) {
                .obstacle => {
                    self.dir = next_dir;
                    continue;
                },
                .space => {}
            }

            switch (grid.cell(self.xpos, self.ypos).?.*) {
                .obstacle => {
                    unreachable;
                },
                .space => |*dirs| {
                    if (dirs[@intFromEnum(self.dir)]) {
                        return true;
                    }
                    dirs[@intFromEnum(self.dir)] = true;
                }
            }

            self.xpos = nx;
            self.ypos = ny;
        }
    }
};

const Row = std.ArrayList(Cell);

const Grid = struct {
    rows: std.ArrayList(Row),

    const Self = @This();

    fn init(allocator: std.mem.Allocator) Self {
        const rows = std.ArrayList(Row).init(allocator);

        return .{.rows = rows};
    }

    fn deinit(self: *Grid) void {
        aoc.deinitList(Row, self.rows);
        self.* = undefined;
    }

    fn clone(self: *const Self, allocator: std.mem.Allocator) !Self {
        var new_grid = Self.init(allocator);
        errdefer new_grid.deinit();

        for (self.rows.items) |row| {
            var new_row = Row.init(allocator);
            errdefer new_row.deinit();

            for (row.items) |c| {
                try new_row.append(c);
            }
            try new_grid.rows.append(new_row);
        }

        return new_grid;
    }

    fn cell(self: *const Grid, x: isize, y: isize) ?*Cell {
        if (x < 0 or self.rows.items[0].items.len <= x or y < 0 or self.rows.items.len <= y) {
            return null;
        }

        return &self.rows.items[@intCast(y)].items[@intCast(x)];
    }
};

fn parseInput(allocator: std.mem.Allocator, input: []const u8) !struct {Grid, Guard} {
    var grid = Grid.init(allocator);
    errdefer grid.deinit();

    var guard: Guard = undefined;
    var lines = std.mem.splitScalar(u8, input, '\n');

    var y: isize = 0;
    while (lines.next()) |line| {
        var row = Row.init(allocator);
        errdefer row.deinit();

        var x: isize = 0;
        for (line) |char| {
            switch (char) {
                '.' => {
                    const cell = Cell.space();
                    try row.append(cell);
                },
                '#' => {
                    const cell = Cell.obstacle();
                    try row.append(cell);
                },
                '^' => {
                    const cell = Cell.space();
                    try row.append(cell);

                    guard = Guard{ .xpos = x, .ypos = y, .dir = Dir.Up};
                },
                else => unreachable,
            }
            x += 1;
        }

        try grid.rows.append(row);
        y += 1;
    }

    return .{grid, guard};
}

const testInput =
    \\....#.....
    \\.........#
    \\..........
    \\..#.......
    \\.......#..
    \\..........
    \\.#..^.....
    \\........#.
    \\#.........
    \\......#...
;

test "part1" {
    const answer = try part1(std.testing.allocator, testInput);
    std.debug.print("\nAnswer: {d}\n", .{answer});
    try std.testing.expect(answer == 41);
}

test "part2" {
    std.debug.print("\n", .{});
    const answer = try part2(std.testing.allocator, testInput);
    std.debug.print("\nAnswer: {d}\n", .{answer});
    try std.testing.expect(answer == 6);
}
