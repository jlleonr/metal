
import MetalKit
import Cocoa

class MainView: MTKView {
    
    var commandQueue: MTLCommandQueue!
    var renderPipelineState: MTLRenderPipelineState!
    
    struct Vertex {
        var position: SIMD3<Float>
        var color: SIMD4<Float>
    }
    
    //Create vertices
    var vertices: [Vertex]!
    
    var vertexBuffer: MTLBuffer!
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        
        //Assign the GPU to the MTKView device property
        self.device = MTLCreateSystemDefaultDevice()
        self.clearColor = MTLClearColor(red: 0.2, green: 0.0, blue: 0.3, alpha: 1.0)
        self.colorPixelFormat = .bgra8Unorm
        self.commandQueue = device?.makeCommandQueue()
        
        createRenderPipelineState()
        createVertexPoints()
        createBuffers()
        
    }
    
    fileprivate func createVertexPoints(){
        func rads(forDegree d: Float)->Float32{
            return (Float.pi*d)/180
        }
        
        for i in 0...720 {
                let position : SIMD3<Float> = [cos(rads(forDegree: Float(Float(i)/2.0)))/2,
                                               sin(rads(forDegree: Float(Float(i)/2.0)))/2,
                                               0]
            
            vertices.append(Vertex(position: position, color: [0.5, 0.5, 0.5, 1]))
            
                if (i+1)%2 == 0 {
                    vertices.append(Vertex(position: [0.5, 0.5, 0.5], color: [1, 1, 1, 1])) //Origin, center of the screen space coordinates
                }
            }
    }
    
    func createBuffers(){
        vertexBuffer = device?.makeBuffer(bytes: vertices,
                                          length: MemoryLayout<Vertex>.stride * vertices.count,
                                          options: .storageModeShared)
    }
    
    func createRenderPipelineState(){
        let library = device?.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "vertex_function")
        let fragmentFunction = library?.makeFunction(name: "fragment_function")
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        renderPipelineDescriptor.vertexFunction = vertexFunction
        renderPipelineDescriptor.fragmentFunction = fragmentFunction
        
        do{
            renderPipelineState = try device?.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        }catch let error as NSError{
            print(error)
        }
        
    }
    
    override func draw(_ dirtyRect: NSRect) {
        
        guard let drawable = self.currentDrawable,
              let renderPassDescriptor = self.currentRenderPassDescriptor else {
                  return
              }
        
        let commandBuffer = commandQueue.makeCommandBuffer()
        let renderCommandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        renderCommandEncoder?.setRenderPipelineState(renderPipelineState)
        
        renderCommandEncoder?.setVertexBuffer(vertexBuffer,
                                              offset: 0,
                                              index: 0)
        
        renderCommandEncoder?.drawPrimitives(type: .triangleStrip,
                                             vertexStart: 0,
                                             vertexCount: vertices.count)
        
        renderCommandEncoder?.endEncoding()
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }

}
