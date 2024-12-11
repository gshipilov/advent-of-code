const std = @import("std");

pub fn run(allocator: std.mem.Allocator, input: []const u8) !void {
    const buffer = try allocator.alloc(u8, input.len);
    defer allocator.free(buffer);

    @memcpy(buffer, input);

    std.debug.print("Part 1: {d}\n", .{computeChecksum(buffer)});

    var entries = try parseEntries(allocator, input);
    defer entries.deinit();

    try defrag(&entries);

    std.debug.print("Part 2: {d}\n", .{computeDefraggedChecksum(entries.items)});
}

fn computeChecksum(input: []u8) usize {
    var i: usize = 0;
    var j: usize = input.len - 1;

    var low_id: usize = 0;
    var high_id = input.len / 2;

    var checksum: usize = 0;
    var checksum_index: usize = 0;
    while (i <= j) {
        const iv = input[i] - '0';
        if (i % 2 == 0) {
            // i is even, add current value to checksum.
            for (0..iv) |_| {
                checksum += low_id * checksum_index;
                checksum_index += 1;
            }
            i += 1;
            low_id += 1;
            continue;
        }

        // left has space.
        const jv = input[j] - '0';
        const diff = @min(iv, jv);

        for (0..diff) |_| {
            checksum += high_id * checksum_index;
            checksum_index += 1;
            input[i] -= 1;
            input[j] -= 1;
        }

        if (input[i] == '0') {
            i += 1;
        }

        if(input[j] == '0') {
            high_id -= 1;
            j -= 2;
        }
    }

    return checksum;
}

const Entry = union(enum) {
    file: struct {
        id: usize,
        size: u8,
    },
    space: u8,
};

fn defrag(entries: *std.ArrayList(Entry)) !void {
    var j = entries.items.len - 1;
    while(j > 0) {
        const entry = entries.items[j];

        if (entry == .space) {
            j -= 1;
            continue;
        }

        for (0..j) |i| {
            const candidate = entries.items[i];
            if (candidate == .file) {
                continue;
            }

            if (candidate.space < entry.file.size) {
                continue;
            }

            const value = entries.items[j];
            entries.items[j] = entries.items[i];
            entries.items[i] = value;

            if (candidate.space > entry.file.size) {
                const diff = candidate.space - entry.file.size;
                const new_space = Entry{.space = diff};
                entries.items[j].space -= diff;
                try entries.insert(i + 1, new_space);
            }
            break;
        }
        j -= 1;
    }
}

fn computeDefraggedChecksum(entries: []Entry) usize {
    var total: usize = 0;

    var checksum_index: usize = 0;
    for (entries) |entry| {
        switch(entry) {
            .space => |size| checksum_index += size,
            .file => |file| {
                for (0..file.size) |_| {
                    const diff = file.id * checksum_index;
                    total += diff;
                    checksum_index += 1;
                }
            }
        }
    }

    return total;
}

fn parseEntries(allocator: std.mem.Allocator, input: []const u8) !std.ArrayList(Entry) {
    var files = std.ArrayList(Entry).init(allocator);
    errdefer files.deinit();

    for (0.., input) |i, c| {
        var entry: Entry = undefined;
        if (i % 2 == 0) {
            entry = Entry{.file = .{.id = i / 2, .size = c - '0'}};
        } else {
            entry = Entry{.space = c - '0'};
        }

        try files.append(entry);
    }

    return files;
}
