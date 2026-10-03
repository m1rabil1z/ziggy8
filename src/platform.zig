const Platform = @This();
const std = @import("std");
const sdl = @import("sdl3");
const chip8 = @import("Chip8.zig");

const init_flags: sdl.InitFlags = .{ .video = true };

window: sdl.video.Window,
renderer: sdl.render.Renderer,
texture: sdl.render.Texture,

pub fn init(title: [:0]const u8, windowWidth: u32, windowHeight: u32, textureWidth: u32, textureHeight: u32) !Platform {
    try sdl.init(init_flags);

    const window, const renderer = try sdl.render.Renderer.initWithWindow(
        title,
        windowWidth,
        windowHeight,
        .{ .resizable = true },
    );

    const texture = try renderer.createTexture(
        .packed_rgba_8_8_8_8,
        .streaming,
        textureWidth,
        textureHeight,
    );

    try texture.setScaleMode(.pixel_art);

    return .{
        .window = window,
        .renderer = renderer,
        .texture = texture,
    };
}

pub fn deinit(self: *Platform) void {
    self.texture.deinit();
    self.renderer.deinit();
    self.window.deinit();
    sdl.quit(init_flags);
}

pub fn update(self: *Platform, buffer: *[chip8.VIDEO_HEIGHT * chip8.VIDEO_WIDTH]u32, pitch: usize) !void {
    try self.texture.update(null, @ptrCast(buffer), pitch);
    try self.renderer.clear();
    try self.renderer.renderTexture(self.texture, null, null);
    try self.renderer.present();
}

pub fn processInput(keys: [*]u8) bool {
    while (sdl.events.poll()) |event| {
        switch (event) {
            .quit => return false,
            .key_down => |key| switch (key.key.?) {
                .escape => return false,
                .x => keys[0] = 1,
                .one => keys[1] = 1,
                .two => keys[2] = 1,
                .three => keys[3] = 1,
                .q => keys[4] = 1,
                .w => keys[5] = 1,
                .e => keys[6] = 1,
                .a => keys[7] = 1,
                .s => keys[8] = 1,
                .d => keys[9] = 1,
                .z => keys[0xA] = 1,
                .c => keys[0xB] = 1,
                .four => keys[0xC] = 1,
                .r => keys[0xD] = 1,
                .f => keys[0xE] = 1,
                .v => keys[0xF] = 1,
                else => {},
            },
            .key_up => |key| switch (key.key.?) {
                .x => keys[0] = 0,
                .one => keys[1] = 0,
                .two => keys[2] = 0,
                .three => keys[3] = 0,
                .q => keys[4] = 0,
                .w => keys[5] = 0,
                .e => keys[6] = 0,
                .a => keys[7] = 0,
                .s => keys[8] = 0,
                .d => keys[9] = 0,
                .z => keys[0xA] = 0,
                .c => keys[0xB] = 0,
                .four => keys[0xC] = 0,
                .r => keys[0xD] = 0,
                .f => keys[0xE] = 0,
                .v => keys[0xF] = 0,
                else => {},
            },
            else => {},
        }
    }
    return true;
}
