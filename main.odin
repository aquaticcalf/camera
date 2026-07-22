package main

import "core:c"
import "base:runtime"
import "core:sys/windows"
import camera "camera"
import renderer "renderer"
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
	{"640 × 480",   640,  480},
	{"800 × 600",   800,  600},
	{"1280 × 720", 1280, 720},
	{"1920 × 1080", 1920, 1080},
}

App :: struct {
	camera_system: camera.System,
	cam:           camera.Stream,
	cam_size:      camera.Size,
	renderer:      renderer.Renderer,

	win_w: i32,
	win_h: i32,
	space_down: bool,

	dragging:     bool,
	drag_start_x: f64,
	drag_start_y: f64,
	pan_start_x:  f32,
	pan_start_y:  f32,
	pan_x:        f32,
	pan_y:        f32,

	win_drag:    bool,
	win_drag_sx: i32,
	win_drag_sy: i32,
	win_start_x: i32,
	win_start_y: i32,

	mirrored:     bool,
	constrain:    bool,
	constraint_w: i32,
	constraint_h: i32,
	decorated:    bool,
	selected_cam: u32,
	window:       glfw.WindowHandle,
	hwnd:         windows.HWND,
	cam_ok:       bool,
}

icon_pixels := #load("camera.rgba")

main :: proc() {
	system, ok := camera.system_open()
	if !ok { return }

	app: App
	app.camera_system = system
	defer camera.system_close(&app.camera_system)
	if camera.device_count(&app.camera_system) == 0 { return }

	if !glfw.Init() { return }
	defer glfw.Terminate()

	glfw.WindowHint(glfw.DECORATED, 1)
	glfw.WindowHint(glfw.RESIZABLE, 1)
	glfw.WindowHint(glfw.FLOATING, 1)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

	win := glfw.CreateWindow(1280, 720, APP_NAME, nil, nil)
	if win == nil { return }
	defer glfw.DestroyWindow(win)

	app.window = win
	app.hwnd = glfw.GetWin32Window(win)
	app.win_w = 1280
	app.win_h = 720
	app.decorated = true

	glfw.MakeContextCurrent(win)
	glfw.SwapInterval(1)
	gl.load_up_to(3, 3, glfw.gl_set_proc_address)
	glfw.SetWindowIcon(win, []glfw.Image{{256, 256, raw_data(icon_pixels)}})

	if camera.stream_open(&app.cam, 0) {
		app.cam_ok = true
		app.cam_size = camera.stream_size(&app.cam)
		app.selected_cam = 0
	}

	renderer_instance, renderer_ok := renderer.open()
	if !renderer_ok {
		if app.cam_ok { camera.stream_close(&app.cam) }
		return
	}
	app.renderer = renderer_instance
	renderer.resize(&app.renderer, app.win_w, app.win_h)

	glfw.SetWindowUserPointer(win, &app)
	glfw.SetWindowSizeCallback(win, proc "c" (w: glfw.WindowHandle, width, height: c.int) {
		context = runtime.default_context()
		app := (^App)(glfw.GetWindowUserPointer(w))
		if app != nil {
			app.win_w = width
			app.win_h = height
			renderer.resize(&app.renderer, width, height)
		}
	})

	glfw.SetKeyCallback(win, proc "c" (w: glfw.WindowHandle, key, scancode, action, mods: c.int) {
		context = runtime.default_context()
		app := (^App)(glfw.GetWindowUserPointer(w))
		if app != nil && key == SPACE_KEY {
			app.space_down = action == glfw.PRESS || action == glfw.REPEAT
			if action == glfw.RELEASE { app.dragging = false }
		}
	})

	glfw.SetMouseButtonCallback(win, proc "c" (w: glfw.WindowHandle, button, action, mods: c.int) {
		context = runtime.default_context()
		app := (^App)(glfw.GetWindowUserPointer(w))
		if app == nil { return }
		if button == glfw.MOUSE_BUTTON_RIGHT && action == glfw.PRESS {
			show_context_menu(app)
			return
		}
		if button != glfw.MOUSE_BUTTON_LEFT { return }
		if action == glfw.PRESS {
			cursor: windows.POINT
			windows.GetCursorPos(&cursor)
			if app.space_down {
				app.dragging = true
				app.drag_start_x = f64(cursor.x)
				app.drag_start_y = f64(cursor.y)
				app.pan_start_x = app.pan_x
				app.pan_start_y = app.pan_y
			} else if !app.decorated {
				set_window_dragging(app, true)
				app.win_drag_sx = cursor.x
				app.win_drag_sy = cursor.y
				app.win_start_x, app.win_start_y = glfw.GetWindowPos(w)
			}
		} else if action == glfw.RELEASE {
			app.dragging = false
			set_window_dragging(app, false)
		}
	})

	for !glfw.WindowShouldClose(win) {
		glfw.PollEvents()
		update_drag(&app)

		app.win_w, app.win_h = glfw.GetWindowSize(win)
		if app.win_w == 0 || app.win_h == 0 { continue }

		if app.cam_ok {
			data, frame_ok := camera.stream_read_frame(&app.cam)
			if frame_ok {
				renderer.upload(&app.renderer, data, app.cam_size)
			}
		}

		renderer.draw(&app.renderer, renderer.View{
			Format   = app.cam_size,
			Window_W = app.win_w,
			Window_H = app.win_h,
			Pan_X    = app.pan_x,
			Pan_Y    = app.pan_y,
			Mirrored = app.mirrored,
		})
		glfw.SwapBuffers(win)
		windows.SetWindowPos(app.hwnd, windows.HWND_TOPMOST, 0, 0, 0, 0, windows.SWP_NOMOVE | windows.SWP_NOSIZE | windows.SWP_NOACTIVATE)
	}

	renderer.close(&app.renderer)
	if app.cam_ok { camera.stream_close(&app.cam) }
}

