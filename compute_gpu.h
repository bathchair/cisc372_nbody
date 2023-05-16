void compute_gpu(vector3* hVel, vector3* hPos, double* mass);
void kernel(vector3** accels, vector3* hVel, vector3* hPos, double* mass);
void second_kernel(vector3** accels, vector3* hVel, vector3* hPos);
