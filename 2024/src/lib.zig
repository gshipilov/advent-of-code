const std = @import("std");

pub fn parseIntLine(comptime T: type, allocator: std.mem.Allocator, line: []const u8) !std.ArrayList(T) {
    switch (@typeInfo(T)) {
        .Int => {},
        else => @compileError("type must be an integer!"),
    }

    var lst = std.ArrayList(T).init(allocator);
    errdefer lst.deinit();

    var iter = std.mem.tokenizeScalar(u8, line, ' ');
    while (iter.next()) |num_str| {
        const num = try std.fmt.parseInt(T, num_str, 10);
        try lst.append(num);
    }

    return lst;
}

pub fn cloneList(comptime T: type, allocator: std.mem.Allocator, list: *const std.ArrayList(T)) !std.ArrayList(T) {
    var new_list = std.ArrayList(T).init(allocator);
    errdefer (new_list.deinit());

    for (list.items) |item| {
        try new_list.append(item);
    }

    return new_list;
}

pub fn deinitList(comptime T: type, list: std.ArrayList(T)) void {
    const has_deinit = switch (@typeInfo(T)) {
        .Struct, .Union, .Enum => @hasDecl(T, "deinit"),
        else => false,
    };

    if (has_deinit) {
        for (list.items) |item| {
            item.deinit();
        }
    }

    list.deinit();
}
