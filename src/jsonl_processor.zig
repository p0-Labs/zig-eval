const std = @import("std");

pub fn main() !void {
    // Get allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Open input file
    const input_file = try std.fs.cwd().openFile("prompts.jsonl", .{});
    defer input_file.close();

    // Create output file
    const output_file = try std.fs.cwd().createFile("prompts_with_names.jsonl", .{});
    defer output_file.close();

    // Setup buffered reader and writer
    var reader = std.io.bufferedReader(input_file.reader());
    var writer = std.io.bufferedWriter(output_file.writer());

    var line_buf = std.ArrayList(u8).init(allocator);
    defer line_buf.deinit();

    var counter: usize = 1;

    // Process each line
    while (true) {
        reader.reader().readUntilDelimiterArrayList(&line_buf, '\n', 4096) catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };

        // Skip empty lines
        if (line_buf.items.len == 0) continue;

        // Find position before the closing brace
        const closing_brace_pos = std.mem.lastIndexOf(u8, line_buf.items, "}") orelse continue;

        // Format the prompt name with padding zeros
        var prompt_num_buf: [3]u8 = undefined;
        _ = std.fmt.formatIntBuf(&prompt_num_buf, counter, 10, .lower, .{ .width = 3, .fill = '0' });

        // Write the modified line
        const prefix = line_buf.items[0..closing_brace_pos];
        try writer.writer().print("{s}, \"prompt_name\": \"zig_eval_{s}\"}}\n", .{ prefix, prompt_num_buf });

        counter += 1;
    }

    // Flush the writer
    try writer.flush();
}
