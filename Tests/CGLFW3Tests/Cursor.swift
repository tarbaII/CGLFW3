import XCTest
@testable import CGLFW3

var cursorX = 0.0
var cursorY = 0.0
var swapInterval = 1 as Int32
var animateCursor = false
var waitEvents = true
var trackCursor = false

var standardCursors: [OpaquePointer?] = []
var trackingCursor: OpaquePointer?

class CursorTests: XCTestCase {
    let cursorFrameCount = 60
    
    let vertexShaderText = """
#version 110
uniform mat4 MVP;
attribute vec2 vPos;
void main()
{
    gl_Position = MVP * vec4(vPos, 0.0, 1.0);
}
"""
    
    let fragmentShaderText = """
#version 110
void main()
{
    gl_FragColor = vec4(1.0);
}
"""
    
    let errorCallback: GLFWerrorfun = { (_, description: UnsafePointer<CChar>?) -> Void in
        XCTFail("Error: \(description.map(String.init(cString:)) ?? "")")
    }
    
    func star(x: Int32, y: Int32, t: Float) -> Float {
        let c: Float = 64 / 2;
        
        let i: Float = (0.25 * sin(2.0 * .pi * t) + 0.75)
        let k: Float = 64 * 0.046875 * i
        
        let xf = Float(x)
        let yf = Float(y)
        let dist: Float = ((xf-c)*(xf-c) + (yf-c)*(yf-c)).squareRoot()
        
        let salpha: Float = 1.0 - dist / c
        let xalpha: Float = xf == c ? c : k / abs(xf - c)
        let yalpha: Float = yf == c ? c : k / abs(yf - c)
        
        return max(0, min(1, i * salpha * 0.2 + salpha * xalpha * yalpha))
    }
    
    func createCursorFrame(t: Float) -> OpaquePointer! {
        let pixels = (0 ..< 64).flatMap { y in
            (0 ..< 64).flatMap { x in
                return [
                    255, 255, 255, UInt8(255 * star(x: x, y: y, t: t))
                ]
            }
        }
        let buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: 64 * 64 * 4)
        _ = buffer.initialize(from: pixels)
        var image = GLFWimage(width: 64, height: 64, pixels: buffer.baseAddress)
        