update_drag :: proc(app: ^App) {
	if app == nil || (!app.dragging && !app.win_drag) { return }
	if windows.GetAsyncKeyState(windows.VK_LBUTTON) >= 0 {
		app.dragging = false
		set_window_dragging(app, false)
		return
	}

	cursor: windows.POINT
	windows.GetCursorPos(&cursor)
	if app.win_drag {
		glfw.SetWindowPos(app.window, app.win_start_x + cursor.x - app.win_drag_sx, app.win_start_y + cursor.y - app.win_drag_sy)
	}
	if app.dragging {
		dx := f32(f64(cursor.x) - app.drag_start_x) / f32(app.win_w)
		dy := f32(f64(cursor.y) - app.drag_start_y) / f32(app.win_h)
		app.pan_x = app.pan_start_x - dx
		app.pan_y = app.pan_start_y - dy
	}
}

set_window_dragging :: proc(app: ^App, dragging: bool) {
	if app == nil { return }
	app.win_drag = dragging
	mode: c.int = glfw.CURSOR_NORMAL
	if dragging { mode = glfw.CURSOR_HIDDEN }
	glfw.SetInputMode(app.window, glfw.CURSOR, mode)
}

show_context_menu :: proc(app: ^App) {
	hmenu := windows.CreatePopupMenu()
	defer windows.DestroyMenu(hmenu)

	camera_menu := windows.CreatePopupMenu()
	count := camera.device_count(&app.camera_system)
	for i in 0 ..< count {
		name := camera.device_name(&app.camera_system, i)
		wname := windows.utf8_to_wstring(name)
		flags: windows.UINT = windows.MF_STRING
		if app.cam_ok && i == app.selected_cam { flags |= windows.MF_CHECKED }
		windows.AppendMenuW(camera_menu, flags, uintptr(MENU_CAMERA_BASE + i), wname)
	}
	windows.AppendMenuW(hmenu, windows.MF_STRING | windows.MF_POPUP, uintptr(camera_menu), windows.L("Camera"))
	windows.AppendMenuW(hmenu, windows.MF_SEPARATOR, 0, nil)

	mirror_flags: windows.UINT = windows.MF_STRING
	if app.mirrored { mirror_flags |= windows.MF_CHECKED }
	windows.AppendMenuW(hmenu, mirror_flags, MENU_MIRROR, windows.L("Mirror"))

	constrain_flags: windows.UINT = windows.MF_STRING
	if app.constrain { constrain_flags |= windows.MF_CHECKED }
	windows.AppendMenuW(hmenu, constrain_flags, MENU_CONSTRAIN, windows.L("Constrain Proportions"))

	decoration_flags: windows.UINT = windows.MF_STRING
	if app.decorated { decoration_flags |= windows.MF_CHECKED }
	windows.AppendMenuW(hmenu, decoration_flags, MENU_DECORATIONS, windows.L("Window Decorations"))
	windows.AppendMenuW(hmenu, windows.MF_SEPARATOR, 0, nil)

	resize_menu := windows.CreatePopupMenu()
	for preset, i in RESIZE_PRESETS {
		wlabel := windows.utf8_to_wstring(preset.label)
		windows.AppendMenuW(resize_menu, windows.MF_STRING, uintptr(MENU_RESIZE_BASE + u32(i)), wlabel)
	}
	windows.AppendMenuW(hmenu, windows.MF_STRING | windows.MF_POPUP, uintptr(resize_menu), windows.L("Resize"))
	windows.AppendMenuW(hmenu, windows.MF_SEPARATOR, 0, nil)
	windows.AppendMenuW(hmenu, windows.MF_STRING, MENU_QUIT, windows.L("Quit"))

	point: windows.POINT
	windows.GetCursorPos(&point)
	hwnd := glfw.GetWin32Window(app.window)
	windows.SetForegroundWindow(hwnd)
	command := windows.TrackPopupMenu(hmenu, windows.TPM_RETURNCMD | windows.TPM_RIGHTBUTTON, point.x, point.y, 0, hwnd, nil)
	handle_menu_command(app, i32(command))
	windows.SetWindowPos(hwnd, windows.HWND_TOPMOST, 0, 0, 0, 0, windows.SWP_NOMOVE | windows.SWP_NOSIZE | windows.SWP_NOACTIVATE)
}

