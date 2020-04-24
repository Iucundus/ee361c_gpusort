#include <stdio.h>
#include <stdlib.h>
#include "file_helper.h"

__global__ void split(int N, int* input, int* left, int* right, int* leftcount, int* rightcount);

struct node{
	int* array;
	int numElements;
	node* left;
	node* right;
};
void recursive_helper(node* current_node);
int* quick_sort(int N, int* input);

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
	A = quick_sort(size,A);


	//Output array to file
	if(saveArray(outputFile, A, size) < 0) {
		printf("Error writing sorted array to %s\n", outputFile);
	}

	free(A);

	return 0;
}




__global__
void split(int N, int* input, int* left, int* right, int* leftcount, int* rightcount){
  int index = threadIdx.x;
  int stride = blockDim.x;

  __shared__ int local_left_count;
  __shared__ int local_right_count;
  local_left_count = 0;
  local_right_count = 0;
  __syncthreads();
  int splitter = input[0];

  for (int i = index+1; i < N; i+= stride){
    if(input[i] > splitter){
      right[atomicAdd(&local_right_count,1)] = input[i];
    }else{
      left[atomicAdd(&local_left_count,1)] = input[i];
    }
  }
  __syncthreads();
  if(index == 0){
    left[atomicAdd(&local_left_count,1)] = input[0];
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
	output = (int*)malloc(sizeof(int)*N);
	output_count = 0;
	recursive_helper(&root);
	return output;
}

void recursive_helper(node* the_node){
	node current_node = *the_node;
	printf("%d ",current_node.numElements);
	if(current_node.numElements < 2){
		output[output_count] = current_node.array[0];
		output_count++;
		return;
	}
	current_node.left = (node*)malloc(sizeof(node));
	current_node.right = (node*)malloc(sizeof(node));
	node left_node = *current_node.left;
	node right_node = *current_node.right;
	cudaMallocManaged(&left_node.array, sizeof(int)*current_node.numElements);
	cudaMallocManaged(&right_node.array, sizeof(int)*current_node.numElements);
	//TODO add break condition
	

	split<<<1,1>>>(current_node.numElements, current_node.array, left_node.array, right_node.array, &left_node.numElements, &right_node.numElements);
	cudaDeviceSynchronize();
	printf("%d left",left_node.numElements);
	printf("%d right",right_node.numElements);
	recursive_helper(current_node.left);
	recursive_helper(current_node.right);

}
