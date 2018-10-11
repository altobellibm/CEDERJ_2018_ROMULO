#include <iostream>
#include <time.h>
#include <cusp/coo_matrix.h>
#include <cusp/print.h>
#include <cusp/transpose.h>
#include <cusp/convert.h>
#include <cusp/array2d.h>
#include <cusp/multiply.h>

#undef NDEBUG
#include <assert.h>


//#define EIGEN_RUNTIME_NO_MALLOC // Define this symbol to enable runtime tests for allocations


//#include "dual_scaling.h"
#include "leitorbasenumerica.h"

//const double LIMITE_INFERIOR_DELTA = 1e-8;
//typedef double real_type;
//typedef double index;

//typedef Eigen::Matrix<real_type, Eigen::Dynamic, Eigen::Dynamic>	dynamic_size_matrix;
//typedef Eigen::Matrix<real_type, Eigen::Dynamic, 1>					column_vector_type;
//typedef Eigen::Matrix<real_type, 1, Eigen::Dynamic>					row_vector_type;
//typedef ds::contingency_table<dynamic_size_matrix>                  mcd;
//typedef ds::rank_order_data<dynamic_size_matrix>                    dominence;


BASE_NUM getMatrixExemplo(std::string& _strFile){

   BASE_NUM base = BASE_NUM();
   if(!LeitorBaseNumerico::obterDadoArquivo(_strFile, base)){
       std::cout << "Erro read file!" << std::endl;
       return base;
   }
   return base;
}

cusp::array1d<float,cusp::device_memory> sumRows(cusp::coo_matrix<int,float,cusp::device_memory>& _M){
    
    cusp::array1d<float,cusp::device_memory> aux(_M.num_entries);
    for(int i = 0; i < _M.num_entries; i++) {
        aux[i] = 0;
    }
        
    cusp::array1d<float,cusp::device_memory> N(_M.num_rows);
    int k = 0;
    for(int i = 0; i < _M.num_entries; i++) {
        if(aux[i] == 0) {
            int count = 0;
            for(int j = i; j < _M.num_entries; j++)
                if(_M.row_indices[j] == _M.row_indices[i]) {
                    count += 1;
                    aux[j] = 1;
                }
            N[k++] = count;
            //cout << _M.values[i] << " occurs " << count << " times" << endl;
            
        }
    }
    return N; 
}

cusp::coo_matrix<int,float,cusp::device_memory> diagMatrix(cusp::array1d<float,cusp::device_memory>& _M){
    
    cusp::coo_matrix<int,float,cusp::device_memory> N(_M.size(),_M.size(),_M.size());
    
    for(int i = 0; i < _M.size(); i++){
        N.column_indices[i] = i;
        N.row_indices[i] = i;
        N.values[i] = _M[i];
    }
    return N; 
}

cusp::coo_matrix<int,float,cusp::device_memory> invDiagMatrix(cusp::coo_matrix<int,float,cusp::device_memory>& _M){
    
    for(int i = 0; i < _M.num_rows; i++){
        _M.values[i] = 1 / _M.values[i];
    }
    return _M; 
}

/*
BASE_UTIL getMatrixExemploDominance(std::string& _strfile){

   BASE_UTIL base;

   if(!leitorbaseHUtilits::obterDadoArquivo(_strfile, base)){
       std::cout << "Erro read file!" << std::endl;
       return base;
   }
   return base;
}
*/

int main(int argc, char* argv[]){

    if(argc != 2){
        cout <<"Falta parametro"<<endl;
        return 1;
    }

    std::string strFile = argv[1];
    

    //dualscaling atributes dados multiplas escolhas
//    dynamic_size_matrix x_normed, x_projected;
//    dynamic_size_matrix y_normed, y_projected;
//    row_vector_type rho, delta, fc;
//    column_vector_type fr;

    auto dado = getMatrixExemplo(strFile);

    cusp::coo_matrix<int,float,cusp::device_memory> F;
    cusp::coo_matrix<int,float,cusp::device_memory> Ft;
    
    cusp::array1d<float,cusp::device_memory> Fr;
    cusp::array1d<float,cusp::device_memory> Fc;
    
    cusp::coo_matrix<int,float,cusp::device_memory> Dr;
    cusp::coo_matrix<int,float,cusp::device_memory> Dc;
    
    cusp::coo_matrix<int,float,cusp::device_memory> Dri;
    cusp::coo_matrix<int,float,cusp::device_memory> Dci;
    
    cusp::coo_matrix<int,float,cusp::device_memory> M1;
    cusp::coo_matrix<int,float,cusp::device_memory> M2;
    cusp::coo_matrix<int,float,cusp::device_memory> M;
    
    F = dado.getMatrix();
        
    Fr = sumRows(F);
    cusp::transpose(F,Ft);
    Fc = sumRows(Ft);
    
    Dr = diagMatrix(Fr);
    Dc = diagMatrix(Fc);
    
    Dri = invDiagMatrix(Dr);
    Dci = invDiagMatrix(Dc);
    
    cusp::multiply(Ft,Dri,M1);
    cusp::multiply(F,Dci,M2);
    cusp::multiply(M1,M2,M);
    
    cusp::print(M);
    
    time_t start,end;
    time (&start);
    
    //contigency table
    std::cout << "start Dual Scaling " << endl;
//    ds::dual_scaling(mcd(dado.getMatrix()), x_normed, y_normed, x_projected, y_projected, rho, delta, fc, fr, LIMITE_INFERIOR_DELTA);

    time (&end);
    double dif = difftime (end,start);
    std::cout << "Elasped time is " << dif << endl;

    // dominance_data
/*
    auto baseDominance = getMatrixExemploDominance(strFile);

    dynamic_size_matrix x_normedR, x_projectedR;
    dynamic_size_matrix y_normedR, y_projectedR;
    row_vector_type rhoR, deltaR;

    time_t start,end;
    time (&start);

    ds::dual_scaling(dominence(baseDominance.getMatrix()), x_normedR, y_normedR, x_projectedR, y_projectedR, rhoR, deltaR);

    double dif = difftime (end,start);
    std::cout << "Elasped time is " << dif << endl;
    */

    return 0;
}