handle_menu_command :: proc(app: ^App, command: i32) {
	if command == 0 { return }
	if command == MENU_QUIT {
		glfw.SetWindowShouldClose(app.window, true)
		return
	}
	if command == MENU_MIRROR {
		app.mirrored = !app.mirrored
		return
	}
	if command == MENU_CONSTRAIN {
		if app.constrain {
			app.constrain = false
		} else {
			app.constraint_w = app.win_w
			app.constraint_h = app.win_h
			app.constrain = app.constraint_w > 0 && app.constraint_h > 0
		}
		apply_aspect_constraint(app)
		return
	}
	if command == MENU_DECORATIONS {
		app.decorated = !app.decorated
		glfw.SetWindowAttrib(app.window, glfw.DECORATED, app.decorated ? 1 : 0)
		return
	}

	count := camera.device_count(&app.camera_system)
	if command >= MENU_CAMERA_BASE && command < MENU_CAMERA_BASE + i32(count) {
		index := u32(command - MENU_CAMERA_BASE)
		if index != app.selected_cam || !app.cam_ok { switch_camera(app, index) }
		return
	}
	if command >= MENU_RESIZE_BASE && command < MENU_RESIZE_BASE + i32(len(RESIZE_PRESETS)) {
		presets := RESIZE_PRESETS
		preset := presets[command - MENU_RESIZE_BASE]
		glfw.SetWindowSize(app.window, preset.w, preset.h)
	}
}

apply_aspect_constraint :: proc(app: ^App) {
	if app.constrain && app.constraint_w > 0 && app.constraint_h > 0 {
		glfw.SetWindowAspectRatio(app.window, app.constraint_w, app.constraint_h)
	} else {
		glfw.SetWindowAspectRatio(app.window, glfw.DONT_CARE, glfw.DONT_CARE)
	}
}

switch_camera :: proc(app: ^App, index: u32) {
	if app.cam_ok {
		camera.stream_close(&app.cam)
		app.cam_ok = false
	}
	app.cam_size = {}
	if camera.stream_open(&app.cam, index) {
		app.cam_ok = true
		app.cam_size = camera.stream_size(&app.cam)
		app.selected_cam = index
		apply_aspect_constraint(app)
	}
}
