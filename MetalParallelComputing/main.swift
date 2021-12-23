//
//  main.swift
//  MetalParallelComputing
//
//  Created by Jose Leon on 12/23/21.
//

import MetalKit
import MetalPerformanceShaders

//let count: Int = 90000000
let count: Int = 3000000

//Reference to the GPU we want to use
guard let device = MTLCreateSystemDefaultDevice() else {
    fatalError("Error accessing the system's GPU.")
}

func computeWay(arr1: [Float], arr2: [Float]) {
    
    print()
    print("GPU Way")
    
    // Begin the process
    let startTime = CFAbsoluteTimeGetCurrent()

    guard //A FIFO queue for sending commands to the GPU
          let commandQueue = device.makeCommandQueue(),
          //Create a command buffer to be sent to the command queue
          let commandBuffer = commandQueue.makeCommandBuffer(),
          // Create an encoder to set vaulues on the compute function
          let commandEncoder = commandBuffer.makeComputeCommandEncoder(),
          //Grab our GPU shader function
          let gpuFuncitonLibrary = device.makeDefaultLibrary(),
          let additionGPUFunction = gpuFuncitonLibrary.makeFunction(name: "addition_compute_function") else {
              fatalError("Error unwrapping optionals in funciton computeWay")
          }

    var additionComputePipelineState: MTLComputePipelineState!
    do {
        additionComputePipelineState = try device.makeComputePipelineState(function: additionGPUFunction)
    } catch {
      print(error)
    }

    // Create the buffers to be sent to the gpu from our arrays
    let arr1Buff = device.makeBuffer(bytes: arr1,
                                      length: MemoryLayout<Float>.size * count,
                                      options: .storageModeShared)

    let arr2Buff = device.makeBuffer(bytes: arr2,
                                      length: MemoryLayout<Float>.size * count,
                                      options: .storageModeShared)

    let resultBuff = device.makeBuffer(length: MemoryLayout<Float>.size * count,
                                        options: .storageModeShared)

    commandEncoder.setComputePipelineState(additionComputePipelineState)

    // Set the parameters of our gpu function
    commandEncoder.setBuffer(arr1Buff, offset: 0, index: 0)
    commandEncoder.setBuffer(arr2Buff, offset: 0, index: 1)
    commandEncoder.setBuffer(resultBuff, offset: 0, index: 2)

    // Figure out how many threads we need to use for our operation
    let threadsPerGrid = MTLSize(width: count, height: 1, depth: 1)
    let maxThreadsPerThreadgroup = additionComputePipelineState.maxTotalThreadsPerThreadgroup // 1024
    let threadsPerThreadgroup = MTLSize(width: maxThreadsPerThreadgroup, height: 1, depth: 1)
    commandEncoder.dispatchThreads(threadsPerGrid,
                                    threadsPerThreadgroup: threadsPerThreadgroup)

    // Tell the encoder that it is done encoding.  Now we can send this off to the gpu.
    commandEncoder.endEncoding()

    // Push this command to the command queue for processing
    commandBuffer.commit()

    // Wait until the gpu function completes before working with any of the data
    commandBuffer.waitUntilCompleted()

    // Get the pointer to the beginning of our data
    var resultBufferPointer = resultBuff?.contents().bindMemory(to: Float.self,
                                                                capacity: MemoryLayout<Float>.size * count)

    // Print out all of our new added together array information
    for i in 0..<3 {
        print("\(arr1[i]) + \(arr2[i]) = \(Float(resultBufferPointer!.pointee) as Any)")
        resultBufferPointer = resultBufferPointer?.advanced(by: 1)
    }
    
    // Print out the elapsed time
    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
    print("Time elapsed \(String(format: "%.05f", timeElapsed)) seconds")
    print()
}

func basicForLoopWay(arr1: [Float], arr2: [Float]) {
    print("CPU Way")
    
    // Begin the process
    let startTime = CFAbsoluteTimeGetCurrent()
    var result = [Float].init(repeating: 0.0, count: count)

    // Process our additions of the arrays together
    for i in 0..<count {
        result[i] = arr1[i] + arr2[i]
    }

    // Print out the results
    for i in 0..<3 {
        print("\(arr1[i]) + \(arr2[i]) = \(result[i])")
    }

    // Print out the elapsed time
    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
    print("Time elapsed \(String(format: "%.05f", timeElapsed)) seconds")

    print()
}


