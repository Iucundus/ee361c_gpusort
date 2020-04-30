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
void quick_sort(int N, int* input);

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
	quick_sort(size,A);


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
    if(index == 0) left[atomicAdd(&local_left_count,1)] = input[0];
  __syncthreads();
    *leftcount = local_left_count;
		*rightcount = local_right_count;

}


int* output;
int output_count;
void quick_sort(int N, int* input){

	node* rootptr;
	cudaMallocManaged(&rootptr, sizeof(node));
	node root = *rootptr;
	cudaMallocManaged(&root.array, sizeof(int)*N);
	cudaMemcpy(root.array,input,sizeof(int)*N,cudaMemcpyHostToDevice);
	root.numElements = N;
	cudaMallocManaged(&output,sizeof(int)*N);
	output_count = 0;
	recursive_helper(&root);
	cudaMemcpy(input,output,N*sizeof(int), cudaMemcpyDeviceToHost);
	cudaFree(output);
}

void recursive_helper(node* current_node){
	//printf("%d total ",current_node->numElements);

	//printf("%d splitter ",current_node->array[0]);
	if(current_node->numElements == 1){
		output[output_count] = current_node->array[0];
		output_count++;
		cudaFree(current_node->array);
		cudaFree(current_node);
		return;
	}if(current_node->numElements == 0){
	       cudaFree(current_node->array);
       	cudaFree(current_node);
		return;
	}
	cudaMallocManaged(&current_node->left,sizeof(node));
	cudaMallocManaged(&current_node->right,sizeof(node));

	cudaMallocManaged(&current_node->left->array, sizeof(int)*current_node->numElements);
	cudaMallocManaged(&current_node->right->array, sizeof(int)*current_node->numElements);
	//printf("%d", current_node->left->array[0]);


	split<<<1,256>>>(current_node->numElements, current_node->array, current_node->left->array, current_node->right->array, &current_node->left->numElements, &current_node->right->numElements);
	cudaDeviceSynchronize();
	recursive_helper(current_node->left);
	recursive_helper(current_node->right);
	cudaFree(current_node->array);
	cudaFree(current_node);

}
