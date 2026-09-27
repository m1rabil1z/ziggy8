const std = @import("std");
const pm = @import("platform.zig");
const c8 = @import("chip8.zig");

pub fn main() !void {
    std.debug.print("{d}", .{@sizeOf(c_int)});
}
