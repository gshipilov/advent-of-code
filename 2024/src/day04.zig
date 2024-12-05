const std = @import("std");

pub fn run(allocator: std.mem.Allocator, input: []const u8) !void {
    var grid = try Grid.init(allocator, input);
    defer grid.deinit();

    std.debug.print("Part 1: {d}\n", .{part1(&grid)});
    std.debug.print("Part 2: {d}\n", .{part2(&grid)});
}

fn part1(grid: *const Grid) usize {
    var total: usize = 0;
    for (0.., grid.values.items) |y, row| {
        for (0.., row.items) |x, cell| {
            if (cell == 'X') {
                total += grid.countRingMatches(x, y, "XMAS");
            }
        }
    }

    return total;
}

fn part2(grid: *const Grid) usize {
    var total: usize = 0;
    for (0.., grid.values.items) |y, row| {
        for (0.., row.items) |x, cell| {
            if (cell == 'A') {
                if (grid.checkXMatch(x, y)) {
                    total += 1;
                }
            }
        }
    }

    return total;
}

const Dir = enum {
    Up,
    UpRight,
    Right,
    RightDown,
    Down,
    DownLeft,
    Left,
    LeftUp,

    fn dx(self: Dir) isize {
        return switch(self) {
            .Up, .Down => 0,
            .UpRight, .Right, .RightDown => 1,
            .DownLeft, .Left, .LeftUp => -1,
        };
    }

    fn dy(self: Dir) isize {
        return switch(self) {
            .Left, .Right => 0,
            .LeftUp, .Up, .UpRight => -1,
            .RightDown, .Down, .DownLeft => 1,
        };
    }

    fn values() [8]Dir {
        return [_]Dir {
            Dir.Up,
            Dir.UpRight,
            Dir.Right,
            Dir.RightDown,
            Dir.Down,
            Dir.DownLeft,
            Dir.Left,
            Dir.LeftUp,
        };
    }
};

const Grid = struct {
    values: std.ArrayList(std.ArrayList(u8)),
    mx: usize,
    my: usize,

    const Self = @This();

    fn init(allocator: std.mem.Allocator, input: []const u8) !Self {
        var grid = std.ArrayList(std.ArrayList(u8)).init(allocator);
        errdefer {
            for (grid.items) |row| {
                row.deinit();
            }

            grid.deinit();
        }

        var mx: usize = 0;
        var lines = std.mem.splitScalar(u8, input, '\n');
        while (lines.next()) |line| {
            var row = std.ArrayList(u8).init(allocator);
            errdefer row.deinit();

            for (line) |char| {
                try row.append(char);
            }

            mx = @max(mx, row.items.len);
            try grid.append(row);
        }

        return .{.values = grid, .mx = mx - 1, .my = grid.items.len - 1};
    }

    fn deinit(self: *Self) void {
        for (self.values.items) |row| {
            row.deinit();
        }

        self.values.deinit();
        self.* = undefined;
    }

    fn countRingMatches(self: *const Self, x: usize, y: usize, chars: []const u8) usize {
        var total: usize = 0;

        for (Dir.values()) |dir| {
            if (self.checkWord(x, y, dir, chars)) {
                total += 1;
            }
        }

        return total;
    }

    fn checkWord(self: *const Self, x: usize, y: usize, dir: Dir, chars: []const u8) bool {
        for (chars, 0..) |c, mult| {
            const mv = @as(isize, @intCast(mult));
            const nx = saturating_add(x, dir.dx() * mv) orelse return false;
            const ny = saturating_add(y, dir.dy() * mv) orelse return false;

            if (!self.checkCell(nx, ny, c)) {
                return false;
            }
        }

        return true;
    }

    fn checkXMatch(self: *const Self, x: usize, y: usize) bool {
        if (x == 0 or x == self.mx or y == 0 or y == self.my) {
            return false;
        }

        var t1: i16 = 'S' + 'M';
        t1 -= self.values.items[y - 1].items[x - 1];
        t1 -= self.values.items[y + 1].items[x + 1];

        var t2: i16 = 'S' + 'M';
        t2 -= self.values.items[y - 1].items[x + 1];
        t2 -= self.values.items[y + 1].items[x - 1];

        return t1 == 0 and t2 == 0;
    }

    fn checkCell(self: *const Self, x: usize, y: usize, char: u8) bool {
        if (x > self.mx or y > self.my){
            return false;
        }

        return self.values.items[y].items[x] == char;
    }

    // can't use the operator because you still can't add usize + isize together :/.
    fn saturating_add(v: usize, dv: isize) ?usize {
        const result = @as(isize, @intCast(v)) + dv;

        if (result < 0) {
            return null;
        } else {
            return @intCast(result);
        }
    }
};

const test_input =
    \\MMMSXXMASM
    \\MSAMXMSMSA
    \\AMXSXMAAMM
    \\MSAMASMSMX
    \\XMASAMXAMM
    \\XXAMMXXAMA
    \\SMSMSASXSS
    \\SAXAMASAAA
    \\MAMMMXMMMM
    \\MXMXAXMASX
;

test "part 1" {
    var grid = try Grid.init(std.testing.allocator, test_input);
    defer grid.deinit();

    std.debug.print("\n", .{});
    const answer = part1(&grid);
    std.debug.print("{any}\n", .{answer});
    try std.testing.expect(answer == 18);
}

test "part 2" {
    var grid = try Grid.init(std.testing.allocator, test_input);
    defer grid.deinit();

    std.debug.print("\n", .{});
    const answer = part2(&grid);
    std.debug.print("{any}\n", .{answer});
    try std.testing.expect(answer == 9);
}
