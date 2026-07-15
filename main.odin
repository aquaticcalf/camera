package main

import "core:fmt"
import "core:c"
import "base:runtime"
import "core:sys/windows"
import glfw "vendor:glfw"
import gl "vendor:OpenGL"

APP_NAME :: "Camera"
SPACE_KEY :: 32

MENU_MIRROR      :: 200
MENU_CONSTRAIN   :: 201
MENU_DECORATIONS :: 202
MENU_QUIT        :: 203
MENU_CAMERA_BASE :: 300
MENU_RESIZE_BASE :: 400

Resize_Preset :: struct {
	label: string,
	w, h:  i32,
}

RESIZE_PRESETS :: [?]Resize_Preset{
	{"640 \u00d7 480",   640,  480},
	{"800 \u00d7 600",   800,  600},
	{"1280 \u00d7 720",  1280, 720},
	{"1920 \u00d7 1080", 1920, 1080},
}

App :: struct {
	cam:          Camera,
	tex:          u32,
	win_w:        i32,
	win_h:        i32,
	space_down:   bool,
	dragging:     bool,
	pan_x:        f32,
	pan_y:        f32,
	drag_start_x: f64,
	drag_start_y: f64,
	pan_start_x:  f32,
	pan_start_y:  f32,
	win_drag:     bool,
	win_drag_sx:  f64,
	win_drag_sy:  f64,
	vao:          u32,
	vbo:          u32,
	shader:       u32,
	uv_uniform:   i32,
	mirrored:     bool,
	constrain:    bool,
	decorated:    bool,
	selected_cam: u32,
	devices_raw:  rawptr,
	dev_count:    u32,
	window:       glfw.WindowHandle,
	hwnd:         windows.HWND,
	cam_ok:       bool,
}

