const std = @import("std");

const Day = *const fn (allocator: std.mem.Allocator, input: []const u8) anyerror!void;

const days = [_]Day{
    @import("day01.zig").run,
    @import("day02.zig").run,
    // @import("day03.zig").run,
    @import("day02.zig").run, // Day 3 not ready to publish yet.
    @import("day04.zig").run,
    @import("day05.zig").run,
    @import("day06.zig").run,
    @import("day07.zig").run,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const free_stat = gpa.deinit();
        if (free_stat == .leak) std.testing.expect(false) catch @panic("Leaked memory!");
    }

    // args
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    // skip cmd
    _ = args.next();

    const day_str = args.next() orelse {
        std.debug.print("Missing day argument.\n", .{});
        std.process.exit(1);
    };

    const input = try readInput(allocator, day_str);
    defer allocator.free(input);

    const day = try std.fmt.parseInt(usize, day_str, 10);
    _ = try days[day - 1](allocator, input);
}

fn readInput(allocator: std.mem.Allocator, day: []const u8) ![]const u8 {
    const input_name = try std.mem.concat(allocator, u8, &[_][]const u8{ "inputs/day", day });
    defer allocator.free(input_name);

    const input_path = try std.fs.cwd().realpathAlloc(allocator, input_name);
    defer allocator.free(input_path);

    const contents = try std.fs.openFileAbsolute(input_path, .{});
    return contents.readToEndAlloc(allocator, std.math.maxInt(usize));
}
