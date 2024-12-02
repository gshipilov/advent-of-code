const std = @import("std");

pub fn run(allocator: std.mem.Allocator, input: []const u8) !void {
    const reports = try parseInput(allocator, input);
    defer {
        for (reports.items) |report| {
            report.deinit();
        }

        reports.deinit();
    }

    std.debug.print("Part 1: {any}\n", .{part1(reports.items)});
    std.debug.print("Part 2: {any}\n", .{part2(allocator, reports.items)});
}

fn part1(reports: []Report) usize {
    var total: usize = 0;
    for (reports) |report| {
        if (checkReport(report.items)) {
            total += 1;
        }
    }

    return total;
}

fn part2(allocator: std.mem.Allocator, reports: []Report) !usize {
    var total: usize = 0;
    for (reports) |report| {
        if (try checkReportWithDampener(allocator, report.items)) {
            total += 1;
        }
    }

    return total;
}

const Report = std.ArrayList(isize);

fn checkReport(report: []isize) bool {
    var increasing = false;
    var decreasing = false;

    for (1..report.len) |i| {
        if (report[i - 1] < report[i]) {
            increasing = true;
        } else if (report[i - 1] > report[i]) {
            decreasing = true;
        }

        if (increasing and decreasing) {
            return false;
        }

        const diff = @abs(report[i] - report[i - 1]);
        if (diff < 1 or diff > 3) {
            return false;
        }
    }

    return !(increasing and decreasing) and (increasing or decreasing);
}

fn checkReportWithDampener(allocator: std.mem.Allocator, report: []isize) !bool {
    if (checkReport(report)) {
        return true;
    }

    for (0..report.len) |ig| {
        var new_report = std.ArrayList(isize).init(allocator);
        defer new_report.deinit();

        for (0.., report) |i, item| {
            if (i == ig) {
                continue;
            }
            try new_report.append(item);
        }

        if (checkReport(new_report.items)) {
            return true;
        }
    }

    return false;
}

fn parseInput(allocator: std.mem.Allocator, input: []const u8) !std.ArrayList(Report) {
    var reports = std.ArrayList(Report).init(allocator);
    errdefer {
        for (reports.items) |report| {
            report.deinit();
        }

        reports.deinit();
    }

    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        var report = Report.init(allocator);
        errdefer report.deinit();

        var nums = std.mem.tokenizeScalar(u8, line, ' ');
        while (nums.next()) |num_str| {
            const num = try std.fmt.parseInt(isize, num_str, 10);
            try report.append(num);
        }

        try reports.append(report);
    }

    return reports;
}

const testInput =
    \\7 6 4 2 1
    \\1 2 7 8 9
    \\9 7 6 2 1
    \\1 3 2 4 5
    \\8 6 4 4 1
    \\1 3 6 7 9
;

test "part1" {
    const reports = try parseInput(std.testing.allocator, testInput);
    defer {
        for (reports.items) |report| {
            report.deinit();
        }

        reports.deinit();
    }

    try std.testing.expect(part1(reports.items) == 2);
}

test "part2" {
    const reports = try parseInput(std.testing.allocator, testInput);
    defer {
        for (reports.items) |report| {
            report.deinit();
        }

        reports.deinit();
    }

    const answer = try part2(std.testing.allocator, reports.items);
    try std.testing.expect(answer == 4);
}
