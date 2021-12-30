# Metal
I created this repository for learning about Apple's Metal API. I am more interested in the parallel computing functionality than in the graphics programming capabilities. The main code is derived from [this video I found from 2etime](https://www.youtube.com/watch?v=VQK28rRK6OU&list=PLEXt1-oJUa4AMDyQlXRMGnBcMzZQvnAAg), checkout his channel and [github repo about Metal](https://github.com/twohyjr/Metal-Game-Engine-Tutorial) for more information about Apple's Metal API.
You can find more documentation about the Metal API in [Apple's documentation page](https://developer.apple.com/documentation/metal/).

# Shader functions
The original code taken from 2etime's repo had a shader function for computing the sum of two arrays. I modified the code slightly to do a comparison of the performance between a shader function and a Metal Performance Shaders API call. Metal uses the Metal Shading Language (MSL) to code the shader functions that will run on the GPU. See the Metal Shadig Language Specification [documentation](https://developer.apple.com/metal/Metal-Shading-Language-Specification.pdf) for more information.

# Metal Performance Shaders
Within the Metal API is a framework with a collection of optimized kernel functions, this framework is called [Metal Performance Shaders](https://developer.apple.com/documentation/metalperformanceshaders) (MPS). I used MPSMatrixSum to compare with the shader code for suming two arrays.

# Parallel execution on the CPU
Just for fun and reference, I added a function to execute the sum of the arrays in parallel but in the CPU. The original code from the repo already had the serial code to execute the sum of the arrays.

# Preliminary results
My hardware specs are:
- MacBook Pro 14"
- M1 Max SoC
- 32 GB Unified Memory
- 24 Built-in GPU cores
- 10 CPU cores (8 performance and 2 efficiency)

---

With that setup, I have been getting the following results:

| Compute unit          |  Execution time (seconds)  |
| --------------------- | :------------------------: |
| CPU (serial)          |  0.99666                   |
| CPU (parallel)        |  0.32256                   |
| GPU (MPS)             |  0.01724                   |
| GPU (MSL)             |  0.01319                   |


# Analysis of the results
There are many factors that affect the quality and application of the results. For example:
- I am using a timer to measure execution time. Even though Metal has
built-in functions to measure the execution time of the encoded command within the GPU, I am not using it because I want to account for the time it takes to create the buffers and encode the commands.
- The shaders kernel funciton seems to run a little faster than the MPS call. But, as you can see [here](https://developer.apple.com/documentation/metalperformanceshaders/mpsmatrixsum) MPSMatrixSum can take n number of matrices to perform the sum. So a good exercise to compare apples to apples would be to create a shader function in MSL that can take a list of arrays to perform their sum.
- With the given results, I see the benefits of having built-in kernels in MPS ready to perform the intended work (less time coding) versus creating you own functions in MSL. In the case where performance is critical, MPS can be used as a baseline for a Proof of Concept that can be later optimized into a custom shader function in MSL.
