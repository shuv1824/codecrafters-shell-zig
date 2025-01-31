const std = @import("std");
const builtin = @import("builtin");
const stdout = std.io.getStdOut().writer();
const stdin = std.io.getStdIn().reader();
const assert = std.debug.assert;

const Builtin = enum {
    exit,
    echo,
    type,
};

pub fn main() !void {
    while (true) {
        var buffer: [1024]u8 = undefined;
        try stdout.print("$ ", .{});

        if (try stdin.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
            var command = line;

            if (builtin.os.tag == .windows) {
                command = @constCast(std.mem.trimRight(u8, command, "\r"));
            }

            if (command.len != 0) {
                try handle_input(command);
            } else {
                try stdout.print("\n", .{});
            }
        }
    }
}

fn handler(T: Builtin, args: []const u8) !void {
    try switch (T) {
        Builtin.exit => std.process.exit(0),
        Builtin.echo => stdout.print("{s}\n", .{args}),
        Builtin.type => try handle_type(args),
    };
}

fn handle_type(args: []const u8) !void {
    const args_type = std.meta.stringToEnum(Builtin, args);
    if (args_type) |@"type"| {
        try stdout.print("{s} is a shell builtin\n", .{@tagName(@"type")});
    } else {
        try find_in_path(args);
    }
}

fn handle_input(input: []const u8) !void {
    assert(input.len != 0);

    var input_slices = std.mem.splitSequence(u8, input, " ");
    const command = input_slices.first();
    const args = input_slices.rest();
    const shell_builtin = std.meta.stringToEnum(Builtin, command);

    if (shell_builtin) |bi| {
        try handler(bi, args);
    } else {
        try stdout.print("{s}: command not found\n", .{command});
    }
}

fn find_in_path(args: []const u8) !void {
    const allocator = std.heap.page_allocator;
    const env_vars = try std.process.getEnvMap(allocator);
    const path_value = env_vars.get("PATH") orelse "";
    var path_it = std.mem.splitSequence(u8, path_value, ":");

    while (path_it.next()) |path| {
        const full_path = try std.fs.path.join(allocator, &[_][]const u8{ path, args });
        defer allocator.free(full_path);

        const file = std.fs.openFileAbsolute(full_path, .{ .mode = .read_only }) catch {
            continue;
        };
        defer file.close();

        const mode = file.mode() catch {
            continue;
        };

        const is_executable = mode & 0b001 != 0;
        if (!is_executable) {
            continue;
        }

        try stdout.print("{s} is {s}\n", .{ args, full_path });
        return;
    }

    try stdout.print("{s}: not found\n", .{args});
}
