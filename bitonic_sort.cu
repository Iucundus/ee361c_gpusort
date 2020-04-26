#include <stdio.h>
#include <stdlib.h>
#include "file_helper.h"

#define THREADS_PER_BLOCK 1024

__global__ void bitonic_sort(int* arrayIn, int* arrayOut, int arrayLen, int chunkSize){
	int idx = blockIdx.x * blockDim.x + threadIdx.x;
	if (idx < arrayLen) {
		int myValue = arrayIn[idx];
		int chunkStart = (idx / chunkSize) * chunkSize;
		int chunkMid = chunkStart + (chunkSize / 2);
		int partnerIndex = chunkSize - (idx - chunkStart) - 1 + chunkStart;
		if (partnerIndex < arrayLen) {
			int partnerValue = arrayIn[partnerIndex];
			int min = (myValue <= partnerValue) ? myValue:partnerValue;
			int max = (myValue > partnerValue) ? myValue:partnerValue;
			myValue = (idx < chunkMid) ? min:max;
		}
		arrayOut[idx] = myValue;
	}
}

__global__ void bitonic_merge(int* arrayIn, int* arrayOut, int arrayLen, int chunkSize){
	int idx = blockIdx.x * blockDim.x + threadIdx.x;
	if (idx < arrayLen) {
		int myValue = arrayIn[idx];
		int chunkStart = (idx / chunkSize) * chunkSize;
		int chunkMid = chunkStart + (chunkSize / 2);
		int partnerIndex = (((idx - chunkStart) + (chunkSize / 2)) % chunkSize) + chunkStart;
		if (partnerIndex < arrayLen) {
			int partnerValue = arrayIn[partnerIndex];
			int min = (myValue <= partnerValue) ? myValue:partnerValue;
			int max = (myValue > partnerValue) ? myValue:partnerValue;
			myValue = (idx < chunkMid) ? min:max;
		}
		arrayOut[idx] = myValue;
	}
}

int main(int argc, char* argv[]) {
	//Set default file name
	const char* inputFile = "inp.txt";
	const char* outputFile = "out.txt";
	//Overwrite file names
	if(argc >= 2)
		inputFile = argv[1];
	if(argc >= 3)
		outputFile = argv[2];
	
	//Read in input array
	int* A;
	int size = getArray(inputFile, &A);
	if(size < 0){
		printf("Error getting array from %s\n", inputFile);
		return -1;
	}
	
	//YOUR CODE HERE
	int *d_arrayIn, *d_arrayOut;
	cudaMalloc(&d_arrayIn, size * sizeof(int));
	cudaMalloc(&d_arrayOut, size * sizeof(int));
	cudaMemcpy(d_arrayIn, A, size * sizeof(int), cudaMemcpyHostToDevice);

	for(int sortSize = 2; (sortSize / 2) < size; sortSize = sortSize * 2) {
		//Sort
		bitonic_sort<<<(size + THREADS_PER_BLOCK - 1)/THREADS_PER_BLOCK,THREADS_PER_BLOCK>>>(d_arrayIn, d_arrayOut, size, sortSize);
		cudaDeviceSynchronize();
			
		int *d_temp = d_arrayOut;
		d_arrayOut = d_arrayIn;
		d_arrayIn = d_temp;
		
		
		//Merge
		for(int mergeSize = sortSize / 2; mergeSize > 1; mergeSize = mergeSize / 2){
			bitonic_merge<<<(size + THREADS_PER_BLOCK - 1)/THREADS_PER_BLOCK,THREADS_PER_BLOCK>>>(d_arrayIn, d_arrayOut, size, mergeSize);
			cudaDeviceSynchronize();
			
			int *d_temp = d_arrayOut;
			d_arrayOut = d_arrayIn;
			d_arrayIn = d_temp;
		}
	}
	
	cudaMemcpy(A, d_arrayIn, size * sizeof(int), cudaMemcpyDeviceToHost);
	cudaFree(d_arrayIn);
	cudaFree(d_arrayOut);
	
	//Output array to file
	if(saveArray(outputFile, A, size) < 0) {
		printf("Error writing sorted array to %s\n", outputFile);
	}
	
	free(A);
	
	return 0;
}