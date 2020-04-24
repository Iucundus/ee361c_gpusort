#include <stdio.h>
#include <stdlib.h>
#include "file_helper.h"

__global__ void split(int N, int* input, int* left, int* right);

struct node{
	int* array;
	int numElements;
	node* left;
	node* right;
};

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



	//Output array to file
	if(saveArray(outputFile, A, size) < 0) {
		printf("Error writing sorted array to %s\n", outputFile);
	}

	free(A);

	return 0;
}




__global__
void split(int N, int* input, int* left, int* right, int* leftcount int* rightcount){
  int index = threadIdx.x;
  int stride = blockDim.x;

  __shared__ int local_left_count;
  __shared__ int local_right_count;

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
		*leftcount = local_left_count;
		*rightcount = local_right_count;
  }

}


int* output;
int output_count;
int* quick_sort(int N, int* input){
	node root;
	root.array = input;
	root.numElements = N;
	output = malloc(sizeof(int)*N);
	output_count = 0;
	recursive_helper(&root);
}

void recursive_helper(node* current_node){

	if(current_node.numElements < 2){
		output[output_count] = current_node.array[0];
		output_count++;
		return;
	}
	current_node.left = malloc(sizeof(node));
	current_node.right = malloc(sizeof(node));

	cudaMallocManaged(&current_node.left.array, sizeof(int)*current_node.numElements);
	cudaMallocManaged(&current_node.right.array, sizeof(int)*current_node.numElements);
	//TODO add break condition
	

	split<<<1,1>>>(size, current_node.array, current_node.left.array, current_node.right.array, &current_node.left.numElements, &current_node.right.numElements);

	recursive_helper(current_node.left);
	recursive_helper(current_node.right);

}
