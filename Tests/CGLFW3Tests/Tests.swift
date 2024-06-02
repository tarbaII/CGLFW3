import XCTest
@testable import CGLFW3
#if os(macOS)
import Cocoa
import GLKit
#endif

class Tests: XCTestCase {

    func testInit() throws {
        XCTAssertEqual(glfwInit(), GLFW_TRUE)
        
        glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4)
        glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 1)
        
        glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE)
        glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GLFW_TRUE)
        
        XCTAssertEqual(glfwGetError(nil), GLFW_NO_ERROR)
        
        let window = glfwCreateWindow(400, 300, "CGLFW3 Testing", nil, nil)
        XCTAssertEqual(glfwGetError(nil), GLFW_NO_ERROR)
        XCTAssertNotNil(window)
        
        glfwMakeContextCurrent(window)
        XCTAssertEqual(glfwGetError(nil), GLFW_NO_ERROR)
        
        XCTAssertNotNil(window)
        glfwPollEvents()
        glfwSwapBuffers(window)
        
        XCTAssertEqual(glfwGetError(nil), GLFW_NO_ERROR)
        glfwTerminate()
    }

    func testBufferSwapPerformance() throws {
        XCTAssertEqual(glfwInit(), GLFW_TRUE)
        
        glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4)
        glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 1)
        
        glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE)
        glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GLFW_TRUE)
        
        XCTAssertEqual(glfwGetError(nil), GLFW_NO_ERROR)
        
        let window = glfwCreateWindow(400, 300, "CGLFW3 Testing", nil, nil)
        XCTAssertEqual(glfwGetError(nil), GLFW_NO_ERROR)
        XCTAssertNotNil(window)
        
        glfwMakeContextCurrent(window)
        XCTAssertEqual(glfwGetError(nil), GLFW_NO_ERROR)
        
        #if os(macOS)
        let cocoaWindow = glfwGetCocoaWindow(window)
        
        
        let context = glfwGetNSGLContext(window) as? NSOpenGLContext
        XCTAssertNotNil(context)
        print(context!)
        #endif
        
        glfwSwapInterval(0)
        
        glfwSwapBuffers(window)
        glfwPollEvents()
        
        var frames = 0
        self.measure {
            while frames < 600 {
                glfwSwapBuffers(window)
                glfwPollEvents()
                frames += 1
            }
        }
        
        glfwTerminate()
    }

}
