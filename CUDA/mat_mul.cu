#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "cuda_runtime.h"
//#include "cuda_profiler_api.h"

#define THREADS 32 //In each block THREADS*THREADS threads

struct matrix {
	int ncols;
	int nrows;
	double* mat;
};

void readMatrix(struct matrix* m, FILE* file);
void printMatrix(struct matrix* m, FILE* file);
__global__ void matrixMul(double *d_m1, double *d_m2, double *d_m3, int row1, int row2, int col1, int col2);

/*
Knowing the number of rows and columns,
it reads a matrix from a file and stores it in the appropriate structure.
*/
void readMatrix(struct matrix* m, FILE* file) {
	int i, j;

	m->mat = (double*)malloc(m->ncols * m->nrows * sizeof(double));

	for (i = 0; i < m->nrows; i++) {
		for (j = 0; j < m->ncols; j++) {
			fscanf(file, "%lf", &m->mat[i * m->ncols + j]);
		}
	}
}

/*
The opposite operation to readMatrix. Saves a matrix in the file given as argument
*/
void printMatrix(struct matrix* m, FILE* file) {
	int i, j;

	for (i = 0; i < m->nrows; i++) {
		for (j = 0; j < m->ncols; j++) {
			fprintf(file, "%lf ", m->mat[i * m->ncols + j]);
		}
		fprintf(file, "\n");
	}
}

/*
Performs the multiplication operation between the matrices m1 and m2.
The result will be stored in the matrix m3.
*/
__global__ void matrixMul(double *d_m1, double *d_m2, double *d_m3, int row1, int row2, int col1, int col2){
	int i = blockIdx.y*blockDim.y+threadIdx.y;
	int j = blockIdx.x*blockDim.x+threadIdx.x;

	double sum = 0;
	int k;

	//the two previous for cycle are substituted by the matrix of threads
	if ((i < row1) && (j < col2)){
		for(k = 0; k<col1; k++){
			sum += d_m1[i*col1+k]*d_m2[k*col2+j];
		}
		d_m3[i*col2+j]=sum;
  }
}

int main(int argc, char* argv[]) {
	if(argc != 3){ //1- exe name, 2- mat1, 3- mat2
		printf("Parameter error.");
		exit(1);
	}

	FILE *mat1, *mat2, *resultFile;
	clock_t t;
	struct matrix m1, m2, m3;

	mat1 = fopen(argv[1], "r");
	mat2 = fopen(argv[2], "r");
	fscanf(mat1, "%d %d", &m1.nrows, &m1.ncols);
	fscanf(mat2, "%d %d", &m2.nrows, &m2.ncols);

	//Multiplication is permitted if m1 is m x n and m2 is n x p.
	if(m1.ncols != m2.nrows){
		printf("It is not possible to do matrix multiplication. Check matrices number of rows and cols.");
		fclose(mat1);
		fclose(mat2);
		exit(1);
	}

	readMatrix(&m1, mat1);
	readMatrix(&m2, mat2);

	//M3 initilization
	m3.nrows=m1.nrows;
	m3.ncols=m2.ncols;
	m3.mat = (double*)malloc(m3.ncols * m3.nrows * sizeof(double));

	//cudaProfilerStart();

	/* Device variable, allocations, and transfers */
	double *d_m1, *d_m2, *d_m3;
	cudaMalloc((void**)&d_m1, m1.nrows*m1.ncols*sizeof(double));
	cudaMalloc((void**)&d_m2, m2.nrows*m2.ncols*sizeof(double));
	cudaMalloc((void**)&d_m3, m3.nrows*m3.ncols*sizeof(double));

	cudaMemcpy(d_m1, m1.mat, m1.nrows*m1.ncols * sizeof(double), cudaMemcpyHostToDevice);
	cudaMemcpy(d_m2, m2.mat, m2.nrows*m2.ncols * sizeof(double), cudaMemcpyHostToDevice);

	cudaMemset(d_m3, 0, m3.nrows*m3.ncols*sizeof(double));

	dim3 dimBlock(THREADS, THREADS);
	dim3 dimGrid((m2.ncols+dimBlock.x-1)/dimBlock.x, (m1.nrows+dimBlock.y-1)/dimBlock.y);

	t = clock();
	matrixMul <<<dimGrid, dimBlock>>>(d_m1, d_m2, d_m3, m1.nrows, m2.nrows, m1.ncols, m2.ncols);
	cudaDeviceSynchronize();
	t = clock() - t; //total time spent in matrixMul

	cudaMemcpy(m3.mat, d_m3, m3.nrows*m3.ncols * sizeof(double), cudaMemcpyDeviceToHost);

	cudaFree(d_m1);
	cudaFree(d_m2);
	cudaFree(d_m3);

	//cudaProfilerStop();

	resultFile = fopen("result.txt", "w");
	printMatrix(&m3, resultFile);

	printf("Elapsed time: %.5lf seconds", ((double)t)/CLOCKS_PER_SEC);

	fclose(mat1);
	fclose(mat2);
	fclose(resultFile);

	free(m1.mat);
	free(m2.mat);
	free(m3.mat);

	return 0;
}