vertex_shader_src   := cstring(raw_data(#load("vert.glsl")))
fragment_shader_src := cstring(raw_data(#load("frag.glsl")))
icon_pixels         := #load("camera.rgba")

quad_vertices := [16]f32{
	-1, -1, 0, 1,
	 1, -1, 1, 1,
	 1,  1, 1, 0,
	-1,  1, 0, 0,
}

main :: proc() {
	devices_raw, dev_count, ok := camera_list_devices()
	if !ok || dev_count == 0 {
		return
	}

	if !glfw.Init() {
		return
	}
	defer glfw.Terminate()

	glfw.WindowHint(glfw.DECORATED, 1)
	glfw.WindowHint(glfw.RESIZABLE, 1)
	glfw.WindowHint(glfw.FLOATING, 1)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

	win := glfw.CreateWindow(1280, 720, APP_NAME, nil, nil)
	if win == nil {
		return
	}
	defer glfw.DestroyWindow(win)

	hwnd := glfw.GetWin32Window(win)

	glfw.MakeContextCurrent(win)
	glfw.SwapInterval(1)
	gl.load_up_to(3, 3, glfw.gl_set_proc_address)

	app: App
	app.decorated = true
	app.devices_raw = devices_raw
	app.dev_count = dev_count
	app.window = win
	app.hwnd = hwnd
	app.win_w = 1280
	app.win_h = 720

	glfw.SetWindowIcon(win, []glfw.Image{{256, 256, raw_data(icon_pixels)}})

	if camera_init(&app.cam, 0) {
		app.cam_ok = true
		app.selected_cam = 0
	}

	gl.GenTextures(1, &app.tex)
	gl.BindTexture(gl.TEXTURE_2D, app.tex)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)

	setup_gl(&app)

	glfw.SetWindowUserPointer(win, &app)

	glfw.SetWindowSizeCallback(win, proc "c" (w: glfw.WindowHandle, wi, he: c.int) {
		context = runtime.default_context()
		a := (^App)(glfw.GetWindowUserPointer(w))
		if a != nil {
			a.win_w = wi
			a.win_h = he
			gl.Viewport(0, 0, wi, he)
		}
	})

	glfw.SetKeyCallback(win, proc "c" (w: glfw.WindowHandle, key, scancode, action, mods: c.int) {
		context = runtime.default_context()
		a := (^App)(glfw.GetWindowUserPointer(w))
		if a != nil && key == SPACE_KEY {
			a.space_down = action == glfw.PRESS || action == glfw.REPEAT
			if action == glfw.RELEASE { a.dragging = false }
		}
	})

	glfw.SetMouseButtonCallback(win, proc "c" (w: glfw.WindowHandle, button, action, mods: c.int) {
		context = runtime.default_context()
		a := (^App)(glfw.GetWindowUserPointer(w))
		if a == nil { return }
		if button == glfw.MOUSE_BUTTON_RIGHT && action == glfw.PRESS {
			show_context_menu(a)
			return
		}
		if button == glfw.MOUSE_BUTTON_LEFT {
			if action == glfw.PRESS {
				if a.space_down {
					a.dragging = true
					a.drag_start_x, a.drag_start_y = glfw.GetCursorPos(w)
					a.pan_start_x = a.pan_x
					a.pan_start_y = a.pan_y
				} else if !a.decorated {
					a.win_drag = true
					a.win_drag_sx, a.win_drag_sy = glfw.GetCursorPos(w)
				}
			} else {
				a.dragging = false
				a.win_drag = false
			}
		}
	})

	glfw.SetCursorPosCallback(win, proc "c" (w: glfw.WindowHandle, x, y: f64) {
		context = runtime.default_context()
		a := (^App)(glfw.GetWindowUserPointer(w))
		if a == nil { return }
		if a.win_drag {
			wx, wy := glfw.GetWindowPos(w)
			dx := i32(x - a.win_drag_sx)
			dy := i32(y - a.win_drag_sy)
			glfw.SetWindowPos(w, wx + dx, wy + dy)
		}
		if a.dragging {
			dx := f32(x - a.drag_start_x) / f32(a.win_w)
			dy := f32(y - a.drag_start_y) / f32(a.win_h)
			a.pan_x = a.pan_start_x - dx
			a.pan_y = a.pan_start_y - dy
		}
	})

	for !glfw.WindowShouldClose(win) {
		glfw.PollEvents()
		a_w, a_h := glfw.GetWindowSize(win)
		app.win_w = a_w
		app.win_h = a_h
		if app.win_w == 0 || app.win_h == 0 { continue }

		if app.cam_ok {
			data, frame_ok := camera_read_frame(&app.cam)
			if frame_ok && len(data) >= int(app.cam.width * app.cam.height * 4) {
				gl.BindTexture(gl.TEXTURE_2D, app.tex)
				gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, i32(app.cam.width), i32(app.cam.height), 0, gl.BGRA, gl.UNSIGNED_BYTE, raw_data(data))
			}
		}

		render(&app)
		glfw.SwapBuffers(win)
		windows.SetWindowPos(app.hwnd, windows.HWND_TOPMOST, 0, 0, 0, 0, windows.SWP_NOMOVE | windows.SWP_NOSIZE | windows.SWP_NOACTIVATE)
	}

	if app.cam_ok { camera_destroy(&app.cam) }
	camera_free_device_list(app.devices_raw, app.dev_count)
}

show_context_menu :: proc(app: ^App) {
	hmenu := windows.CreatePopupMenu()
	defer windows.DestroyMenu(hmenu)

	cam_menu := windows.CreatePopupMenu()
	for i in 0 ..< app.dev_count {
		name := camera_get_device_name(app.devices_raw, i)
		wname := windows.utf8_to_wstring(name)
		flags: windows.UINT = windows.MF_STRING
		if app.cam_ok && i == app.selected_cam { flags |= windows.MF_CHECKED }
		windows.AppendMenuW(cam_menu, flags, uintptr(MENU_CAMERA_BASE + i), wname)
	}
	windows.AppendMenuW(hmenu, windows.MF_STRING | windows.MF_POPUP, uintptr(cam_menu), windows.L("Camera"))

	windows.AppendMenuW(hmenu, windows.MF_SEPARATOR, 0, nil)

	mirror_flags: windows.UINT = windows.MF_STRING
	if app.mirrored { mirror_flags |= windows.MF_CHECKED }
	windows.AppendMenuW(hmenu, mirror_flags, MENU_MIRROR, windows.L("Mirror"))

	constrain_flags: windows.UINT = windows.MF_STRING
	if app.constrain { constrain_flags |= windows.MF_CHECKED }
	windows.AppendMenuW(hmenu, constrain_flags, MENU_CONSTRAIN, windows.L("Constrain Proportions"))

	deco_flags: windows.UINT = windows.MF_STRING
	if app.decorated { deco_flags |= windows.MF_CHECKED }
	windows.AppendMenuW(hmenu, deco_flags, MENU_DECORATIONS, windows.L("Window Decorations"))

	windows.AppendMenuW(hmenu, windows.MF_SEPARATOR, 0, nil)

	resize_menu := windows.CreatePopupMenu()
	for preset, i in RESIZE_PRESETS {
		wlabel := windows.utf8_to_wstring(preset.label)
		windows.AppendMenuW(resize_menu, windows.MF_STRING, uintptr(MENU_RESIZE_BASE + u32(i)), wlabel)
	}
	windows.AppendMenuW(hmenu, windows.MF_STRING | windows.MF_POPUP, uintptr(resize_menu), windows.L("Resize"))

	windows.AppendMenuW(hmenu, windows.MF_SEPARATOR, 0, nil)
	windows.AppendMenuW(hmenu, windows.MF_STRING, MENU_QUIT, windows.L("Quit"))

	pt: windows.POINT
	windows.GetCursorPos(&pt)
	hwnd := glfw.GetWin32Window(app.window)
	windows.SetForegroundWindow(hwnd)
	cmd := windows.TrackPopupMenu(hmenu, windows.TPM_RETURNCMD | windows.TPM_RIGHTBUTTON, pt.x, pt.y, 0, hwnd, nil)

	handle_menu_command(app, i32(cmd))

	windows.SetWindowPos(hwnd, windows.HWND_TOPMOST, 0, 0, 0, 0, windows.SWP_NOMOVE | windows.SWP_NOSIZE | windows.SWP_NOACTIVATE)
}

handle_menu_command :: proc(app: ^App, cmd: i32) {
	if cmd == 0 { return }

	if cmd == MENU_QUIT {
		glfw.SetWindowShouldClose(app.window, true)
		return
	}

	if cmd == MENU_MIRROR {
		app.mirrored = !app.mirrored
		return
	}

	if cmd == MENU_CONSTRAIN {
		app.constrain = !app.constrain
		if app.constrain && app.cam_ok {
			glfw.SetWindowAspectRatio(app.window, i32(app.cam.width), i32(app.cam.height))
		} else {
			glfw.SetWindowAspectRatio(app.window, glfw.DONT_CARE, glfw.DONT_CARE)
		}
		return
	}

	if cmd == MENU_DECORATIONS {
		app.decorated = !app.decorated
		glfw.SetWindowAttrib(app.window, glfw.DECORATED, app.decorated ? 1 : 0)
		return
	}

	if cmd >= MENU_CAMERA_BASE && cmd < MENU_CAMERA_BASE + i32(app.dev_count) {
		new_cam := u32(cmd - MENU_CAMERA_BASE)
		if new_cam != app.selected_cam || !app.cam_ok {
			switch_camera(app, new_cam)
		}
		return
	}

	if cmd >= MENU_RESIZE_BASE && cmd < MENU_RESIZE_BASE + i32(len(RESIZE_PRESETS)) {
		idx := cmd - MENU_RESIZE_BASE
		presets := RESIZE_PRESETS
		glfw.SetWindowSize(app.window, presets[idx].w, presets[idx].h)
		return
	}
}

switch_camera :: proc(app: ^App, index: u32) {
	if app.cam_ok {
		camera_destroy(&app.cam)
		app.cam_ok = false
	}
	app.cam = {}
	if camera_init(&app.cam, index) {
		app.cam_ok = true
		app.selected_cam = index
		if app.constrain {
			glfw.SetWindowAspectRatio(app.window, i32(app.cam.width), i32(app.cam.height))
		}
	}
}

setup_gl :: proc(app: ^App) {
	vs := compile_shader(vertex_shader_src, gl.VERTEX_SHADER)
	fs := compile_shader(fragment_shader_src, gl.FRAGMENT_SHADER)
	app.shader = gl.CreateProgram()
	gl.AttachShader(app.shader, vs)
	gl.AttachShader(app.shader, fs)
	gl.LinkProgram(app.shader)

	status: i32
	gl.GetProgramiv(app.shader, gl.LINK_STATUS, &status)
	if status == 0 {
		log: [512]u8
		gl.GetProgramInfoLog(app.shader, 512, nil, raw_data(log[:]))
		fmt.eprintln("Shader link error:", string(log[:]))
	}
	gl.DeleteShader(vs)
	gl.DeleteShader(fs)

	gl.GenVertexArrays(1, &app.vao)
	gl.GenBuffers(1, &app.vbo)
	gl.BindVertexArray(app.vao)
	gl.BindBuffer(gl.ARRAY_BUFFER, app.vbo)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(quad_vertices), &quad_vertices[0], gl.STATIC_DRAW)
	gl.EnableVertexAttribArray(0)
	gl.VertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, 4 * size_of(f32), 0)
	gl.EnableVertexAttribArray(1)
	gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, 4 * size_of(f32), uintptr(2 * size_of(f32)))

	app.uv_uniform = gl.GetUniformLocation(app.shader, "uv_rect")
}

