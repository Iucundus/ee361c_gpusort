#include <stdio.h>
#include <stdlib.h>
#include "file_helper.h"

__global__ void mergesort(int* src, int* dest, int sliceWidth, int size, int slices);
__device__ void merge(int* src, int* dest, int start, int mid, int end);
void swap(int * &a, int * &b);

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

	int* B = (int *)malloc(size*sizeof(int));

	int threadsPerBlock = 512;
	int blocksPerGrid =((size) + threadsPerBlock - 1) / threadsPerBlock;

	if(size > 1000){
		blocksPerGrid = ((1000) + threadsPerBlock - 1) / threadsPerBlock;
	}

	int *d_A;
	int *d_B;
	cudaMalloc((void **) &d_A, size*sizeof(int));
	cudaMalloc((void **) &d_B, size*sizeof(int));

	cudaMemcpy(d_A,A, size*sizeof(int), cudaMemcpyHostToDevice);

	printf("threads: %u\n",blocksPerGrid*threadsPerBlock);

	for(int sliceWidth = 2; sliceWidth < (size*2); sliceWidth = sliceWidth*2){
		int slices = size / ((blocksPerGrid*threadsPerBlock) * sliceWidth) + 1;
		mergesort<<<blocksPerGrid,threadsPerBlock>>>(d_A,d_B,sliceWidth, size, slices);
		swap(d_A,d_B);
	}

	cudaMemcpy(A, d_A, size*sizeof(int), cudaMemcpyDeviceToHost);

	
	//Output array to file
	if(saveArray(outputFile, A, size) < 0) {
		printf("Error writing sorted array to %s\n", outputFile);
	}
	
	free(A);
	free(B);
	cudaFree(d_A);
	cudaFree(d_B);
	
	return 0;
}

/*
 * Sets start, midpoint, and end of array for use in merge()
 */
__global__ void mergesort(int* src, int* dest, int sliceWidth, int size, int slices){
	int idx = blockDim.x * blockIdx.x + threadIdx.x;

	int start = idx*sliceWidth*slices;
	int mid;
	int end;


	for (int slice = 0; slice < slices; slice++) { 
        if (start >= size)
            break;
 
        mid = min(start + (sliceWidth/2), size);
        end = min(start + sliceWidth, size);
        merge(src,dest,start,mid,end);
        start += sliceWidth;
    }

	

}

/*
 * Merges two sorted halves of array into one sorted array
 */
__device__ void merge(int* src, int* dest, int start, int mid, int end){
	int frontIDX = start;
	int backIDX = mid;

	for(int mergeIDX = start; mergeIDX < end; mergeIDX++){
		if(((frontIDX < mid) && (src[frontIDX] < src[backIDX])) || ((frontIDX < mid) && (backIDX >= end))){ //frontIDX element is lower or back array has already been traversed
			dest[mergeIDX] = src[frontIDX];
			frontIDX++;
		}
		else{
			dest[mergeIDX] = src[backIDX];
			backIDX++;
		}
	}

}

/*
 * Swaps array pointers
 */

void swap(int * &a, int * &b){
	int *temp = a;
	a = b;
	b = temp;
}