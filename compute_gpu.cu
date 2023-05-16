#include <stdlib.h>
#include <math.h>
#include "vector.h"
#include "config.h"
#include "compute_gpu.cuh"

extern "C"
void compute_gpu(vector3* hVel, vector3* hPos, double* mass){
	// parallelize two dimensional array
	vector3* values;
	vector3** accels;
	cudaMallocManaged(&values, sizeof(vector3)*NUMENTITIES*NUMENTITIES);
	cudaMallocManaged(&accels, sizeof(vector3*)*NUMENTITIES);
	for (int i=0; i<NUMENTITIES; i++) {
		accels[i] = &values[i*NUMENTITIES];
	}

	// thread calling kernel
	vector3* velTemp;
	vector3* posTemp;
	double* massTemp;
	dim3 dimBlock(10, 10);
	dim3 dimGrid(NUMENTITIES / dimBlock.x, NUMENTITIES / dimBlock.y);

	cudaMallocManaged(&velTemp, sizeof(vector3)*NUMENTITIES);
	cudaMallocManaged(&posTemp, sizeof(vector3)*NUMENTITIES);
	cudaMallocManaged(&massTemp, sizeof(double)*NUMENTITIES);

	cudaMemcpy(velTemp, hVel, sizeof(hVel), cudaMemcpyHostToDevice);
	cudaMemcpy(posTemp, hPos, sizeof(hPos), cudaMemcpyHostToDevice);
	cudaMemcpy(massTemp, mass, sizeof(mass), cudaMemcpyHostToDevice);

	kernel<<<dimGrid, dimBlock>>>(accels, velTemp, posTemp, massTemp);
	second_kernel<<<dimGrid, dimBlock>>>(accels, velTemp, posTemp);

	cudaMemcpy(hVel, velTemp, sizeof(velTemp), cudaMemcpyDeviceToHost);
	cudaMemcpy(hPos, posTemp, sizeof(posTemp), cudaMemcpyDeviceToHost);
	cudaMemcpy(mass, massTemp, sizeof(massTemp), cudaMemcpyDeviceToHost);
	cudaDeviceSynchronize();

	// freeing memory
	cudaFree(velTemp);
	cudaFree(posTemp);
	cudaFree(massTemp);
	cudaFree(values);
	cudaFree(accels);
}


__global__
void kernel(vector3** accels, vector3* hVel, vector3* hPos, double* mass){
	int i = blockIdx.x * blockDim.x + threadIdx.x;
	int j = blockIdx.y * blockDim.y * threadIdx.y;

	if (i == j) {
		FILL_VECTOR(accels[i][j],0,0,0);
	} else {
		vector3 distance;
		for (int k=0; k<3; k++){
			distance[k] = hPos[i][k]-hPos[j][k];
		}
		double magnitude_sq = distance[0]*distance[0]+distance[1]+distance[2]*distance[2];
		double magnitude = sqrt(magnitude_sq);
		double accelmag = 1 * GRAV_CONSTANT * mass[j]/magnitude_sq;
		FILL_VECTOR(accels[i][j], accelmag * distance[0]/magnitude, accelmag*distance[1]/magnitude, accelmag*distance[2]/magnitude);
	}
}

__global__
void second_kernel(vector3** accels, vector3* hVel, vector3* hPos) {
	int i = blockIdx.x * blockDim.x + threadIdx.x;
	int j = blockIdx.y * blockDim.y * threadIdx.y;
	vector3 accel_sum = {0, 0, 0};
	int k;

	for (k=0;k<3;k++){
		accel_sum[k]+=accels[i][j][k];
	}

	for (k=0; k<3; k++){
		hVel[i][j]+=accel_sum[k]*INTERVAL;
		hPos[i][j]=hVel[i][k]*INTERVAL;
	}
}	
