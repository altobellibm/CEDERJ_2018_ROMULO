#include <iostream>
#include <time.h>

#undef NDEBUG
#include <assert.h>

#define EIGEN_RUNTIME_NO_MALLOC // Define this symbol to enable runtime tests for allocations

#define CLOCKS_PER_MS (CLOCKS_PER_SEC / 1000)

#include "dual_scaling.h"
#include "leitorbasenumerica.h"

const double LIMITE_INFERIOR_DELTA = 1e-8;
typedef double real_type;
typedef double Index;

typedef Eigen::Matrix<real_type, Eigen::Dynamic, Eigen::Dynamic>	dynamic_size_matrix;
typedef Eigen::Matrix<real_type, Eigen::Dynamic, 1>					column_vector_type;
typedef Eigen::Matrix<real_type, 1, Eigen::Dynamic>					row_vector_type;
typedef ds::multiple_choice_data<dynamic_size_matrix>                  mcd;
typedef ds::rank_order_data<dynamic_size_matrix>                    dominence;


BASE_NUM getMatrixExemplo(std::string& _strFile){

   BASE_NUM base = BASE_NUM();
   if(!LeitorBaseNumerico::obterDadoArquivo(_strFile, base)){
       std::cout << "Erro read file!" << std::endl;
       return base;
   }
   return base;
}

int main(int argc, char* argv[]){

    if(argc != 2)
        return 1;

    std::string strFile = argv[1];

    //dualscaling atributes dados multiplas escolhas
    dynamic_size_matrix x_normed, x_projected;
    dynamic_size_matrix y_normed, y_projected;
    row_vector_type rho, delta, fc;
    column_vector_type fr;

    auto dado = getMatrixExemplo(strFile);

    //unsigned long int64 = 0;
    clock_t Start = clock();

    //time_t start,end;
    //time (&start);
    //contigency table
    std::cout << "start Dual Scaling " << endl;
    ds::dual_scaling(mcd(dado.getMatrix()), x_normed, y_normed, x_projected, y_projected, rho, delta, fc, fr, LIMITE_INFERIOR_DELTA);

    std::cout << x_projected;

    //time (&end);
    //double dif = difftime (end,start);
    //std::cout << "Elasped time is " << dif << endl;

    std::cout << "Time Difference: " << (float)((clock() - Start )/ CLOCKS_PER_MS) / (float) 1000 << endl;

    return 0;
}
