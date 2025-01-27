package main

import "core:c"
import "core:fmt"
import "core:strings"
import gl "vendor:OpenGL"
import "vendor:glfw"

GL_MAJOR_VERSION :: 3
GL_MINOR_VERSION :: 3


vertex_shader_src: cstring = `#version 330 core
layout (location = 0) in vec3 aPos;
void main() {
    gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
}`



fragment_shader_src: cstring = `#version 330 core
out vec4 FragColor;
void main() {
   FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
}`



main :: proc() {
    if !bool(glfw.Init()) {
        fmt.println("GLFW has failed to load")
        return
    }
    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_MAJOR_VERSION)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_MINOR_VERSION)
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
    glfw.WindowHint(glfw.OPENGL_FORWARD_COMPAT, glfw.TRUE)

    window_handle := glfw.CreateWindow(800, 600, "LearnOpenGL", nil, nil)
    defer glfw.Terminate()
    defer glfw.DestroyWindow(window_handle)
    if window_handle == nil {
        fmt.eprintln("Failed to create GLFW window")
        return
    }

    // Load OpenGL context or the "state" of OpenGL.
    glfw.MakeContextCurrent(window_handle)

    // Load OpenGL function pointers with the specified OpenGL major and minor version.
    gl.load_up_to(GL_MAJOR_VERSION, GL_MINOR_VERSION, glfw.gl_set_proc_address)

    // Set the viewport size.
    gl.Viewport(0, 0, 800, 600)

    // Handle window resizing and set the viewport size accordingly.
    glfw.SetFramebufferSizeCallback(window_handle, framebuffer_size_callback)


    // Build and compile our shader program.
    // -------------------------------------
    vertex_shader := gl.CreateShader(gl.VERTEX_SHADER)
    gl.ShaderSource(vertex_shader, 1, &vertex_shader_src, nil)
    gl.CompileShader(vertex_shader)

    success: i32
    info_log: [512]u8
    gl.GetShaderiv(vertex_shader, gl.COMPILE_STATUS, &success)
    if !bool(success) {
        gl.GetShaderInfoLog(vertex_shader, 512, nil, raw_data(info_log[:]))
        fmt.eprintln("ERROR::SHADER::VERTEX::COMPILATION_FAILED\n%s", string(info_log[:]))
    }

    frag_shader := gl.CreateShader(gl.FRAGMENT_SHADER)
    gl.ShaderSource(frag_shader, 1, &fragment_shader_src, nil)
    gl.CompileShader(frag_shader)

    success = 0
    info_log = [512]u8{}
    gl.GetShaderiv(frag_shader, gl.COMPILE_STATUS, &success)
    if !bool(success) {
        gl.GetShaderInfoLog(frag_shader, 512, nil, raw_data(info_log[:]))
        fmt.eprintln("ERROR::SHADER::FRAGMENT::COMPILATION_FAILED\n%s", string(info_log[:]))
    }

    shader_program := gl.CreateProgram()
    gl.AttachShader(shader_program, vertex_shader)
    gl.AttachShader(shader_program, frag_shader)
    gl.LinkProgram(shader_program)

    success = 0
    info_log = [512]u8{}
    gl.GetProgramiv(shader_program, gl.LINK_STATUS, &success)
    if !bool(success) {
        gl.GetProgramInfoLog(shader_program, 512, nil, raw_data(info_log[:]))
        fmt.eprintln("ERROR::SHADER::PROGRAM::LINKING_FAILED\n%s", string(info_log[:]))
    }
    gl.DeleteShader(vertex_shader)
    gl.DeleteShader(frag_shader)

    // Set up vertex data (and buffer(s)) and configure vertex attributes.
    // ------------------------------------------------------------------
    vertices := [?]f32{-0.5, -0.5, 0.0, 0.5, -0.5, 0.0, 0.0, 0.5, 0.0}

    vao: u32
    gl.GenVertexArrays(1, &vao)
    gl.BindVertexArray(vao)

    vbo: u32
    gl.GenBuffers(1, &vbo)
    gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.STATIC_DRAW)

    // Set up vertex data and buffers and configure vertex attributes.
    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), uintptr(0))
    gl.EnableVertexAttribArray(0)

    // Unbind the VBO and VAO to prevent accidental changes.
    gl.BindBuffer(gl.ARRAY_BUFFER, 0)
    gl.BindVertexArray(0)


    // Main loop.
    for !glfw.WindowShouldClose(window_handle) {
        process_input(window_handle)

        // rendering commands here
        gl.ClearColor(0.2, 0.3, 0.3, 1.0)
        gl.Clear(gl.COLOR_BUFFER_BIT)

        gl.UseProgram(shader_program)
        gl.BindVertexArray(vao)
        gl.DrawArrays(gl.TRIANGLES, 0, 3)

        glfw.SwapBuffers(window_handle)
        glfw.PollEvents()
    }

    // De-allocate resources.
    gl.DeleteVertexArrays(1, &vao)
    gl.DeleteBuffers(1, &vbo)
    gl.DeleteProgram(shader_program)
}

framebuffer_size_callback :: proc "c" (window: glfw.WindowHandle, width, height: c.int) {
    gl.Viewport(0, 0, width, height)
}

process_input :: proc(window: glfw.WindowHandle) {
    if glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS {
        glfw.SetWindowShouldClose(window, true)
    }
}
