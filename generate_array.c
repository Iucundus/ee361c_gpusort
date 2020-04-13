#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include <time.h>
#include "file_helper.h"

int main(int argc, char* argv[]) {
	//set defaults
	int arraySize = 10000;
	const char* fileName = "inp.txt";
	int maxValue = INT_MAX;
	
	//allow default overwrite
	if(argc >= 2)
		arraySize = atoi(argv[1]);
	if(argc >= 3)
		fileName = argv[2];
	if(argc >= 4)
		maxValue = atoi(argv[3]);
	
	//check values
	if(arraySize < 1) {
		printf("%i is an invalid array size\n", arraySize);
		return -1;
	}
	if(maxValue < 1) {
		printf("%i is an invalid max value\n", maxValue);
		return -1;
	}
	
	//generate array
	int* array = malloc(arraySize * sizeof(int));
	srand(time(0));
	for(int i = 0; i < arraySize; i++) {
		array[i] = rand() % maxValue;
	}
	
	//save array
	if(saveArray(fileName, array, arraySize) < 0) {
		printf("Error saving to %s\n", fileName);
		return -1;
	}
	printf("New array saved to %s\n", fileName);
	
	free(array);
	return 0;
}