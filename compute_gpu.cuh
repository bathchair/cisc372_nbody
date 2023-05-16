extern "C" void compute_gpu(vector3* hVel, vector3* hPos, double* mass);
__global__ void kernel(vector3** accels, vector3* hVel, vector3* hPos, double* mass);
__global__ void second_kernel(vector3** accels, vector3* hVel, vector3* hPos);
