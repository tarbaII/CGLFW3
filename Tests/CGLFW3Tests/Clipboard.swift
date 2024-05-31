import XCTest
@testable import CGLFW3

#if os(macOS)
let modifier = GLFW_MOD_SUPER
#else
let modifier = GLFW_MOD_CONTROL
#endif

class ClipboardTests: XCTestCase {
    let errorCallback: GLFWerrorfun = { (_, description: UnsafePointer<CChar>?) -> Void in
        XCTFail("Error: \(description.map(String.init(cString:)) ?? "")")
    }
    
    let keyCallback: GLFWkeyfun = { (window, key, scancode, action, mods) in
        guard action == GLFW_PRESS else {
            return
        }
        
        switch key {
        case GLFW_KEY_ESCAPE:
            glfwSetWindowShouldClose(window, GLFW_TRUE)
        case GLFW_KEY_V:
            guard mods == modifier else {
                break
            }
            
            let string = glfwGetClipboardString(nil).flatMap(String.init(cString:))
            if let string {
                print("Clipboard contains \"\(string)\"")
            } else {
                print("Clipboard does not contain a string")
            }
        case GLFW_KEY_C:
            guard mods == modifier else {
                break
            }
            
            let string = "Hello GLFW World!"
            string.withCString { pointer in
                glfwSetClipboardString(nil, pointer)
            }
        default:
            break
        }
    }
    
    func testClipboard() {
        var window: OpaquePointer?
        
        glfwSetErrorCallback(errorCallback)
        
        guard glfwInit() == GLFW_TRUE else {
            XCTFail("Failed to initialize GLFW")
            exit(EXIT_FAILURE)
        }
        
        window = glfwCreateWindow(200, 200, "Clipboard Test", nil, nil)
        guard let window else {
            glfwTerminate()
            XCTFail("Failed to open GLFW window")
            exit(EXIT_FAILURE)
        }
        
        glfwMakeContextCurrent(window)
        glfwSwapInterval(1)
        
        glfwSetKeyCallback(window, keyCallback)
        
        glClearColor(0.5, 0.5, 0.5, 0)
        
        while glfwWindowShouldClose(window) == GLFW_FALSE {
            glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
            
            glfwSwapBuffers(window)
            glfwWaitEvents()
        }
        
        glfwTerminate()
    }
}
