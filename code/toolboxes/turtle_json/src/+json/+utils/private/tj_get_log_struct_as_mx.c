#include "../../../c_code/turtle_json.h"

//  Note this is not designed to be fast since this is only for debugging

//  Compile as:
//  mex -DNO_OPENMP tj_get_log_struct_as_mx.c 
//
//  Exposed in MATLAB as:
//  json.utils.getPerformanceLog


//TODO: Do an input check ...

#define addINT32(y) \
s = mxCreateNumericMatrix(1, 1, mxINT32_CLASS, 0); \
temp_int = (int *)mxGetData(s); \
*temp_int = slog->y; \
mxAddField(plhs[0],#y); \
mxSetField(plhs[0],0,#y,s);

//mxSetFieldByNumber(plhs[0],0,i,s);


#define addDOUBLE(y) \
s = mxCreateNumericMatrix(1, 1, mxDOUBLE_CLASS, 0); \
temp_double = (double *)mxGetData(s); \
*temp_double = slog->y; \
mxAddField(plhs[0],#y); \
mxSetField(plhs[0],0,#y,s);

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray*prhs[])
{
    //Goal
    //1 input -> uint8 data
    //1 output struct array ...
    
    struct sdata *slog = (struct sdata*)mxGetData(prhs[0]);
    
    mxArray *s;
    int *temp_int;
    double *temp_double;
    
    //This is slow since we will add fields dynamically
    plhs[0] = mxCreateStructMatrix(1,1,0,0);
    
    s = mxCreateNumericMatrix(1,MAX_DEPTH_ARRAY_LENGTH,mxINT32_CLASS,0);
    temp_int = (int *)mxGetData(s);
    memcpy(temp_int,slog->obj__n_objects_at_depth,MAX_DEPTH_ARRAY_LENGTH);
    mxAddField(plhs[0],"obj__n_objects_at_depth");
    mxSetField(plhs[0],0,"obj__n_objects_at_depth",s);
    
    s = mxCreateNumericMatrix(1,MAX_DEPTH_ARRAY_LENGTH,mxINT32_CLASS,0);
    temp_int = (int *)mxGetData(s);
    memcpy(temp_int,slog->arr__n_arrays_at_depth,MAX_DEPTH_ARRAY_LENGTH);
    mxAddField(plhs[0],"arr__n_arrays_at_depth");
    mxSetField(plhs[0],0,"arr__n_arrays_at_depth",s);    
    
    
    
    int obj__n_objects_at_depth[MAX_DEPTH_ARRAY_LENGTH];
    int arr__n_arrays_at_depth[MAX_DEPTH_ARRAY_LENGTH];
    
    //int i = 0;
    //i++; //skipping int array for now ...
    
    //int arr__n_arrays_at_depth[MAX_DEPTH_ARRAY_LENGTH];
    addINT32(buffer_added);
    addINT32(alloc__n_tokens_allocated);
    addINT32(alloc__n_objects_allocated);
    addINT32(alloc__n_arrays_allocated);
    addINT32(alloc__n_keys_allocated);
    addINT32(alloc__n_strings_allocated);
    addINT32(alloc__n_numbers_allocated);
    addINT32(alloc__n_data_allocations);
    addINT32(alloc__n_object_allocations);
    addINT32(alloc__n_array_allocations);
    addINT32(alloc__n_key_allocations);
    addINT32(alloc__n_string_allocations);
    addINT32(alloc__n_numeric_allocations);
    addINT32(obj__max_keys_in_object);
    addINT32(obj__n_unique_objects);
    addDOUBLE(time__elapsed_read_time);
    addDOUBLE(time__c_parse_init_time);
    addDOUBLE(time__c_parse_time);
    addDOUBLE(time__parsed_data_logging_time);
    addDOUBLE(time__total_elapsed_parse_time);
    addDOUBLE(time__object_parsing_time);
    addDOUBLE(time__object_init_time);
    addDOUBLE(time__array_parsing_time);
    addDOUBLE(time__number_parsing_time);
    addDOUBLE(time__string_memory_allocation_time);
    addDOUBLE(time__string_parsing_time);
    addDOUBLE(time__total_elapsed_pp_time);
    addDOUBLE(time__total_elapsed_time_mex);
    addDOUBLE(qpc_freq);
  	addINT32(n_nulls);
    addINT32(n_tokens);
    addINT32(n_arrays);
    addINT32(n_numbers);
    addINT32(n_objects);
    addINT32(n_keys);
    addINT32(n_strings);

}