func parallelForLoopWay(arr1: [Float], arr2: [Float]) {
    print("Parallel CPU Way")
    
    var lock = os_unfair_lock_s()
    var result = [Float].init(repeating: 0.0, count: count)
    
    // Begin the process
    let startTime = CFAbsoluteTimeGetCurrent()
    
    DispatchQueue.concurrentPerform(iterations: count, execute: { index in
        
        let res = arr1[index] + arr2[index]
        os_unfair_lock_lock(&lock)
        result[index] = res
        os_unfair_lock_unlock(&lock)
    })

    // Print out the results
    for i in 0..<3 {
        print("\(arr1[i]) + \(arr2[i]) = \(result[i])")
    }

    // Print out the elapsed time
    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
    print("Time elapsed \(String(format: "%.05f", timeElapsed)) seconds")

    print()
}

//Compute using Metal Performance Shaders
func mpsWay(arr1: [Float], arr2: [Float]){
    
    print("MPS way")
    
    let startTime = CFAbsoluteTimeGetCurrent()
              
    guard // A queue for sending buffers with commands to the GPU
          let commandQueue = device.makeCommandQueue(),
          //A buffer to send commands to the GPU
          let commandBuffer = commandQueue.makeCommandBuffer() else {
              fatalError("Error unwrapping optionals in function mpsWay!")
          }
    
    //A MPS that calls a kernel to sum two matrices
    let matrixSumKermel = MPSMatrixSum(device: device,
                                       count: 2,
                                       rows: 1,
                                       columns: count,
                                       transpose: false)
    
    //Buffer A with matrix 1 values
    let bufferA = device.makeBuffer(bytes: arr1,
                                    length: MemoryLayout<Float>.stride * arr1.count,
                                    options: .storageModeShared)
    
    //Create matrix 1 descriptor
    let matrixADescA = MPSMatrixDescriptor(rows: 1,
                                          columns: count,
                                          rowBytes: MemoryLayout<Float>.stride * count,
                                          dataType: .float32)
    
    //Convert bufferA to MPSMatrix type
    let mpsMatrixA = MPSMatrix(buffer: bufferA!,
                               descriptor: matrixADescA)
    
    //Buffer B with matrix 2 values
    let bufferB = device.makeBuffer(bytes: arr2,
                                    length: MemoryLayout<Float>.stride * arr2.count,
                                    options: .storageModeShared)
    
    //Create matrix 2 descriptor
    let matrixDescB = MPSMatrixDescriptor(rows: 1,
                                          columns: count,
                                          rowBytes: MemoryLayout<Float>.stride * count,
                                          dataType: .float32)
    
    //Convert bufferB to MPSMatrix
    let mpsMatrixB = MPSMatrix(buffer: bufferB!,
                               descriptor: matrixDescB)
    
    let bufferC = device.makeBuffer(length: MemoryLayout<Float>.stride * count,
                                    options: .storageModeShared)
    
    let resultMatrixDesc = MPSMatrixDescriptor(rows: 1,
                                               columns: count,
                                               rowBytes: MemoryLayout<Float>.stride * count,
                                               dataType: .float32)
    
    let resultMatrix = MPSMatrix(buffer: bufferC!,
                                 descriptor: resultMatrixDesc)
    
    matrixSumKermel.encode(to: commandBuffer,
                           sourceMatrices: [mpsMatrixA, mpsMatrixB],
                           resultMatrix: resultMatrix,
                           scale: nil,
                           offsetVector: nil,
                           biasVector: nil,
                           start: 0)
    
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
    
/*
    var output = [Float]()
    
    let rawPointer = resultMatrix.data.contents()
    let typePointer = rawPointer.bindMemory(to: Float.self, capacity: count)
    let bufferPointer = UnsafeBufferPointer(start: typePointer, count: count)
    
    bufferPointer.map { value in
        output += [value]
    }
    
    // Print out the results
    for i in 0..<3 {
        print("\(arr1[i]) + \(arr2[i]) = \(output[i])")
    }
*/
    // Get the pointer to the beginning of our data
    var resultBufferPointer = bufferC!.contents().bindMemory(to: Float.self,
                                                                capacity: MemoryLayout<Float>.size * count)

    // Print out all of our new added together array information
    for i in 0..<3 {
        print("\(arr1[i]) + \(arr2[i]) = \(Float(resultBufferPointer.pointee) as Any)")
        resultBufferPointer = resultBufferPointer.advanced(by: 1)
    }
    
    // Print out the elapsed time
    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
    print("Time elapsed \(String(format: "%.05f", timeElapsed)) seconds")

    print()

}


// Helper function
func getRandomArray()->[Float] {
    var result = [Float].init(repeating: 0.0, count: count)
    for i in 0..<count {
        result[i] = Float(arc4random_uniform(10))
    }
    return result
}

// Create our random arrays
var array1 = getRandomArray()
var array2 = getRandomArray()

// Call our functions
print("Using count = \(count)")
computeWay(arr1: array1, arr2: array2)
parallelForLoopWay(arr1: array1, arr2: array2)
basicForLoopWay(arr1: array1, arr2: array2)
mpsWay(arr1: array1, arr2: array2)


