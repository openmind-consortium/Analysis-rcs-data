#include "mex.h"

/*
 *
 data = rand(500,5)
 
 mex struct_test.c
 
 d = rand(1,1e7)+1:1e7;
 tic; wtf = array_writer(d); toc;
 
 *
 *
 */


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray*prhs[])
{
    
    plhs[0] = mxCreateStructMatrix(1,1,0,NULL);
    
    setStructField(plhs[0],d1,"d1",mxINT32_CLASS,current_data_index + 1);
    
            
}

void setStructField(mxArray *s, void *pr, const char *fieldname, mxClassID classid, mwSize N)
{
    
    //This function is used to set a field in the output struct
        
    mxArray *pm;
    
    pm = mxCreateNumericArray(0, 0, classid, mxREAL);
    mxSetData(pm, pr);
    mxSetM(pm, 1);
    mxSetN(pm, N);
    mxAddField(s,fieldname);
    mxSetField(s,0,fieldname,pm);
}