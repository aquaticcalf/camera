package renderer

import "core:c"
import "core:fmt"
import camera "../camera"
import gl "vendor:OpenGL"

Renderer :: struct {
	texture:        u32,
	vao:            u32,
	vbo:            u32,
	shader:         u32,
	uv_uniform:     i32,
	texture_uniform: i32,
}

View :: struct {
	Format:   camera.Size,
	Window_W: i32,
	Window_H: i32,
	Pan_X:    f32,
	Pan_Y:    f32,
	Mirrored: bool,
}

vertex_shader_source   := cstring(raw_data(#load("vert.glsl")))
fragment_shader_source := cstring(raw_data(#load("frag.glsl")))

quad_vertices := [16]f32{
	-1, -1, 0, 1,
	 1, -1, 1, 1,
	 1,  1, 1, 0,
	-1,  1, 0, 0,
}

open :: proc() -> (result: Renderer, ok: bool) {
	gl.GenTextures(1, &result.texture)
	gl.BindTexture(gl.TEXTURE_2D, result.texture)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)

	vertex_shader := compile_shader(vertex_shader_source, gl.VERTEX_SHADER)
	fragment_shader := compile_shader(fragment_shader_source, gl.FRAGMENT_SHADER)
	result.shader = gl.CreateProgram()
	gl.AttachShader(result.shader, vertex_shader)
	gl.AttachShader(result.shader, fragment_shader)
	gl.LinkProgram(result.shader)
	gl.DeleteShader(vertex_shader)
	gl.DeleteShader(fragment_shader)

	status: i32
	gl.GetProgramiv(result.shader, gl.LINK_STATUS, &status)
	if status == 0 {
		log: [512]u8
		gl.GetProgramInfoLog(result.shader, 512, nil, raw_data(log[:]))
		fmt.eprintln("renderer: shader link error:", string(log[:]))
		close(&result)
		return {}, false
	}

	gl.GenVertexArrays(1, &result.vao)
	gl.GenBuffers(1, &result.vbo)
	gl.BindVertexArray(result.vao)
	gl.BindBuffer(gl.ARRAY_BUFFER, result.vbo)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(quad_vertices), &quad_vertices[0], gl.STATIC_DRAW)
	gl.EnableVertexAttribArray(0)
	gl.VertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, 4 * size_of(f32), 0)
	gl.EnableVertexAttribArray(1)
	gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, 4 * size_of(f32), uintptr(2 * size_of(f32)))

	result.uv_uniform = gl.GetUniformLocation(result.shader, "uv_rect")
	result.texture_uniform = gl.GetUniformLocation(result.shader, "tex")
	gl.UseProgram(result.shader)
	gl.Uniform1i(result.texture_uniform, 0)
	return result, true
}

close :: proc(result: ^Renderer) {
	if result == nil { return }
	if result.texture != 0 { gl.DeleteTextures(1, &result.texture) }
	if result.vbo != 0 { gl.DeleteBuffers(1, &result.vbo) }
	if result.vao != 0 { gl.DeleteVertexArrays(1, &result.vao) }
	if result.shader != 0 { gl.DeleteProgram(result.shader) }
	result^ = {}
}

resize :: proc(result: ^Renderer, width, height: i32) {
	if result == nil { return }
	gl.Viewport(0, 0, width, height)
}

upload :: proc(result: ^Renderer, data: []u8, size: camera.Size) {
	if result == nil || len(data) == 0 { return }
	gl.BindTexture(gl.TEXTURE_2D, result.texture)
	gl.TexImage2D(
		gl.TEXTURE_2D, 0, gl.RGBA,
		i32(size.Width), i32(size.Height), 0,
		gl.BGRA, gl.UNSIGNED_BYTE, raw_data(data),
	)
}

draw :: proc(result: ^Renderer, view: View) {
	if result == nil { return }
	gl.Clear(gl.COLOR_BUFFER_BIT)
	if view.Format.Width == 0 || view.Format.Height == 0 || view.Window_W == 0 || view.Window_H == 0 { return }

	cw := f32(view.Format.Width)
	ch := f32(view.Format.Height)
	ww := f32(view.Window_W)
	wh := f32(view.Window_H)
	camera_aspect := cw / ch
	window_aspect := ww / wh

	crop_w, crop_h: f32
	if window_aspect > camera_aspect {
		crop_w = cw
		crop_h = cw / window_aspect
	} else {
		crop_w = ch * window_aspect
		crop_h = ch
	}

	max_pan_x := (cw - crop_w) / cw
	max_pan_y := (ch - crop_h) / ch
	pan_x := clamp_pan(view.Pan_X, max_pan_x)
	pan_y := clamp_pan(view.Pan_Y, max_pan_y)

	uv_x := (cw - crop_w) / (2.0 * cw) + pan_x
	uv_y := (ch - crop_h) / (2.0 * ch) + pan_y
	uv_w := crop_w / cw
	uv_h := crop_h / ch
	if view.Mirrored {
		uv_x += uv_w
		uv_w = -uv_w
	}

	gl.UseProgram(result.shader)
	gl.Uniform4f(result.uv_uniform, uv_x, uv_y, uv_w, uv_h)
	gl.BindVertexArray(result.vao)
	gl.ActiveTexture(gl.TEXTURE0)
	gl.BindTexture(gl.TEXTURE_2D, result.texture)
	gl.DrawArrays(gl.TRIANGLE_FAN, 0, 4)
}

clamp_pan :: proc(value, maximum: f32) -> f32 {
	if value < -maximum { return -maximum }
	if value > maximum { return maximum }
	return value
}

compile_shader :: proc(source: cstring, kind: u32) -> u32 {
	shader := gl.CreateShader(kind)
	sources := [1]cstring{source}
	gl.ShaderSource(shader, 1, raw_data(sources[:]), nil)
	gl.CompileShader(shader)

	status: i32
	gl.GetShaderiv(shader, gl.COMPILE_STATUS, &status)
	if status == 0 {
		log: [512]u8
		gl.GetShaderInfoLog(shader, 512, nil, raw_data(log[:]))
		fmt.eprintln("renderer: shader compile error:", string(log[:]))
	}
	return shader
}
