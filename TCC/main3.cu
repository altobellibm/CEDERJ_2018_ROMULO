#include <cusp/array1d.h>
#include <cusp/array2d.h>
#include <cusp/print.h>
#include <cusp/gallery/poisson.h>
// include cusp lapack header file
#include <cusp/lapack/lapack.h>
int main()
{
  // create an empty dense matrix structure
  cusp::array2d<float,cusp::device_memory> A;
  // create 2D Poisson problem
  cusp::gallery::poisson5pt(A, 4, 4);
  // create initial RHS of 2 vectors and initialize
  cusp::array2d<float,cusp::device_memory> B(A.num_rows, 2);
  B.values = cusp::random_array<float>(B.values.size());
  // solve multiple RHS vectors
  cusp::lapack::trtrs(A, B);
  // print the contents of B
  cusp::print(B);
}
