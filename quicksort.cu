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
void* recursive_helper(void* current_node);
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
void quick_sort(int N, int* input){

	node* rootptr;
	cudaMallocManaged(&rootptr, sizeof(node));
	node root = *rootptr;
	cudaMallocManaged(&root.array, sizeof(int)*N);
	cudaMemcpy(root.array,input,sizeof(int)*N,cudaMemcpyHostToDevice);
	root.numElements = N;
	cudaMallocManaged(&output,sizeof(int)*N);
	output_count = 0;
	
	pthread_t root_thread;
	void* temp_ptr = (void*)  &root;

	pthread_create(&root_thread, NULL, recursive_helper, (void*)temp_ptr );
	//pthread_create(&root_thread, NULL, recursive_helper
	
	//recursive_helper(&root);
	pthread_join(root_thread, NULL);
	cudaFree(rootptr);	
	cudaMemcpy(input,output,N*sizeof(int), cudaMemcpyDeviceToHost);
	cudaFree(output);
}
cudaStream_t streams [5000];
void *recursive_helper(void* ptr){
	
	node* current_node = (node*) ptr;
	printf("%d total\n ", current_node->numElements);
	
	if( current_node->numElements == 1){
		output[output_count] = current_node->array[0];
		output_count++;
		//cudaFree(current_node->array);
		//cudaFree(current_node);
		printf("exiting insert\n");
		return NULL;
	}if( current_node->numElements == 0){
		//cudaFree(current_node->array);
       		//cudaFree(current_node);
		printf("exiting 0\n");
		return NULL;
	}
	
	while( 0 != cudaMallocManaged( &current_node->left, sizeof(node)));
	while( 0 != cudaMallocManaged( &current_node->right, sizeof(node)));
	
	while( 0 != cudaMallocManaged(&current_node->left->array, sizeof(int)*current_node->numElements));
	while( 0 != cudaMallocManaged(&current_node->right->array, sizeof(int)*current_node->numElements));
	
	
	current_node->left->numElements = 0;
	current_node->right->numElements = 0;
	int numBlocks = (current_node->numElements + 256 -1) / 256;
	printf("calling split\n");
	
	
	int streamID = __atomic_fetch_add(&stream_cnt, 1, __ATOMIC_SEQ_CST);
	cudaStreamCreate(&streams[streamID]);

	split<<<numBlocks,256, 0,streams[streamID]>>>(current_node->numElements, current_node->array, current_node->left->array, current_node->right->array, &current_node->left->numElements, &current_node->right->numElements);
	
	cudaStreamSynchronize(streams[streamID]);
	printf("done splitting\n");
	printf("%d right Elem\n", current_node->right->numElements);
	printf("%d left Elem\n", current_node->left->numElements);

	current_node->left->array[current_node->left->numElements] = current_node->array[0];
	current_node->left->numElements ++;

	pthread_t left_thread, right_thread;

	node* left = current_node->left;
	node* right = current_node->right;
	
	pthread_create(&left_thread, NULL, recursive_helper, (void*) left);
	//pthread_join(left_thread,NULL);
	pthread_create(&right_thread, NULL, recursive_helper, (void*) right);
	
	//recursive_helper( (void*) current_node->left);
	//recursive_helper( (void*) current_node->right);
	pthread_join(left_thread, NULL);
	pthread_join(right_thread, NULL);
	
	cudaFree(current_node->array);
	cudaFree(current_node);
	printf("thread exiting");
	return NULL;
}
