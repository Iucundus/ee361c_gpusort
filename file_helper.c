#include <stdio.h>
#include <stdlib.h>

typedef struct linked_list_stuct{
	int value;
	struct linked_list_stuct* next;
} linked_list_t;

int getArray(const char* file, int** array) {
	//open file
	FILE *fp = fopen( file, "r" );
	if (fp == NULL)
		return -1; //error opening file
	
	//read file and add inputs to linked list
	linked_list_t head_dummy = {-1, NULL};
	linked_list_t* head = &head_dummy;
	linked_list_t* tail = head;
	int input;
	int inputSize = 0;
	while(fscanf(fp, "%d", &input)==1 || fscanf(fp, "%*s%d", &input)==1) {
		linked_list_t* newNode = (linked_list_t *) malloc(sizeof(linked_list_t));
		newNode->value = input;
		newNode->next = NULL;
		tail->next = newNode;
		tail = newNode;
		inputSize++;
	}
	
	//close file
	fclose(fp);
	
	//convert linked list to array
	int* newArray = (int *) malloc(inputSize * sizeof(int));
	linked_list_t* nextNode = head->next;
	for(int i = 0; (i < inputSize) && (nextNode != NULL); i++) {
		newArray[i] = nextNode->value;
		linked_list_t* previousNode = nextNode;
		nextNode = previousNode->next;
		free(previousNode);
	}
	
	//return values
	*array = newArray;
	return inputSize;
}

int saveArray(const char* file, int* array, int arraySize) {
	//Open or create file
	FILE *fp = fopen(file, "w+");
		if(fp == NULL)
			return -1; //error creating file
	
	//Output array to file
	for (int i = 0; i < arraySize; i++) {
		fprintf(fp, "%i", array[i]);
		if(i < (arraySize - 1))
			fprintf(fp, ", ");
	}
	
	//close file
	fclose(fp);
	
	//return
	return 0;
}