        return glfwCreateCursor(&image, image.width / 2, image.height / 2)
    }
    
    func createTrackingCursor() -> OpaquePointer! {
        let pixels = (0 ..< 32).flatMap { y in
            (0 ..< 32).flatMap { x in
                if x == 7 || y == 7 {
                    return [255, 0, 0, 255] as [UInt8]
                } else {
                    return [0, 0, 0, 0] as [UInt8]
                }
            }
        }
        let buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: 32 * 32 * 4)
        _ = buffer.initialize(from: pixels)
        var image = GLFWimage(width: 32, height: 32, pixels: buffer.baseAddress)
        
        return glfwCreateCursor(&image, 7, 7)
    }
    
    let cursorPositionCallback: GLFWcursorposfun = { window, x, y in
        print(String(format: "%0.3f: Cursor position: %f %f (%+f %+f)",
                     glfwGetTime(),
                     x, y, x - cursorX, y - cursorY))
        
        cursorX = x
        cursorY = y
    }
    
    let keyCallback: GLFWkeyfun = { window, key, scancode, action, mods in
        if action != GLFW_PRESS {
            return
        }
        
        switch key {
        case GLFW_KEY_A:
            animateCursor.toggle()
            if !animateCursor {
                glfwSetCursor(window, nil)
            }
        case GLFW_KEY_ESCAPE:
            let mode = glfwGetInputMode(window, GLFW_CURSOR)
            if mode != GLFW_CURSOR_DISABLED && mode != GLFW_CURSOR_CAPTURED {
                glfwSetWindowShouldClose(window, GLFW_TRUE)
                break
            }
            fallthrough
        case GLFW_KEY_N:
            glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_NORMAL)
            glfwGetCursorPos(window, &cursorX, &cursorY)
            print("(( cursor is normal ))")
        case GLFW_KEY_D:
            glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_DISABLED)
            print("(( cursor is hidden ))")
        case GLFW_KEY_H:
            glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_HIDDEN)
            print("(( cursor is hidden ))")
        case GLFW_KEY_C:
            glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_CAPTURED)
            print("(( cursor is captured ))")
        case GLFW_KEY_R:
            guard glfwRawMouseMotionSupported() == GLFW_TRUE else {
                break
            }
            
            if glfwGetInputMode(window, GLFW_RAW_MOUSE_MOTION) == GLFW_TRUE {
                glfwSetInputMode(window, GLFW_RAW_MOUSE_MOTION, GLFW_FALSE)
                print("(( raw input is disabled ))")
            } else {
                glfwSetInputMode(window, GLFW_RAW_MOUSE_MOTION, GLFW_TRUE)
                print("(( raw input is enabled ))")
            }
        case GLFW_KEY_SPACE:
            swapInterval = 1 - swapInterval
            print("(( swap interval: \(swapInterval) ))")
            glfwSwapInterval(swapInterval)
        case GLFW_KEY_W:
            trackCursor.toggle()
            if trackCursor {
                glfwSetCursor(window, trackingCursor)
            } else {
                glfwSetCursor(window, nil)
            }
        case GLFW_KEY_P:
            var x = 0.0
            var y = 0.0
            glfwGetCursorPos(window, &x, &y)
            
            print(String(format: "Query before set: %f %f (%+f %+f)", x, y, x - cursorX, y - cursorY))
            cursorX = x
            cursorY = y
            
            glfwSetCursorPos(window, cursorX, cursorY)
            glfwGetCursorPos(window, &x, &y)
            
            print(String(format: "Query after set: %f %f (%+f %+f)", x, y, x - cursorX, y - cursorY))
            cursorX = x
            cursorY = y
        case GLFW_KEY_UP:
            glfwSetCursorPos(window, 0, 0)
            glfwGetCursorPos(window, &cursorX, &cursorY)
        case GLFW_KEY_DOWN:
            var width = 0 as Int32
            var height = 0 as Int32
            glfwGetWindowSize(window, &width, &height)
            glfwSetCursorPos(window, Double(width) - 1, Double(height) - 1)
            glfwGetCursorPos(window, &cursorX, &cursorY)
        case GLFW_KEY_0:
            glfwSetCursor(window, nil)
        case GLFW_KEY_1 ... GLFW_KEY_9:
            var index = key - GLFW_KEY_1
            if mods & GLFW_MOD_SHIFT == GLFW_TRUE {
                index += 9
            }
            
            if index < standardCursors.count {
                glfwSetCursor(window, standardCursors[Int(index)])
            }
        default:
            break
        }
    }
    
    func testCursors() {
        glfwSetErrorCallback(errorCallback)
        
        guard glfwInit() == GLFW_TRUE else {
            XCTFail("Failed to initialize GLFW")
            exit(EXIT_FAILURE)
        }
        
        var currentFrame: OpaquePointer?
        
        trackingCursor = createTrackingCursor()
        guard let trackingCursor else {
            glfwTerminate()
            XCTFail()
            exit(EXIT_FAILURE)
        }
        
        var starCursors = (0 ..< cursorFrameCount).map { i in
            guard let cursor = createCursorFrame(t: Float(i) / Float(cursorFrameCount)) else {
                glfwTerminate()
                XCTFail()
                exit(EXIT_FAILURE)
            }
            return cursor
        }
        
        standardCursors = [
            GLFW_ARROW_CURSOR,
            GLFW_IBEAM_CURSOR,
            GLFW_CROSSHAIR_CURSOR,
            GLFW_POINTING_HAND_CURSOR,
            GLFW_RESIZE_EW_CURSOR,
            GLFW_RESIZE_NS_CURSOR,
            GLFW_RESIZE_NWSE_CURSOR,
            GLFW_RESIZE_NESW_CURSOR,
            GLFW_RESIZE_ALL_CURSOR,
            GLFW_NOT_ALLOWED_CURSOR,
        ].map(glfwCreateStandardCursor)
        
        glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 2)
        glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 0)
        
        guard let window = glfwCreateWindow(640, 480, "Cursor Test", nil, nil) else {
            glfwTerminate()
            XCTFail("Failed to create window")
            return
        }
        
        glfwMakeContextCurrent(window)
        
        var vertexBuffer = 0 as GLuint
        glGenBuffers(1, &vertexBuffer)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBuffer)
        
        let vertexShader = glCreateShader(GLenum(GL_VERTEX_SHADER))
        vertexShaderText.withCString { string in
            glShaderSource(vertexShader, 1, [string], nil)
        }
        glCompileShader(vertexShader)
        
        let fragmentShader = glCreateShader(GLenum(GL_FRAGMENT_SHADER))
        fragmentShaderText.withCString { string in
            glShaderSource(fragmentShader, 1, [string], nil)
        }
        glCompileShader(fragmentShader)
        
        let program = glCreateProgram()
        glAttachShader(program, vertexShader)
        glAttachShader(program, fragmentShader)
        glLinkProgram(program)
        
        glDeleteShader(vertexShader)
        glDeleteShader(fragmentShader)
        
        let mvpLocation = glGetUniformLocation(program, "MVP")
        let vPosLocation = glGetUniformLocation(program, "vPos")
        glUseProgram(program)
        
        var linkStatus: GLint = 0
        glGetProgramiv(program, GLenum(GL_LINK_STATUS), &linkStatus)
        print("link status: \(linkStatus)")
        
        glfwGetCursorPos(window, &cursorX, &cursorY)
        print(String(format: "Cursor position: %+f %+f", cursorX, cursorY))
        
        glfwSetCursorPosCallback(window, cursorPositionCallback)
        glfwSetKeyCallback(window, keyCallback)
        
        while glfwWindowShouldClose(window) == GLFW_FALSE {
            glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
            
            if trackCursor {
                var windowWidth = 0 as Int32
                var windowHeight = 0 as Int32
                glfwGetWindowSize(window, &windowWidth, &windowHeight)
                
                var framebufferWidth = 0 as Int32
                var framebufferHeight = 0 as Int32
                glfwGetFramebufferSize(window, &framebufferWidth, &framebufferHeight)
                
                glViewport(0, 0, framebufferWidth, framebufferHeight)
                
                let scale = Float(framebufferWidth) / Float(windowWidth)
                
                var vertices = [[Float]](repeating: [0, 0], count: 4)
                vertices[0][0] = 0.5
                vertices[0][1] = Float(framebufferHeight) - floor(Float(cursorY) * scale) - 1 + 0.5
                vertices[1][0] = Float(framebufferWidth) + 0.5
                vertices[1][1] = Float(framebufferHeight) - floor(Float(cursorY) * scale) - 1 + 0.5
                vertices[2][0] = floor(Float(cursorX) * scale) + 0.5
                vertices[2][1] = 0.5
                vertices[3][0] = floor(Float(cursorY) * scale) + 0.5
                vertices[3][1] = Float(framebufferHeight) + 0.5
                
                let vertexData = vertices.reduce([], +)
                vertexData.withUnsafeBytes { data in
                    glBufferData(GLenum(GL_ARRAY_BUFFER),
                                 MemoryLayout<Float>.stride * vertexData.count,
                                 data.baseAddress,
                                 GLenum(GL_STREAM_DRAW))
                }
                
                let l = Float.zero
                let r = Float(framebufferWidth)
                let b = Float.zero
                let t = Float(framebufferHeight)
                let n = Float.zero
                let f = Float(1)
                let mvp: [Float] = [
                    2/(r-l), 0, 0, 0,
                    0, 2/(t-b), 0, 0,
                    0, 0, -2/(f-n), 0,
                    -(r+l)/(r-l), -(t+b)/(t-b), -(f+n)/(f-n), 1
                ]
                glUniformMatrix4fv(mvpLocation, 1, GLboolean(GL_FALSE), mvp)
                
                glDrawArrays(GLenum(GL_LINES), 0, 4)
            }
            
            glfwSwapBuffers(window)
            
            if animateCursor {
                let i = Int(glfwGetTime() * 30) % cursorFrameCount
                if currentFrame != starCursors[i] {
                    glfwSetCursor(window, starCursors[i])
                    currentFrame = starCursors[i]
                }
            } else {
                currentFrame = nil
            }
            
            if waitEvents {
                if animateCursor {
                    glfwWaitEventsTimeout(1 / 30)
                } else {
                    glfwWaitEvents()
                }
            } else {
                glfwPollEvents()
            }
        }
        
        glfwDestroyWindow(window)
        
        starCursors.forEach(glfwDestroyCursor)
        standardCursors.forEach(glfwDestroyCursor)
        
        glfwTerminate()
    }
}
