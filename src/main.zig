const std = @import("std");
const Platform = @import("platform.zig");
const C8 = @import("Chip8.zig");

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

    var platform: Platform = try .init(
        "CHIP-8 Emulator",
        videoScale * @as(i32, @intCast(C8.VIDEO_WIDTH)),
        videoScale * @as(i32, @intCast(C8.VIDEO_HEIGHT)),
        @as(i32, @intCast(C8.VIDEO_WIDTH)),
        @as(i32, @intCast(C8.VIDEO_HEIGHT)),
    );
    defer platform.deinit();

    var chip8: C8 = .init(init.io);
    chip8.loadROM(init.io, romFilename) catch {
        std.log.err("Invalid rom argument",.{});
        return;
    };

    var lastCycleTime = std.Io.Clock.now(.real, init.io);

    while (Platform.processInput(&chip8.keypad)) {
        const currentTime = std.Io.Clock.now(.real, init.io);
        const dt: i32 = @intCast(lastCycleTime.durationTo(currentTime).toMilliseconds());

        if (dt > cycleDelay) {
            lastCycleTime = currentTime;

            chip8.cycle();

            const videoPitch = @sizeOf(u32) * C8.VIDEO_WIDTH;
            try platform.update(&chip8.video, videoPitch);
        }
    }
}
