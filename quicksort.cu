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
cudaStream_t streams [50000];
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

	pthread_t left_thread, right_thread;

	node* left = current_node->left;
	node* right = current_node->right;
	
	pthread_create(&left_thread, NULL, recursive_helper, (void*) left);
	pthread_join(left_thread,NULL);
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
int done = 0;
int done_count;
void quick_sort2(int N, int* input){
	node2* rootptr;
	
	cudaMallocManaged(&rootptr,sizeof(node2));
	node2 root = *rootptr;
	cudaMallocManaged(&root.array, sizeof(int)*N);
	cudaMemcpy(root.array,input,sizeof(int)*N,cudaMemcpyHostToDevice);
	root.numElements = N;
	cudaMallocManaged(&output,sizeof(int)*N);
	done_count = N;
	recursive_helper2(&root);
	while(!done);
	cudaMemcpy(input,output,N*sizeof(int),cudaMemcpyDeviceToHost);
	
	cudaFree(output);
}

void* recursive_helper2(void* ptr){
	node2* current_node = (node2*) ptr;
	if(current_node->numElements == 1){
		output[current_node->before] = current_node->array[0];
		cudaFree(current_node->array);
		cudaFree(current_node);
		//if(current_node->before == done_count-2) done = 1;
		return NULL;
	}if(current_node->numElements == 0){
		cudaFree(current_node->array);
		cudaFree(current_node);
		return NULL;
	}
//	printf("%d\n", current_node->numElements);	
	node2* left;
	node2* right;

	while(cudaMallocManaged(&left, sizeof(node2)));
	while(cudaMallocManaged(&left->array, sizeof(int)*current_node->numElements));
	while(cudaMallocManaged(&right, sizeof(node2)));
	while(cudaMallocManaged(&right->array, sizeof(int)*current_node->numElements));

	int numBlocks = (current_node->numElements + 256 - 1) /256;
	
	int streamID = __atomic_fetch_add(&stream_cnt, 1, __ATOMIC_SEQ_CST);
	cudaStreamCreate(&streams[streamID]);
	
	split<<<1, 256, 0, streams[streamID]>>>(current_node->numElements, current_node->array, left->array, right->array, &left->numElements, &right->numElements);
	cudaStreamSynchronize(streams[streamID]);
	
	left->array[left->numElements] = current_node->array[0];
	left->numElements ++;

	left->before = current_node->before;
	right->before = current_node->before + left->numElements;

	pthread_t left_thread, right_thread;


	cudaFree(current_node->array);
	cudaFree(current_node);


	pthread_create(&left_thread, NULL, recursive_helper2, (void*) left);
//	pthread_join(left_thread,NULL);	
	pthread_create(&right_thread, NULL, recursive_helper2, (void*) right);

	pthread_join(left_thread,NULL);
	pthread_join(right_thread,NULL);
	
	//cudaFree(current_node->array);
	//cudaFree(current_node);
	
//	pthread_join(left_thread,NULL);
//	pthread_join(right_thread,NULL);

	return NULL;

}
