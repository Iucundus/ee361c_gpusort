#include <stdio.h>
#include <stdlib.h>
#include "file_helper.h"

__global__ void split(int N, int* input, int* left, int* right);

struct node{

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
	int* input;
	int* left;
	int* right;

	cudaMallocManaged(&left, size*sizeof(int));
	cudaMallocManaged(&right, size*sizeof(int));
	cudaMallocManaged(&input, size*sizeof(int));
	split<<<1,1>>>(size, input, left, right);


	//Output array to file
	if(saveArray(outputFile, A, size) < 0) {
		printf("Error writing sorted array to %s\n", outputFile);
	}

	free(A);

	return 0;
}




__global__
void split(int N, int* input, int* left, int* right){
  int index = threadIdx.x;
  int stride = blockDim.x;

  __shared__ int leftcount;
  __shared__ int rightcount;

  int splitter = input[0];

  for (int i = index+1; i < N; i+= stride){
    if(input[i] > splitter){
      right[atomicAdd(&rightcount,1)] = input[i];
    }else{
      left[atomicAdd(&leftcount,1)] = input[i];
    }
  }
  __syncthreads();
  if(index == 0){
    left[atomicAdd(&leftcount,1)] = input[0];
  }

}
