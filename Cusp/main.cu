//

#include <iostream>
#include <time.h>

#include <cusp/coo_matrix.h>
#include <cusp/print.h>
#include <cusp/transpose.h>
#include <cusp/convert.h>
#include <cusp/array2d.h>
#include <cusp/multiply.h>
#include <cusp/array1d.h>
#include <cusp/functional.h>


#include <cusp/dia_matrix.h>
#include <cusp/monitor.h>
#include <cusp/krylov/gmres.h>
#include <thrust/reduce.h>
#include <cusp/sort.h>
#include <thrust/copy.h>
#include <thrust/sequence.h>
#include <cusp/elementwise.h>
#include <thrust/iterator/zip_iterator.h>

//#include <cusp/eigen/lanczos.h>
#include <cusp/krylov/bicgstab.h>
#include <cusolverDn.h>
#include <cusparse_v2.h>

#include "leitorbasenumerica.h"
#include "TimingGPU.cuh"
#include "TimingGPU.cu"

#define CLOCKS_PER_MS (CLOCKS_PER_SEC / 1000)

// error check macros
#define CUSPARSE_CHECK(x) {cusparseStatus_t _c=x; if (_c != CUSPARSE_STATUS_SUCCESS) {printf("cusparse fail: %d, line: %d\n", (int)_c, __LINE__); exit(-1);}}

#define cudaCheckErrors(msg) \
    do { \
        cudaError_t __err = cudaGetLastError(); \
        if (__err != cudaSuccess) { \
            fprintf(stderr, "Fatal error: %s (%s at %s:%d)\n", \
                msg, cudaGetErrorString(__err), \
                __FILE__, __LINE__); \
            fprintf(stderr, "*** FAILED - ABORTING\n"); \
            exit(1); \
        } \
    } while (0)


const float LIMITE_INFERIOR_DELTA = 1e-8;


// convert a linear index to a row index
template <typename T>
struct linear_index_to_row_index : public thrust::unary_function<T,T>
{
  T C; // number of columns
  
  __host__ __device__
  linear_index_to_row_index(T C) : C(C) {}

  __host__ __device__
  T operator()(T i)
  {
    return i / C;
  }
};

template <typename T>
	struct reciprocal_my : public thrust::unary_function<T,T>
	{
	  T value;
	  reciprocal_my(T thr) : value(thr) {};
	  __host__ __device__ 
	  T operator()(const T& v) const {
		   return sqrt(T(value) / v);
	  }
	};

template <typename T>
	struct remove_col : public thrust::unary_function<T,T>
	{
	  T value;
	  remove_col(T thr) : value(thr) {};
	  __host__ __device__ 
	  T operator()(const T& v) const {
		  if (v % value == 1)
			  return 0;
		  else
			  return 1;
	  }
	};	
	
template <typename T>
	struct column_by_vector : public thrust::unary_function<T,T>
	{
	  T* data;
	  T col;
	  column_by_vector(T *_data, T _col) : data(_data), col(_col) {};
	  __host__ __device__ 
	  T operator()(const thrust::tuple<int,float>& v) {
		   return data[thrust::get<0>(v) % (int)col] * thrust::get<1>(v);
	 }
	};

template <typename T>
struct diag_mul : public thrust::unary_function<T,T>
{
	  T* data;
	  T col;
	  diag_mul(T *_data, T _col) : data(_data), col(_col) {};
	  __host__ __device__ 
	  T operator()(const thrust::tuple<float,int>& v) {
		   return thrust::get<0>(v) * data[thrust::get<1>(v) / (int)col];
	 }
	};

	
template <typename T>
struct is_true : thrust::unary_function<T, T>
{
	T col;
	
	is_true(T _c): col(_c) {};
	
    __host__ __device__
    bool operator()(const T &x)
    {
        return (x % col) != 0;
    }
};

void printMatrix(int m, int n, const float*A, int lda, const char* name)
{
    for(int row = 0 ; row < m ; row++){
        for(int col = 0 ; col < n ; col++){
            float Areg = A[row + col*lda];
            printf("%s(%d,%d) = %f  ", name, row+1, col+1, Areg);
        }
		 printf("\n");
    } 
}  
 
