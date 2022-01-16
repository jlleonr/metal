
import MetalKit
import Cocoa

class MainView: MTKView {
    
    private var commandQueue: MTLCommandQueue!
    private var renderPipelineState: MTLRenderPipelineState!
    
    private struct Vertex {
        var position: SIMD3<Float>
        var color: SIMD4<Float>
    }
    
    //Vertices container
    private var vertices: [Vertex] = [Vertex]()
    
    private var vertexBuffer: MTLBuffer!
    
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
    
    
    /// Create enough vertices to form a circle
    fileprivate func createVertexPoints(){
        
        var col: SIMD4<Float>
        var origin_col: SIMD4<Float>
        var x, y: Float
        
        func rads(forDegree d: Float)->Float32{
            return (Float.pi*d)/180
        }
        
        //Form many triangles with a common origin
        // vertices = (n*360)/2
        for i in 0...720 {
            
            x = cos(rads(forDegree: Float(Float(i)/2.0)))/2
            y = sin(rads(forDegree: Float(Float(i)/2.0)))/2
            
            let pos : SIMD3<Float> = [x, y, 0]
                        
            if ( x >= 0 && y >= 0 ) {        //Paint quadrant I green
                
                col = [0, 1, 0, 1]
                origin_col = [0, 1, 0, 1]
                
            } else if ( x >= 0 && y <= 0 ) { //Paint quadrant II red
                
                col = [1, 0, 0, 1]
                origin_col = [1, 0, 0, 1]
                
            } else if ( x <= 0 && y <= 0 ) { //Paint quadrant III blue
                
                col = [0, 0, 1, 1]
                origin_col = [0, 0, 1, 1]
                
            } else {                         //Paint quadrant IV yellow
                
                col = [1, 1, 0, 1]
                origin_col = [1, 1, 0, 1]
                
            }
            
            vertices.append(Vertex(position: pos, color: col))
            
                if (i+1)%2 == 0 {
                    
                    //Origin, center of the screen space coordinates
                    vertices.append(Vertex(position: [0, 0, 0], color: origin_col))
                }
            }
    }
    
    
    /// Create a MTL buffer to store the vertices
    func createBuffers(){
        vertexBuffer = device?.makeBuffer(bytes: vertices,
                                          length: MemoryLayout<Vertex>.stride * vertices.count,
                                          options: .storageModeShared)
    }
    
    
    /// Configure and create the render pipeline state
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
