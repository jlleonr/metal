
#include <metal_stdlib>
using namespace metal;

struct Vertex {
    simd_float4 position [[position]];
    simd_float4 color;
};

vertex float4 vertex_function(const device simd_float3 *vertices [[buffer(0)]],
                              uint vertexID [[vertex_id]]){
    
    Vertex output;
    simd_float3 currentVertex = vertices[vertexID];
    
    output.position = simd_float4(currentVertex.x, currentVertex.y, currentVertex.z, 1);
    
    
    return float4(vertices[vertexID], 1);
}

fragment half4 fragment_function(){
    return half4(1);
}