bool svd(int M, cusp::array2d<float,cusp::device_memory>& M_denseHM, cusp::array2d<float,cusp::device_memory>& U, cusp::array1d<float,cusp::device_memory>& S){
	
	  thrust::device_ptr<float> dev_ptr = &(M_denseHM.values[0]);
	  float *M_raw_ptr = thrust::raw_pointer_cast(dev_ptr);
		
    // --- device side SVD workspace and matrices
    int work_size = 0;

    int *devInfo;       cudaMalloc(&devInfo, sizeof(int));
    float *d_U;         cudaMalloc(&d_U, M * M * sizeof(float));
    float *d_V;         cudaMalloc(&d_V, M * M * sizeof(float));
    float *d_S;         cudaMalloc(&d_S, M *     sizeof(float));

    cusolverStatus_t stat;

    // --- CUDA solver initialization
    cusolverDnHandle_t solver_handle;
    cusolverDnCreate(&solver_handle);

    cusolverDnSgesvd_bufferSize(solver_handle, M, M, &work_size);

    float *work;    
	  cudaMalloc(&work, work_size * sizeof(float));
	
	  cusolverDnSgesvd(solver_handle, 'A', 'A', M, M, M_raw_ptr, M, d_S, d_U, M, d_V, M, work, work_size, NULL, devInfo);
    
    int devInfo_h = 0;
    cudaMemcpy(&devInfo_h, devInfo, sizeof(int), cudaMemcpyDeviceToHost);
	
	  thrust::device_ptr<float > dev_ptr_U( d_U );
	  thrust::copy(thrust::device,dev_ptr_U, dev_ptr_U + (M*M), U.values.begin());
	
	  thrust::device_ptr<float > dev_ptr_S( d_S );
	  thrust::copy(thrust::device,dev_ptr_S, dev_ptr_S+M, S.begin());
	
    cusolverDnDestroy(solver_handle);
	  
    return 1;
}

