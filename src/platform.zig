const std = @import("std");
const sdl = @cImport(@cInclude("SDL3/SDL.h"));
const glad = @cImport(@cInclude("glad/glad.h"));

const Platform = struct {
    window: ?*sdl.SDL_Window,
    gl_context: sdl.SDL_GLContext,
    framebuffer_texture: glad.GLuint,
    renderer: ?*sdl.SDL_Renderer,
    texture: ?*sdl.SDL_Texture,
};

pub fn Platform__init(title: [*:0]const u8, windowWidth: i32, windowHeight: i32, textureWidth: i32, textureHeight: i32) !Platform {
    if (!sdl.SDL_Init(sdl.SDL_INIT_VIDEO)) {
        return error.InitFailed;
    }

    if (!sdl.SDL_GL_SetAttribute(@intCast(sdl.SDL_GL_CONTEXT_PROFILE_MASK), sdl.SDL_GL_CONTEXT_PROFILE_CORE)) {
        return error.setAttprofmaskFailed;
    }
    if (!sdl.SDL_GL_SetAttribute(@intCast(sdl.SDL_GL_CONTEXT_MAJOR_VERSION), 3)) {
        return error.setAttmajFailed;
    }
    if (!sdl.SDL_GL_SetAttribute(@intCast(sdl.SDL_GL_CONTEXT_MINOR_VERSION), 3)) {
        return error.setAttminfailed;
    }

    const window = sdl.SDL_CreateWindow(
        title,
        windowWidth,
        windowHeight,
        sdl.SDL_WINDOW_OPENGL | sdl.SDL_WINDOW_RESIZABLE,
    );

    if (window == null) {
        return error.createWindowFailed;
    }

    const gl_context = sdl.SDL_GL_CreateContext(window);

    if (gl_context == null) {
        return error.createContextFailed;
    }

    if (!sdl.SDL_GL_SetSwapInterval(1)) {
        return error.setSwapIntervalfailed;
    }
    _ = glad.gladLoadGL();

    var framebuffer_texture: glad.GLuint = undefined;
    glad.glGenTextures(1, &framebuffer_texture);
    glad.glBindTexture(@intCast(glad.GL_TEXTURE), framebuffer_texture);
    glad.glTexParameteri(@intCast(glad.GL_TEXTURE_2D), @intCast(glad.GL_TEXTURE_MIN_FILTER), glad.GL_NEAREST);
    glad.glTexParameteri(@intCast(glad.GL_TEXTURE_2D), @intCast(glad.GL_TEXTURE_MAG_FILTER), glad.GL_NEAREST);
    glad.glTexParameteri(@intCast(glad.GL_TEXTURE_2D), @intCast(glad.GL_TEXTURE_WRAP_S), @intCast(glad.GL_CLAMP_TO_EDGE));
    glad.glTexParameteri(@intCast(glad.GL_TEXTURE_2D), @intCast(glad.GL_TEXTURE_WRAP_T), @intCast(glad.GL_CLAMP_TO_EDGE));
    glad.glTexImage2D(@intCast(glad.GL_TEXTURE_2D), 0, glad.GL_RGBA, 640, 320, 0, @intCast(glad.GL_RGBA), @intCast(glad.GL_UNSIGNED_BYTE), null);
    glad.glBindTexture(@intCast(glad.GL_TEXTURE), 0);

    const renderer = sdl.SDL_CreateRenderer(window, null);
    if (renderer == null) {
        return error.createRendererFailed;
    }

    const texture = sdl.SDL_CreateTexture(
        renderer,
        sdl.SDL_PIXELFORMAT_RGBA8888,
        sdl.SDL_TEXTUREACCESS_STREAMING,
        @intCast(textureWidth),
        @intCast(textureHeight),
    );
    if (texture == null) {
        return error.createTexturerFailed;
    }

    return Platform{
        .window = window,
        .gl_context = gl_context,
        .framebuffer_texture = framebuffer_texture,
        .renderer = renderer,
        .texture = texture,
    };
}

