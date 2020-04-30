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
	
	//Output array to file
	if(saveArray(outputFile, A, size) < 0) {
		printf("Error writing sorted array to %s\n", outputFile);
	}
	
	free(A);
	
	return 0;
}