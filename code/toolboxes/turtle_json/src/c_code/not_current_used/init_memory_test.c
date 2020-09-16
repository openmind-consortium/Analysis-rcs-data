#include "mex.h"
#include <sys/time.h>   //for gettimeofday

//quick test on memory allocation speeed
//for N = 6e6, I get
//
//headers: 0.427
//   data: 0.354

#define TIC(x) \
    struct timeval x ## _0; \
    struct timeval x ## _1; \
    gettimeofday(&x##_0,NULL);
    
#define TOC_AND_LOG(x,y) \
    gettimeofday(&x##_1,NULL); \
    double *y = mxMalloc(sizeof(double)); \
    *y = (double)(x##_1.tv_sec - x##_0.tv_sec) + (double)(x##_1.tv_usec - x##_0.tv_usec)/1e6; \
    mexPrintf("Elapsed Time: %0g\n",*y);
    


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray*prhs[])
{
    
    
    int N = 6e6;
    mxArray **mx_arrays = mxMalloc(N*sizeof(mxArray *));
    double **values = mxMalloc(N*sizeof(double *));
    
    TIC(data);
    for (int i = 0; i < N; i++){
        mx_arrays[i] = mxCreateNumericMatrix(0,0,mxDOUBLE_CLASS,mxREAL);
    }
    TOC_AND_LOG(data,cheese);
    
    TIC(data2);
    for (int i = 0; i < N; i++){
        values[i] = mxMalloc(sizeof(double));
    }
    TOC_AND_LOG(data2,cheese2);
    
        
        
}