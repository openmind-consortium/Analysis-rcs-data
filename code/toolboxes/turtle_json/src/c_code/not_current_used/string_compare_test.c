#include "mex.h"
#include <stdio.h>
#include <x86intrin.h>
#include <string.h>
#include <stdio.h>
#include <stdint.h>

//mex CFLAGS="$CFLAGS -std=c11 -fopenmp -mavx" LDFLAGS="$LDFLAGS -fopenmp" COPTIMFLAGS="-O3 -DNDEBUG" turtle_json_mex.c turtle_json_main.c turtle_json_post_process.c -O -v

//  s3 = typecast(uint8('testing1'),'double')
//  s4 = typecast(uint8('testing1'),'double')

//  setenv('MW_MINGW64_LOC','C:\TDM-GCC-64')
//  mex CFLAGS="$CFLAGS -std=c11 -mavx2" string_compare_test.c

//%lld

//  ? Do we need to use intrinsics, can we just use long long?
//  => Then we don't get byte level differences (-1 or 0 by char)
//  This is useful for partial strings, just pass in everything, and extract
//  the desired number to match
//
//  e.g
//  "this is": "an apple"
//  "this is": 3
//  Are these keys the same?
//  Pass in point to t, bit mask with
//  Only works with even lengths ... but, we always pad with ", so we
//  can adjust the length depending upon even or odd ...
//  

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray*prhs[]){

    //__m256i _mm256_cmpeq_epi16 (__m256i a, __m256i b)

    //Use mask on invalids???
    //__mmask16 _mm256_cmpeq_epi16_mask (__m256i a, __m256i b)
    //
    // -1 for true
    // 0 for false
    
    //__mmask16 result;
    //                     1234567890123456
    
    __m256i result;
    int collapsed_result;       
    
    int n_compare = 7;
    int n_drop = 32 - n_compare;
    int answer = -33554432; //bin2dec([repmat('1',1,7),repmat('0',1,32-7)]), typecast(uint32(4261412864),'int32')
    
    char test_string1[] = "this is a testa apples are delicious asdfasfdasdf asdfasdfasdf";
    char test_string2[] = "this is a testb                                               ";
    
    //https://software.intel.com/sites/landingpage/IntrinsicsGuide/#text=_mm256_l&expand=718,3575,3024
    //"this is a test"  => 14 chars, so 7 should match
    __m256i b1 = _mm256_lddqu_si256 ((__m256i *)test_string1);     
    __m256i b2 = _mm256_lddqu_si256 ((__m256i *)test_string2);  
    
    //https://software.intel.com/sites/landingpage/IntrinsicsGuide/#text=_mm256_cmpeq_epi16&expand=718
    //L1,T0.5
    result = _mm256_cmpeq_epi16(b1,b2);
    
    //https://software.intel.com/sites/landingpage/IntrinsicsGuide/#text=_mm256_movemask_epi8&expand=718,3575
    //L3,T-
    collapsed_result = _mm256_movemask_epi8(result) << n_drop;
    
    mexPrintf("collapsed_result: %d\n",collapsed_result);
    mexPrintf("is_equal: %d\n",collapsed_result == answer);
    
    
    
    
    //Need to shift for comparison
    
    //another option, but this requires zeroing bytes
    //int _mm256_testz_si256 (__m256i a, __m256i b)
    //faster on newer processors
    
//     mexPrintf("wtf3: %d\n",wtf3);
//     
//     match7 = 2^14-1; //first 14 bits are true
    
//     _mm256_storeu_si256 ((__m256i *)&wtf,result);
//     _mm256_storeu_si256 ((__m256i *)&wtf2,match7);
    
//     if ((long long int) result == (long long int) match7){
//         mexPrintf("Hi mom\n");
//     }
    

}