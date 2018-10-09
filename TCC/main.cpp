#include <iostream>
#include <time.h>
#include <cusp/coo_matrix.h>
#include <cusp/print.h>

#include <cusp/convert.h>
#include <cusp/array2d.h>

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

    cusp::array2d<float,cusp::device_memory> B;
    
    cusp::coo_matrix<int,float,cusp::device_memory> A;
    
    A = dado.getMatrix();
    cusp::convert(A,B);
    
    cusp::print(A);
    cusp::print(B);
    
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