const std = @import("std");

pub fn main() !void {
    std.debug.print("{d}", .{@sizeOf(c_int)});
}
