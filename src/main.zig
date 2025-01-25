const std = @import("std");

pub fn main() !void {
    // Uncomment this block to pass the first stage
    const stdout = std.io.getStdOut().writer();
    while (true) {
        try stdout.print("$ ", .{});

        const stdin = std.io.getStdIn().reader();
        var buffer: [1024]u8 = undefined;
        const user_input = try stdin.readUntilDelimiter(&buffer, '\n');

        var input = std.mem.splitSequence(u8, user_input, " ");

        const command = input.next();
        const args = input.rest();

        if (command) |c| {
            if (std.mem.eql(u8, c, "exit")) {
                const exit_code = try std.fmt.parseInt(u8, input.next() orelse "0", 10);
                std.process.exit(exit_code);
            } else if (std.mem.eql(u8, c, "echo")) {
                _ = try stdout.write(args);
                _ = try stdout.write("\n");
            } else {
                try stdout.print("{s}: command not found\n", .{c});
            }
        }
    }
}