pub fn Platform__destroy(self: *Platform) void {
    sdl.SDL_DestroyTexture(self.texture);
    sdl.SDL_DestroyRenderer(self.renderer);
    sdl.SDL_DestroyWindow(self.window);
    sdl.SDL_Quit();
}

pub fn Update(self: *Platform, buffer: *const anyopaque, pitch: i32) void {
    _ = sdl.SDL_UpdateTexture(self.texture, null, buffer, @intCast(pitch));
    _ = sdl.SDL_RenderClear(self.renderer);
    _ = sdl.SDL_RenderTexture(self.renderer, self.texture, null, null);
    _ = sdl.SDL_RenderPresent(self.renderer);
}

pub fn ProcessInput(self: *Platform, keys: [*]u8) bool {
    _ = self;
    var quit: bool = false;
    var event: sdl.SDL_Event = undefined;

    while (sdl.SDL_PollEvent(&event)) {
        switch (@as(c_int, @intCast(event.type))) {
            sdl.SDL_EVENT_QUIT => {
                quit = true;
            },

            sdl.SDL_EVENT_KEY_DOWN => {
                switch (@as(c_uint, event.key.key)) {
                    sdl.SDLK_ESCAPE => {
                        quit = true;
                    },

                    sdl.SDLK_X => {
                        keys[0] = 1;
                    },

                    sdl.SDLK_1 => {
                        keys[1] = 1;
                    },

                    sdl.SDLK_2 => {
                        keys[2] = 1;
                    },

                    sdl.SDLK_3 => {
                        keys[3] = 1;
                    },

                    sdl.SDLK_Q => {
                        keys[4] = 1;
                    },

                    sdl.SDLK_W => {
                        keys[5] = 1;
                    },

                    sdl.SDLK_E => {
                        keys[6] = 1;
                    },

                    sdl.SDLK_A => {
                        keys[7] = 1;
                    },

                    sdl.SDLK_S => {
                        keys[8] = 1;
                    },

                    sdl.SDLK_D => {
                        keys[9] = 1;
                    },

                    sdl.SDLK_Z => {
                        keys[0xA] = 1;
                    },

                    sdl.SDLK_C => {
                        keys[0xB] = 1;
                    },

                    sdl.SDLK_4 => {
                        keys[0xC] = 1;
                    },

                    sdl.SDLK_R => {
                        keys[0xD] = 1;
                    },

                    sdl.SDLK_F => {
                        keys[0xE] = 1;
                    },

                    sdl.SDLK_V => {
                        keys[0xF] = 1;
                    },

                    else => {},
                }
            },

            sdl.SDL_EVENT_KEY_UP => {
                switch (@as(c_uint, event.key.key)) {
                    sdl.SDLK_X => {
                        keys[0] = 0;
                    },

                    sdl.SDLK_1 => {
                        keys[1] = 0;
                    },

                    sdl.SDLK_2 => {
                        keys[2] = 0;
                    },

                    sdl.SDLK_3 => {
                        keys[3] = 0;
                    },

                    sdl.SDLK_Q => {
                        keys[4] = 0;
                    },

                    sdl.SDLK_W => {
                        keys[5] = 0;
                    },

                    sdl.SDLK_E => {
                        keys[6] = 0;
                    },

                    sdl.SDLK_A => {
                        keys[7] = 0;
                    },

                    sdl.SDLK_S => {
                        keys[8] = 0;
                    },

                    sdl.SDLK_D => {
                        keys[9] = 0;
                    },

                    sdl.SDLK_Z => {
                        keys[0xA] = 0;
                    },

                    sdl.SDLK_C => {
                        keys[0xB] = 0;
                    },

                    sdl.SDLK_4 => {
                        keys[0xC] = 0;
                    },

                    sdl.SDLK_R => {
                        keys[0xD] = 0;
                    },

                    sdl.SDLK_F => {
                        keys[0xE] = 0;
                    },

                    sdl.SDLK_V => {
                        keys[0xF] = 0;
                    },

                    else => {},
                }
            },
            else => {},
        }
    }
    return quit;
}
