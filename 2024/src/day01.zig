const std = @import("std");

pub fn run(_: std.mem.Allocator, _: []const u8) void {
    std.debug.print("Hello, world!\n", .{});
}
