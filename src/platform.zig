const std = @import("std");
const sdl = @cImport(@cInclude("SDL3/SDL.h"));
const glad = @cImport(@cInclude("glad/glad.h"));

const Platform = struct {
    window: *sdl.SDL_Window,
    gl_context: sdl.SDL_GLContext,
    framebuffer_texture: glad.GLuint,
    renderer: *sdl.SDL_Renderer,
    texture: *sdl.SDL_Texture,
};

pub fn Platform__init(title: [*:0]const u8, windowWidth: i32, windowHeight: i32, textureWidth: i32, textureHeight: i32) Platform {
    _ = title;
    _ = windowHeight;
    _ = windowWidth;
    _ = textureHeight;
    _ = textureWidth;
    return Platform{};
}

pub fn Platform__destroy(self: *Platform) void {
    _ = self;
}

pub fn Update(self: *Platform, buffer: *const void, pitch: i32) void {
    _ = self;
    _ = buffer;
    _ = pitch;
}

pub fn ProcessInput(self: *Platform, keys: [*]u8) bool {
    _ = self;
    _ = keys;
}
