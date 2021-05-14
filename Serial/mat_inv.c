#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

struct matrix {
	int ncols;
	int nrows;
	double* mat;
};

void readMatrix(struct matrix* m, FILE* file);
void storeMatrix(struct matrix* m, FILE* file);
void matrixInversion(struct matrix* m1, struct matrix* m2);
int computeDeterminant(const struct matrix* m);

/* 
	Reads a matrix from a file and stores it into the appropriate structure.
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
	Stores a matrix into the file passed as argument
*/
void storeMatrix(struct matrix* m, FILE* file) {
	int i, j;

	for (i = 0; i < m->nrows; i++) {
		for (j = 0; j < m->ncols; j++) {
			fprintf(file, "%lf ", m->mat[i * m->ncols + j]);
		}
		fprintf(file, "\n");
	}
}

/* https://www.codesansar.com/c-programming-examples/matrix-determinant.htm */
int computeDeterminant(const struct matrix* m) {
	int i, j, k, ratio;
	float det = 1;
	double* mat = (double*)malloc(m->ncols * m->nrows * sizeof(double));
	mat = memcpy(mat, m->mat, m->nrows * m->ncols * sizeof(double));
	
	/* Using Gauss Elimination technique for transforming matrix to upper triangular matrix */
	for (i = 0; i < m->nrows; i++) {
	 	if (mat[i * m->ncols + i] == 0) {
	 		printf("Mathematical Error: diagonal elements cannot be equal to 0");
			exit(0);
		}
		for (j = i + 1; j < m->nrows; j++) {
			ratio = mat[j * m->ncols + i] / mat[i * m->ncols + i];
	
			for (k = 0; k < m->nrows; k++) {
				mat[j * m->ncols + k] = mat[j * m->ncols + k] - ratio * mat[i * m->ncols + k];
			}
		}
	}
	
	/* Finding determinant by multiplying elements in principal diagonal elements */
	for (i = 0; i < m->nrows; i++) {
        det = det * mat[i * m->ncols + i];
    }
    
    free(mat);
    return det;
}

/*
	Performs the inversion of the matrix m by using Jacobi algorithm
*/
void matrixInversionJacobi(struct matrix* m) {
	int i, j, k;

	/* Jacobi Algorithm */
	
}

/*
	Performs the inversion of the matrix m by using Gauss-Seidel algorithm
*/
void matrixInversionGauss(struct matrix* m) {
	int i, j, k;

	/* Gauss-Seidel Algorithm */
}

int main(int argc, char* argv[]) {
	/* Checking parameters: 1.mat_inv.exe 2.matrix */
	if(argc != 2) {
		printf("Parameters error.");
		exit(1);
	}

	/* Declaring variables */
	FILE *mat, *resultFile;
	clock_t t;
	struct matrix m;
	float det;

	/* Reading matrix */
	mat = fopen(argv[1], "r");
	fscanf(mat, "%d %d", &m.nrows, &m.ncols);
	readMatrix(&m, mat);

	/* Checking if it is possible to perform the matrix inversion */
	det = computeDeterminant(&m);
	printf("Determinant of the matrix: %f", det);
	if (det == 0) {
		printf("\nIt is not possible to compute the inversion: determinant is equal to 0");
		fclose(mat);
		exit(1);
	}

	/* Performing inversion and computing its duration*/
	t = clock();
	matrixInversionJacobi(&m);
	t = clock() - t;

	/* Storing matrix into a file */
	resultFile = fopen("inverse.txt", "w");
	storeMatrix(&m, resultFile);

	/* Printing duration in seconds */
	printf("\nElapsed time: %f seconds", ((double)t) / CLOCKS_PER_SEC);

	/* File closing and Memory cleaning */
	fclose(mat);
	fclose(resultFile);
	free(m.mat);
	
	return 0;
}
