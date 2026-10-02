const std = @import("std");
const pm = @import("platform.zig");
const c8 = @import("chip8.zig");

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const args = try init.minimal.args.toSlice(arena);
    if (args.len != 4) {
        std.debug.print(
            "Usage : {s} <Scale> <Delay> <ROM>\n",
            .{args[0]},
        );
        std.process.exit(1);
    }

    const videoScale = try std.fmt.parseInt(i32, args[1], 10);
    const cycleDelay: i32 = try std.fmt.parseInt(i32, args[2], 10);

    const romFilename = args[3];

    var platform = try pm.Platform__init(
        "CHIP-8 Emulator",
        videoScale * @as(i32, @intCast(c8.VIDEO_WIDTH)),
        videoScale * @as(i32, @intCast(c8.VIDEO_HEIGHT)),
        @as(i32, @intCast(c8.VIDEO_WIDTH)),
        @as(i32, @intCast(c8.VIDEO_HEIGHT)),
    );

    var chip8 = c8.Chip8__init(init);
    _ = try c8.LoadROM(&chip8, init, romFilename);

    const videoPitch = @as(i32, @intCast(@sizeOf(u32) * c8.VIDEO_WIDTH));

    var lastCycleTime = std.Io.Clock.now(.real, init.io);
    var quit: bool = false;

    while (!quit) {
        quit = pm.ProcessInput(&platform, &chip8.keypad);

        const currentTime = std.Io.Clock.now(.real, init.io);

        const dt: i32 = @intCast(lastCycleTime.durationTo(currentTime).toMilliseconds());

        if (dt > cycleDelay) {
            lastCycleTime = currentTime;

            c8.Cycle(&chip8);

            pm.Update(&platform, &chip8.video, videoPitch);
        }
    }
}
