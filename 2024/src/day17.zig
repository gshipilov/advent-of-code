const std = @import("std");

pub fn run(allocator: std.mem.Allocator, input: []const u8) !void {
    try part1(allocator, input);
    std.debug.print("Part 2: {d}\n", .{try part2(allocator, input)});
}

fn part1(allocator: std.mem.Allocator, input: []const u8) !void {
    var vm = try parseInput(allocator, input);
    defer vm.deinit();

    try vm.run();

    std.debug.print("Part 1: ", .{});
    for (0.., vm.out.items) |i, num| {
        std.debug.print("{d}", .{num});
        if (i < vm.out.items.len - 1) {
            std.debug.print(",", .{});
        }
    }

    std.debug.print("\n", .{});
}

fn part2(allocator: std.mem.Allocator, input: []const u8) !isize {
    var vm = try parseInput(allocator, input);

    var code = try vm.code.clone();
    defer code.deinit();

    vm.deinit();

    return (try p2Inner(allocator, &code, code.items.len - 1, 0)).?;
}

fn p2Inner(allocator: std.mem.Allocator, code: *std.ArrayList(u3), index: usize, a_value: isize) !?isize {
    for (0..8) |dv| {
        const next_value = a_value + @as(isize, @intCast(dv));

        var vm = VM.init(allocator, try code.clone());
        defer vm.deinit();

        vm.a = next_value;

        try vm.run();
        if (vm.out.items[0] != code.items[index]) {
            continue;
        }

        if (index == 0) {
            return next_value;
        }

        if (try p2Inner(allocator, code, index - 1, next_value * 8)) |result| {
            return result;
        }
    }

    return null;
}

const OpCode = enum(u3) {
    Adv = 0,
    Bxl = 1,
    Bst = 2,
    Jnz = 3,
    Bxc = 4,
    Out = 5,
    Bdv = 6,
    Cdv = 7,
};

const VM = struct {
    a: isize = 0,
    b: isize = 0,
    c: isize = 0,

    ip: usize = 0,
    code: std.ArrayList(u3),

    out: std.ArrayList(u3),

    const Self = @This();

    fn init(allocator: std.mem.Allocator, code: std.ArrayList(u3)) Self {
        return .{
            .code = code,

            .out = std.ArrayList(u3).init(allocator),
        };
    }

    fn deinit(self: *Self) void {
        self.code.deinit();
        self.out.deinit();
        self.* = undefined;
    }

    fn run(self: *Self) !void {
        while(self.ip < self.code.items.len) {
            try self.eval();
        }
    }

    fn eval(self: *Self) !void {
        const op_code: OpCode = @enumFromInt(self.code.items[self.ip]);
        const operand = self.code.items[self.ip + 1];

        var jumped = false;
        switch (op_code) {
            .Adv => {
                const denom = std.math.powi(isize, 2, self.getComboValue(operand)) catch unreachable;
                const answer = @divTrunc(self.a, denom);
                self.a = answer;
            },
            .Bxl => {
                self.b ^= @intCast(operand);
            },
            .Bst => {
                self.b = @mod(self.getComboValue(operand), 8);
            },
            .Jnz => {
                if (self.a != 0) {
                    self.ip = @intCast(operand);
                    jumped = true;
                }
            },
            .Bxc => {
                self.b ^= self.c;
            },
            .Out => {
                try self.out.append(@intCast(@mod(self.getComboValue(operand), 8)));
            },
            .Bdv => {
                const denom = std.math.powi(isize, 2, self.getComboValue(operand)) catch unreachable;
                const answer = @divTrunc(self.a, denom);
                self.b = answer;
            },
            .Cdv => {
                const denom = std.math.powi(isize, 2, self.getComboValue(operand)) catch unreachable;
                const answer = @divTrunc(self.a, denom);
                self.c = answer;
            },
        }

        if(!jumped) {
            self.ip += 2;
        }
    }

    fn getComboValue(self: *const Self, operand: u3) isize {
        return switch(operand) {
            0...3 => @intCast(operand),
            4 => self.a,
            5 => self.b,
            6 => self.c,
            7 => unreachable,
        };
    }
};

fn parseInput(allocator: std.mem.Allocator, input: []const u8) !VM {
    var lines = std.mem.splitScalar(u8, input, '\n');

    const a: isize = try parseRegister(lines.next().?);
    const b: isize = try parseRegister(lines.next().?);
    const c: isize = try parseRegister(lines.next().?);

    _ = lines.next();

    var code = std.ArrayList(u3).init(allocator);
    errdefer code.deinit();

    var codes = std.mem.tokenize(u8, lines.next().?, " ,");
    _ = codes.next();

    while(codes.next()) |opcode| {
        try code.append(try std.fmt.parseInt(u3, opcode, 10));
    }

    var vm = VM.init(allocator, code);
    vm.a = a;
    vm.b = b;
    vm.c = c;

    return vm;
}

fn parseRegister(line: []const u8) !isize {
    var parts = std.mem.split(u8, line, ": ");
    _ = parts.next();

    return try std.fmt.parseInt(isize, parts.next().?, 10);
}

test "part 1" {
    const input =
        \\Register A: 729
        \\Register B: 0
        \\Register C: 0
        \\
        \\Program: 0,1,5,4,3,0
    ;
    var vm = try parseInput(std.testing.allocator, input);
    defer vm.deinit();

    try vm.run();

    std.debug.print("Answer: {d}\n", .{vm.out.items});
}

test "part 2" {
    const input =
        \\Register A: 2024
        \\Register B: 0
        \\Register C: 0
        \\
        \\Program: 0,3,5,4,3,0
    ;

    const answer = try part2(std.testing.allocator, input);
    try std.testing.expect(answer == 117440);
}