compile_shader :: proc(src: cstring, kind: u32) -> u32 {
	s := gl.CreateShader(kind)
	srcs := [1]cstring{src}
	gl.ShaderSource(s, 1, raw_data(srcs[:]), nil)
	gl.CompileShader(s)
	status: i32
	gl.GetShaderiv(s, gl.COMPILE_STATUS, &status)
	if status == 0 {
		log: [512]u8
		gl.GetShaderInfoLog(s, 512, nil, raw_data(log[:]))
		fmt.eprintln("Shader compile error:", string(log[:]))
	}
	return s
}

clamp_pan :: proc(v, max: f32) -> f32 {
	if v < -max { return -max }
	if v >  max { return  max }
	return v
}

render :: proc(app: ^App) {
	gl.Clear(gl.COLOR_BUFFER_BIT)
	if !app.cam_ok { return }

	cw := f32(app.cam.width)
	ch := f32(app.cam.height)
	ww := f32(app.win_w)
	wh := f32(app.win_h)

	cam_aspect := cw / ch
	win_aspect := ww / wh

	crop_w, crop_h: f32
	if win_aspect > cam_aspect {
		crop_w = cw
		crop_h = cw / win_aspect
	} else {
		crop_w = ch * win_aspect
		crop_h = ch
	}

	max_pan_x := (cw - crop_w) / cw
	max_pan_y := (ch - crop_h) / ch
	px := clamp_pan(app.pan_x, max_pan_x)
	py := clamp_pan(app.pan_y, max_pan_y)

	uv_x := (cw - crop_w) / (2.0 * cw) + px
	uv_y := (ch - crop_h) / (2.0 * ch) + py
	uv_w := crop_w / cw
	uv_h := crop_h / ch

	if app.mirrored {
		uv_x = uv_x + uv_w
		uv_w = -uv_w
	}

	gl.UseProgram(app.shader)
	gl.Uniform4f(app.uv_uniform, uv_x, uv_y, uv_w, uv_h)
	gl.BindVertexArray(app.vao)
	gl.ActiveTexture(gl.TEXTURE0)
	gl.BindTexture(gl.TEXTURE_2D, app.tex)
	gl.DrawArrays(gl.TRIANGLE_FAN, 0, 4)
}
