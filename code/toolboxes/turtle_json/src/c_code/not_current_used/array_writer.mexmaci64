#include "mex.h"

/*
 *
 data = rand(500,5)
 
 mex array_writer.c
 
 d = rand(1,1e7)+1:1e7;
 tic; wtf = array_writer(d); toc;
 
 *
 *
 */


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray*prhs[])
{
      //
      //    output_string
      //
    
      //Improvements
      //------------
      //1) Take in an optional string format
      //    # of decimal places of precision
      //    - fixed width of min width
      //2) Take in a pointer to a string
      //
      //- newline support after so many characters
    
      char *str = mxGetData(prhs[1]);
      
      double *data = mxGetData(prhs[0]);
      
      int n_data = mxGetNumberOfElements(prhs[0]);
      
      str = mxMalloc(n_data*20);
      char *str_p = str;

      for (int i = 0; i <= n_data; i++){
          //%f seems a lot slower than %g
        str_p += sprintf(str_p, ",%0.10g",data[i]);
      }
      
      plhs[0] = mxCreateNumericArray(0, 0, mxUINT8_CLASS, mxREAL);
      mxSetData(plhs[0] , str);
      mxSetM(plhs[0] , 1);
      mxSetN(plhs[0] , str_p-str+1);
            
}