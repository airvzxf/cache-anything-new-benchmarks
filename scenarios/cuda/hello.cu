// Compiled only: hosted runners have no GPU.
#include <cstdio>

__global__ void add(const float* a, const float* b, float* c, int n) {
  const int i = blockIdx.x * blockDim.x + threadIdx.x;
  if (i < n) c[i] = a[i] + b[i];
}

int main() {
  constexpr int n = 1 << 20;
  float *a, *b, *c;
  cudaMallocManaged(&a, n * sizeof(float));
  cudaMallocManaged(&b, n * sizeof(float));
  cudaMallocManaged(&c, n * sizeof(float));
  add<<<(n + 255) / 256, 256>>>(a, b, c, n);
  cudaDeviceSynchronize();
  std::printf("%f\n", c[0]);
  cudaFree(a);
  cudaFree(b);
  cudaFree(c);
}
