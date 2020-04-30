#include <stdio.h>
#include <stdlib.h>
#include "file_helper.h"
#include <pthread.h>
__global__ void split(int N, int* input, int* left, int* right, int* leftcount, int* rightcount);


struct node{
	int* array;
	int numElements;
	node* left;
	node* right;
};

struct node2{
	int* array;
	int numElements;
	int before;
};

void* recursive_helper(void* current_node);
void* recursive_helper2(void* current_node);
void quick_sort(int N, int* input);
void quick_sort2(int N, int* input);

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
	quick_sort2(size,A);


	//Output array to file
	if(saveArray(outputFile, A, size) < 0) {
		printf("Error writing sorted array to %s\n", outputFile);
	}

	free(A);

	return 0;
}


__global__
void split(int N, int* input, int* left, int* right, int* leftcount, int* rightcount){
  int index = blockIdx.x * blockDim.x + threadIdx.x;
  int stride = blockDim.x * gridDim.x;
  //*leftcount = 0;
  //*rightcount = 0;
  __syncthreads();
  int splitter = input[0];
  for (int i = index+1; i < N; i+= stride){
    if(input[i] > splitter){
      right[atomicAdd(rightcount,1)] = input[i];
    }else{
      left[atomicAdd(leftcount,1)] = input[i];
    }
  }
    //*leftcount = local_left_count;
    //		*rightcount = local_right_count;

}


int* output;
int output_count;
int stream_cnt;
cudaStream_t streams [50000];
	
void quick_sort2(int N, int* input){
	node2* rootptr;
	
	cudaMallocManaged(&rootptr,sizeof(node2));
	node2 root = *rootptr;
	cudaMallocManaged(&rootptr->array, sizeof(int)*N);
	cudaMemcpy(rootptr->array,input,sizeof(int)*N,cudaMemcpyHostToDevice);
	rootptr->numElements = N;
	cudaMallocManaged(&output,sizeof(int)*N);
	recursive_helper2(&rootptr);
	cudaMemcpy(input,output,N*sizeof(int),cudaMemcpyDeviceToHost);
	
	cudaFree(output);
}

void* recursive_helper2(void* ptr){
	
	node2* current_node = *((node2**)ptr);
			
	if(((node2*)current_node)->numElements == 1){
		output[((node2*)current_node)->before] = ((node2*)current_node)->array[0];
		cudaFree(((node2*)current_node)->array);
		cudaFree(current_node);
		return NULL;
	}if(((node2*)current_node)->numElements == 0){
		cudaFree(((node2*)current_node)->array);
		cudaFree(current_node);
		return NULL;
	}
	node2* left;
	node2* right;

	while(cudaMallocManaged(&left, sizeof(node2)));
	while(cudaMallocManaged(&left->array, sizeof(int)*(((node2*)current_node)->numElements)));
	while(cudaMallocManaged(&right, sizeof(node2)));
	while(cudaMallocManaged(&right->array, sizeof(int)*(((node2*)current_node)->numElements)));

	int numBlocks = (((node2*)current_node)->numElements + 256 - 1) /256;
	
	int streamID = __atomic_fetch_add(&stream_cnt, 1, __ATOMIC_SEQ_CST);
	cudaStreamCreate(&streams[streamID]);
	
	split<<<1, 256, 0, streams[streamID]>>>(((node2*)current_node)->numElements, ((node2*)current_node)->array, left->array, right->array, &left->numElements, &right->numElements);
	cudaStreamSynchronize(streams[streamID]);
	
	left->array[left->numElements] = ((node2*)current_node)->array[0];
	left->numElements ++;
	
	left->before = ((node2*)current_node)->before;
	right->before = ((node2*)current_node)->before + left->numElements;

	pthread_t left_thread, right_thread;

	cudaDeviceSynchronize();
	cudaFree(((node2*)current_node)->array);
	cudaFree(((node2*)current_node));


	pthread_create(&left_thread, NULL, recursive_helper2, (void*) &left);
//	pthread_join(left_thread,NULL);
	pthread_create(&right_thread, NULL, recursive_helper2, (void*) &right);

	pthread_join(left_thread,NULL);
	pthread_join(right_thread,NULL);
	

	return NULL;

}
