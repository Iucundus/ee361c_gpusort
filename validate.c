#include <stdio.h>
#include <stdlib.h>
#include <limits.h>
#include "file_helper.h"

int cmpInt(const void * a, const void * b) {
   return ( *(int*)a - *(int*)b );
}

int main(int argc, char* argv[]) {
	//get arguments
	if(argc < 3) {
		printf("Argument error. Use form:\n\tvalidate_array test_file.txt output_file.txt");
		return -1;
	}
	
	//read arrays
	int* testArray;
	int testArraySize = getArray(argv[1], &testArray);
	if(testArraySize < 0) {
		printf("Error reading array from %s", argv[1]);
		return -1;
	}
	int* outputArray;
	int outputArraySize = getArray(argv[2], &outputArray);
	if(outputArraySize < 0) {
		printf("Error reading array from %s", argv[2]);
		return -1;
	}
	
	//Compare array sizes
	int size = 1;
	if(testArraySize != outputArraySize)
		size = 0;
	
	//Sort test array
	qsort(testArray, testArraySize, sizeof(int), cmpInt);
	
	//Compare arrays
	int sorted = 1;
	int incorrectSortIndex = -1;
	int previousValue = INT_MIN;
	int expected = 1;
	int incorrectValueIndex = -1;
	for(int i = 0; (i < testArraySize) && (i < outputArraySize) && (sorted || expected); i++) {
		if(sorted) {
			if(outputArray[i] >= previousValue) {
				previousValue = outputArray[i];
			} else {
				sorted = 0;
				incorrectSortIndex = i;
			}
		}
		if(expected) {
			if(outputArray[i] == testArray[i]) {
				
			} else {
				expected = 0;
				incorrectValueIndex = i;
			}
		}
	}
	
	//Print results
	if(size && sorted && expected) {
		printf("All test passed!\n");
	} else {
		if(!size)
			printf("Size test failed: expected %i but got %i\n", testArraySize, outputArraySize);
		if(!sorted)
			printf("Sort test failed: at index %i, expected value greater than %i but got %i\n", incorrectSortIndex, previousValue, outputArray[incorrectSortIndex]);
		if(!expected)
			printf("Comparison test failed: at index %i, expected %i but got %i\n", incorrectValueIndex, testArray[incorrectValueIndex], outputArray[incorrectValueIndex]); 
	}
	
	free(testArray);
	free(outputArray);
	
	return 0;
}