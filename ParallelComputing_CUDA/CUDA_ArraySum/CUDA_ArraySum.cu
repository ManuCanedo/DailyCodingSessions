﻿
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <iostream>
#include <memory>
#include <math.h>
#include <chrono>

// Timer class to benchmark the results
class Timer
{
public:
    Timer() : m_StartTimepoint(std::chrono::high_resolution_clock::now()) {}
    ~Timer() { Stop(); }

    void Stop()
    {
        const auto endTimepoint = std::chrono::high_resolution_clock::now();
        const auto start = std::chrono::time_point_cast<std::chrono::microseconds>(m_StartTimepoint).time_since_epoch().count();
        const auto end = std::chrono::time_point_cast<std::chrono::microseconds>(endTimepoint).time_since_epoch().count();
        const double ms = (end - start) * 0.001;
        std::cout << "Execution time: " << ms << "ms\n";
    }

private:
    const std::chrono::time_point<std::chrono::high_resolution_clock> m_StartTimepoint;
};

// CUDA add function
__global__
void addCUDA(int N, float* x, float* y)
{
    int i = threadIdx.x + blockDim.x * blockIdx.x;
    if (i < N) y[i] += x[i];
}

// Standard CPU add function
void addCPU(int N, float* x, float* y)
{
    for (int i = 0; i < N; i++)
        y[i] += x[i];
}

int main()
{
    int N = 1 << 20;

    // Standard CPU array sum
    float* x = new float[N], * y = new float[N];

    for (int i = 0; i < N; ++i)
    {
        x[i] = 1.0f;
        y[i] = 2.0f;
    }

    {
        Timer CPU;
        addCPU(N, x, y);
    }

    // Free Memory
    delete[] x;
    delete[] y;
    x = y = nullptr;

    // CUDA array sum
    // Allocate Unified Memory
    cudaMallocManaged(&x, N * sizeof(float));
    cudaMallocManaged(&y, N * sizeof(float));

    // Initialize x and y arrays
    for (int i = 0; i < N; ++i)
    {
        x[i] = 1.0f;
        y[i] = 2.0f;
    }

    {
        Timer CUDA;
        // Run kernel on 1M elements on the CPU
        addCUDA <<<N/1024, 1024>>> (N, x, y);
        // Wait for GPU to finish before assessing the result
        cudaDeviceSynchronize();
    }

    for (int i = 0; i < N; ++i)
        if (y[i] != 3)
            std::cout << "Oops!";

    // Free Memory
    cudaFree(x);
    cudaFree(y);

    return 0;
}