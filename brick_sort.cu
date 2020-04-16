#include <stdio.h>
#include <stdlib.h>
#include "file_helper.h"

__global__ void brickSort(int* array, int arrayLen, int p) {
	int idx = blockIdx.x * blockDim.x + threadIdx.x;
	if (idx >= arrayLen - 1)
		return;
	if ((p % 2 == 0) && (idx % 2 == 1))
		return;
	if ((p % 2 == 1) && (idx % 2 == 0))
		return;
	if (array[idx] > array[idx + 1]) {
		int tmp = array[idx + 1];
		array[idx + 1] = array[idx];
		array[idx] = tmp;
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
	int* d_array;
	cudaMalloc(&d_array, size * sizeof(int));
	cudaMemcpy(d_array, A, size * sizeof(int), cudaMemcpyHostToDevice);

	// To get the first element, first pass number is 0
	// Last pass number is probably (size - 2)
	// By zero-indexing, that means (size - 1) passes
	// If the largest element is in array[0], that gives (size - 1) passes to move it (size - 1) places to array[size - 1]
	for (int i = 0; i < size - 1; i++) {
		brickSort<<<(size + 1023)/1024, 1024>>>(d_array, size, i);
		cudaDeviceSynchronize();
	}

	cudaMemcpy(A, d_array, size * sizeof(int), cudaMemcpyDeviceToHost);
	cudaFree(d_array);
	
	//Output array to file
	if(saveArray(outputFile, A, size) < 0) {
		printf("Error writing sorted array to %s\n", outputFile);
	}
	
	free(A);
	
	return 0;
}