int main(int argc, char* argv[]){

    if(argc != 2){
        cout <<"Falta parametro"<<endl;
        return 1;
    }

    std::string strFile = argv[1];
	
	  //std::cout << strFile << std::endl; 
    
	  BASE_NUM base = BASE_NUM();
    LeitorBaseNumerico::obterDadoArquivo(strFile, base);
    	
	  if (base.getErro()) 
	  	return 1;

    cusp::coo_matrix<unsigned long long,float,cusp::device_memory> F;
    
	  //**** matrix F
    std::cout << "Carregando F" << std::endl;
    F = base.getMatrix();
	  std::cout << "Terminado F" << std::endl;
    TimingGPU timer_GPU;
    timer_GPU.StartCounter();
    clock_t Start = clock();
    //std::cout << "F" << std::endl;
  	//cusp::print(F);
   
//	std::cout << "F: n= "<< F.num_rows <<", m= " << F.num_cols <<std::endl;	
	  
    // **** compute the transpose
    cusp::coo_matrix<unsigned long long,float,cusp::device_memory> FT;
    cusp::transpose(F, FT);
	
    //std::cout << "Transposta" << std::endl;													
	  //cusp::print(FT);
	
  	// **** FALTA calcular marginal F da linha e coluna

  	// fr
  	cusp::array1d<int,cusp::device_memory> index_sum_r(F.num_rows);
	  cusp::array1d<float,cusp::device_memory> marginal_sum_r(F.num_rows);
	
  	thrust::reduce_by_key(F.row_indices.begin(), F.row_indices.end(), F.values.begin(), index_sum_r.begin(), marginal_sum_r.begin());

	  //cusp::print(marginal_sum_r);
	
	  // inversa
 	  cusp::array1d<float,cusp::device_memory> fr_inv(F.num_rows, 0);
  	thrust::transform(marginal_sum_r.begin(), marginal_sum_r.end(), fr_inv.begin(), cusp::reciprocal_functor<float>());

  	//cusp::print(fr_inv);

  	// fc
  	cusp::array1d<int,cusp::device_memory> index_sum_c(F.num_cols);
  	cusp::array1d<float,cusp::device_memory> marginal_sum_c(F.num_cols);
	
  	cusp::sort_by_row(F.column_indices, F.row_indices, F.values);

  	//cusp::print(F);
	
  	thrust::reduce_by_key(F.column_indices.begin(), F.column_indices.end(), F.values.begin(), index_sum_c.begin(), marginal_sum_c.begin());
	
	  //cusp::print(marginal_sum_c);
	
  	cusp::array1d<float,cusp::device_memory> fc_inv(F.num_cols, 0);
    thrust::transform(marginal_sum_c.begin(), marginal_sum_c.end(), fc_inv.begin(), cusp::reciprocal_functor<float>());

  	cusp::sort_by_row_and_column(F.row_indices, F.column_indices, F.values);
  	//cusp::print(F);
	
  	//**** Dc
  	// allocate storage for (F.num_cols,F.num_cols) matrix with F.num_cols nonzeros in 1 diagonals
  	cusp::dia_matrix<unsigned long long,float,cusp::device_memory> Dc_inv(F.num_cols,F.num_cols,F.num_cols,1);
    // initialize diagonal offsets
  	Dc_inv.diagonal_offsets[0] = 0;

  	auto diag_c = Dc_inv.values.column(0);
	
  	thrust::copy(thrust::device,fc_inv.begin(), fc_inv.end(), diag_c.begin());
 
  	//cusp::print(Dc_inv);

  	// **** Dr
  	// allocate storage for (F.num_rows,F.num_rows) matrix with F.num_rows nonzeros in 1 diagonals
  	cusp::dia_matrix<unsigned long long,float,cusp::device_memory> Dr_inv(F.num_rows,F.num_rows,F.num_rows,1);
  	// initialize diagonal offsets
  	Dr_inv.diagonal_offsets[0] = 0;
	
  	auto diag_r = Dr_inv.values.column(0);

  	thrust::copy(thrust::device,fr_inv.begin(), fr_inv.end(), diag_r.begin());	
/*
  	cusp::csr_matrix<int,float,cusp::device_memory> DR(F.num_rows,F.num_rows,F.num_rows);
  	cusp::array1d<int,cusp::device_memory> rows(F.num_rows);
  	thrust::sequence(rows.begin(), rows.end(),0);
    thrust::copy(thrust::device,rows.begin(), rows.end(), DR.row_offsets.begin());
  	DR.row_offsets[F.num_rows] = F.num_rows;
  	thrust::copy(thrust::device,rows.begin(), rows.end(), DR.column_indices.begin());
    thrust::copy(thrust::device,fr_inv.begin(), fr_inv.end(), DR.values.begin());

	
  	cusp::csr_matrix<int,float,cusp::device_memory> DC(F.num_cols,F.num_cols,F.num_cols);
  	cusp::array1d<int,cusp::device_memory> cols(F.num_cols);
  	thrust::sequence(cols.begin(), cols.end(),0);
    thrust::copy(thrust::device,cols.begin(), cols.end(), DC.row_offsets.begin());
  	DC.row_offsets[F.num_cols] = F.num_cols;
  	thrust::copy(thrust::device,cols.begin(), cols.end(), DC.column_indices.begin());
    thrust::copy(thrust::device,fc_inv.begin(), fc_inv.end(), DC.values.begin());
*/	
    //cusp::print(DR);
  	//cusp::print(DC);
	
	/*
	cusp::coo_matrix<unsigned long long,float,cusp::host_memory> FT_H(FT);
    cusp::coo_matrix<unsigned long long,float,cusp::host_memory> Dr_inv_H(Dr_inv);
    cusp::coo_matrix<unsigned long long,float,cusp::host_memory> F_H(F);
    cusp::coo_matrix<unsigned long long,float,cusp::host_memory> Dc_inv_H(Dc_inv);
    cusp::coo_matrix<unsigned long long,float,cusp::host_memory> M1_H;
    cusp::coo_matrix<unsigned long long,float,cusp::host_memory> M2_H;
	cusp::coo_matrix<unsigned long long,float,cusp::host_memory> M_H;
    */
    cusp::coo_matrix<unsigned long long,float,cusp::device_memory> M1;
    cusp::coo_matrix<unsigned long long,float,cusp::device_memory> M2;
    cusp::coo_matrix<unsigned long long,float,cusp::device_memory> M;
	  
    
    
    std::cout << "Inicio da Multiplicação" << std::endl;
  	//cusp::multiply(FT,DR,M1);
    cusp::multiply(FT,Dr_inv,M1);
  	//cusp::multiply(FT_H,Dr_inv_H,M1_H);
    
    //cusp::sort_by_row_and_column(M1.row_indices, M1.column_indices, M1.values);
  	//std::cout << "M1(" << M1.num_rows << " , " << M1.num_cols << " ) = "  << M1.num_entries << std::endl;
	  std::cout << "2a parte da Multiplicação" << std::endl;
  	//std::cin.ignore();
  	//cusp::print(M1);
  	cusp::multiply(M1,F,M2);
	//cusp::multiply(M1_H,F_H,M2_H);
    
  	//std::cout << "M2(" << M2.num_rows << " , " << M2.num_cols << " ) = "  << M2.num_entries << std::endl;
  	//std::cin.ignore();
    
	std::cout << "3a parte da Multiplicação" << std::endl;
    cusp::multiply(M2,Dc_inv,M);
    //cusp::multiply(M2_H,Dc_inv_H,M_H);
    
    //cusp::coo_matrix<unsigned long long,float,cusp::device_memory> M(M_H);
    
  	cusp::array2d<float,cusp::device_memory> M_denseHM;
    
    cusp::convert(M,M_denseHM);
	
  	//cusp::print(M_denseHM);

  	cusp::array2d<float,cusp::device_memory> U(F.num_cols,F.num_cols);
  	cusp::array1d<float,cusp::device_memory> S(F.num_cols);
  	
//  std::cout << "M_denseHM: n= "<< M_denseHM.num_rows <<", m= " << M_denseHM.num_cols <<std::endl;
    std::cout << "Inicio da Decomposicao" << std::endl;
  	svd(F.num_cols,M_denseHM, U, S);
/*	
    S[0] = 0.826388;
    S[1] = 0.789907;
    S[2] = 0.210093;
    S[3] = 0.173612;

	//cusp::print(D);

    U.values[0] = 0.478171;
    U.values[1] = 0.0710447;
    U.values[2] = 0.0710447;
    U.values[3] = 0.478171;
    U.values[4] = -0.0985857;
    U.values[5] = -0.551342;
    U.values[6] = -0.551342;
    U.values[7] = -0.0985857;
    U.values[8] = -0.379585;
    U.values[9] = 0.480297;
    U.values[10] = 0.480297;
    U.values[11] = -0.379585;
    U.values[12] = 0.624277;
    U.values[13] = 0.0823854;
    U.values[14] = -0.0823854;
    U.values[15] = -0.624277;
    U.values[16] = -0.440523;
    U.values[17] = 0.433206;
    U.values[18] = -0.433206;
    U.values[19] = 0.440523;
    U.values[20] = -0.183754;
    U.values[21] = -0.515592;
    U.values[22] = 0.515592;
    U.values[23] = 0.183754;

  	std::cout << "X" << std::endl;
    //cusp::print(U);
  	std::cout << "V" << std::endl;
  	//cusp::print(S);
*/	
  	//**************************************
    
    std::cout << "Fim da Decomposicao" << std::endl;
    cusp::array1d<float,cusp::device_memory> rho(S.size()-1);
    thrust::transform(S.begin()+1, S.end(), rho.begin(), cusp::sqrt_functor<float>());
  	//std::cout << "rho" << std::endl;
  	//cusp::print(rho);

  	cusp::array2d<float,cusp::device_memory> X(U.num_rows,U.num_cols-1);

  	cusp::array1d<int,cusp::device_memory> index(F.num_cols*(F.num_cols-1));
  	thrust::sequence(index.begin(), index.end(),0);	
  	thrust::copy_if( U.values.begin(),  U.values.end(), index.begin(),  X.values.begin(), is_true<int>(F.num_cols));
	
    //std::cout << "X" << std::endl;
  	//cusp::print(X);
	
	
	  //**************************************

    cusp::array2d<float,cusp::device_memory> x_sqr;
    cusp::elementwise(X, X, x_sqr,  thrust::multiplies<float>());

    //std::cout << "X_sqr" << std::endl;
    //cusp::print(x_sqr);
	
  	//**************************************
	
    //thrust::copy(thrust::device,marginal_sum_c.begin(), marginal_sum_c.end(), off_c.begin());
	
  	cusp::array2d<float,cusp::device_memory> T(X.num_rows,X.num_cols);
	
  	cusp::array1d<int,cusp::device_memory> index_X(X.num_rows*X.num_cols);
  	thrust::sequence(index_X.begin(), index_X.end(),0);
  	//cusp::print(index_X);
	
  	thrust::transform(thrust::make_zip_iterator(thrust::make_tuple(x_sqr.values.begin(), index_X.begin())), thrust::make_zip_iterator(thrust::make_tuple(x_sqr.values.end(), index_X.end())), T.values.begin(), diag_mul<float>(thrust::raw_pointer_cast(marginal_sum_c.data()),(float)X.num_cols));
	
  	//std::cout << "T" << std::endl;
  	//cusp::print(T);

  	//**************************************
  	cusp::array1d<int,cusp::device_memory> index_sum_t(T.num_cols);
  	cusp::array1d<float,cusp::device_memory> marginal_sum_t(T.num_cols);
	
  	cusp::array2d<float,cusp::device_memory> T_T(T.num_cols,T.num_rows);
    cusp::transpose(T, T_T);
	
  	thrust::reduce_by_key(thrust::make_transform_iterator(thrust::counting_iterator<int>(0), linear_index_to_row_index<int>(T.num_rows)), thrust::make_transform_iterator(thrust::counting_iterator<int>(0), linear_index_to_row_index<int>(T.num_rows)) + (T.num_rows*T.num_cols), T_T.values.begin(), index_sum_t.begin(), marginal_sum_t.begin(), thrust::equal_to<int>(),thrust::plus<float>());
	
  	//std::cout << "cc" << std::endl;
  	//cusp::print(marginal_sum_t);
	
  	cusp::array1d<float,cusp::device_memory> marginal_sum_t_ft(T.num_cols);
	
  	thrust::transform(marginal_sum_t.begin(), marginal_sum_t.end(), marginal_sum_t_ft.begin(), reciprocal_my<float>(float(F.num_entries)));

  	//cusp::print(marginal_sum_t_ft);
	
	
  	//**************************************
  	cusp::array2d<float,cusp::device_memory> x_normed(X.num_rows,X.num_cols);
		
	  thrust::transform(thrust::make_zip_iterator(thrust::make_tuple(index_X.begin(), X.values.begin())), thrust::make_zip_iterator(thrust::make_tuple(index_X.end(), X.values.end())), x_normed.values.begin(), column_by_vector<float>(thrust::raw_pointer_cast(marginal_sum_t_ft.data()),(float)X.num_cols));

    //  std::cout << "x_normed" << std::endl;
  	//  cusp::print(x_normed);
	
  	//**************************************
  	cusp::array2d<float,cusp::device_memory> x_project(X.num_rows,X.num_cols);
	
  	thrust::transform(thrust::make_zip_iterator(thrust::make_tuple(index_X.begin(), x_normed.values.begin())), thrust::make_zip_iterator(thrust::make_tuple(index_X.end(), x_normed.values.end())), x_project.values.begin(), column_by_vector<float>(thrust::raw_pointer_cast(rho.data()),(float)X.num_cols));

    //  std::cout << "x_project" << std::endl;
  	//  cusp::print(x_project);
   
//  std::cout << "X_project: n= "<< x_project.num_rows <<", m= " << x_project.num_cols <<std::endl;
    std::cout << "GPU Timing = " << timer_GPU.GetCounter() << " ms" << std::endl;
    std::cout << "Time Difference: " << (float)((clock() - Start )/ CLOCKS_PER_MS) / (float) 1000 << endl;
    return 0;
}
