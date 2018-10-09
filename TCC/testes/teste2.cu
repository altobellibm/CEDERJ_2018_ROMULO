#include <cusp/io/matrix_market.h>
#include <cusp/gallery/random.h>
#include <cusp/coo_matrix.h>
#include <cusp/print.h>
#include <cusp/array2d.h>
#include <cusp/array1d.h>
#include <cusp/convert.h>

#include <iostream>

using namespace std;

int main(void)
{
    cusp::coo_matrix<int, float, cusp::device_memory> A;
    //cusp::array2d<float,cusp::device_memory> B;
    
    cusp::io::read_matrix_market_file(A, "A.mtx");
    
    
    //cusp::print(A);
    //cout << A.num_cols << A.num_rows ;A.column_indices A.num_entries A.row_indices
        
    

    
    //Fr = A.row_indices;
    // define array container types
    //typedef cusp::array1d<float, cusp::device_memory> Array;
    // define array view types
    //typedef typename cusp::array1d_view<Array::iterator> ArrayView;
    //ArrayView a_rowindices(Fr.begin(),Fr.end());
    //cout << a_rowindices.size();
    
    
    cusp::array1d<float,cusp::device_memory> aux(A.num_entries);
    for(int i = 0; i < A.num_entries; i++) {
        aux[i] = 0;
    }
        cusp::array1d<float,cusp::device_memory> Fr(A.num_rows);
    for(int i = 0; i < A.num_entries; i++) {
        if(aux[i] == 0) {
            int count = 0;
            for(int j = i; j < A.num_entries; j++)
                if(A.row_indices[j] == A.row_indices[i]) {
                    count += 1;
                    aux[j] = 1;
                }
            cout << A[i] << " occurs " << count << " times" << endl;
        }
    }
        
    cusp::print(Fr);
    
    for (int i = 0; i < A.num_entries ; i++){
        
    }
    
    //cusp::gallery::random(B, 1000, 1000, 10);
    //cusp::convert(B, C);

    //cusp::io::write_matrix_market_file(B, "B.mtx");

    return 0;
}