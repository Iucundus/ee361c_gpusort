#include <stdio.h>
#include <stdlib.h>
#include "file_helper.h"

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


	int* x;
  int* buck0;
  int* buck1;
  int* out;
  int* prefix1;
  int* prefix2;

  cudaMallocManaged(&x, size*sizeof(int));
  cudaMallocManaged(&out, size*sizeof(int));
  cudaMallocManaged(&buck0, size*sizeof(int));
  cudaMallocManaged(&buck1, size*sizeof(int));
  cudaMallocManaged(&prefix1, size*sizeof(int));
  cudaMallocManaged(&prefix2, size*sizeof(int));

  cudaMemcpy(x,A,size*sizeof(int), cudaMemcpyHostToDevice);

  radix_sort<<<1,256>>>(size, x, out, buck0, buck1, prefix1, prefix2);

  cudaDeviceSynchronize();

  cudaMemcpy(A,out,size*sizeof(int),cudaMemcpyDeviceToHost);

  cudaFree(x);
  cudaFree(buck0);
  cudaFree(buck1);
  cudaFree(prefix1);
  cudaFree(prefix2);
  cudaFree(out);




	//Output array to file
	if(saveArray(outputFile, A, size) < 0) {
		printf("Error writing sorted array to %s\n", outputFile);
	}

	free(A);

	return 0;
}






__global__
void radix_sort(int N, int* x, int* out, int* buck0, int* buck1, int* prefix1, int* prefix2){


    int index = threadIdx.x;
    int stride = blockDim.x;

    int mask = 1;
    int even = 1;

    int* temp;
    int* p1;
    int* p2;
    p1 = prefix1;
    p2 = prefix2;

    __shared__ int buck0count;
    __shared__ int buck1count;

    buck0count = 0;
    buck1count = 0;

    for(int count = 0; count < 32; count++){

      for(int i = index; i < N; i += stride){
        if(x[i] & mask){
          p1[i] = 1;
        }else{
          p1[i] = 0;
        }
      }

      __syncthreads();

      for (int offset = 1; offset < N; offset *= 2){

        for(int i = index; i < N; i += stride){
          if(i>=offset){

	    p2[i] = p1[i] + p1[i-offset];
	  }else{
	    p2[i] = p1[i];
	  }
        }
        temp = p1;
        p1 = p2;
        p2 = temp;

        __syncthreads();
      }

      buck0count = 0;
      buck1count = 0;
      __syncthreads();

      for(int i = index; i < N; i += stride){
        if(x[i] & mask){
          buck1[p1[i]-1] = x[i];
          atomicAdd(&buck1count,1);
        }else{
          buck0[i-p1[i]] = x[i];
          atomicAdd(&buck0count,1);
        }
      }
      __syncthreads();
      int i = 0;
      for(i = index; i < buck0count; i+= stride){
        x[i] = buck0[i];
      }
      __syncthreads();
      for(int j = index; j < buck1count; j+= stride){
        x[j+buck0count] = buck1[j];
      }

      ////////////

      mask <<= 1;
      __syncthreads();
    }

}
