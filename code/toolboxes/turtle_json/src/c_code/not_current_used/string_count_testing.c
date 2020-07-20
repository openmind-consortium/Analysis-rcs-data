#include "mex.h"
#include <x86intrin.h>
#include "stdint.h"

//  mex  CFLAGS="$CFLAGS -std=c11 -fopenmp -mavx2" string_count_testing.c 

/*
 file_path = json.utils.getBinFilePath('large-dict.json')
 
 str = sl.io.fileRead(file_path,'*uint8');
 
 string_count_testing(str);
 
 *
 */

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray*prhs[])
{

    uint8_t *data = mxGetData(prhs[0]);
    mwSize n = mxGetN(prhs[0]);
    
    __m256i char_to_match = _mm256_set1_epi8(34);
    
    __m256i m_data;
    m_data = _mm256_lddqu_si256((__m256i *)data);
    
    __m256i result = _mm256_cmpeq_epi8(m_data,char_to_match);
    
    int mask = _mm256_movemask_epi8(result);
    
    mexPrintf("mask: %d\n", mask);
    
    
    
    //__builtin_popcount
    
    //_mm256_lddqu_si256
    
    //_mm256_set1_epi8
    
}