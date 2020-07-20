#include "turtle_json.h"
#include "json_info_to_data.h"

mxArray* permuteArray(mxArray* temp_array, int n_dimensions){
    
    //Ideally this would be avoided since it is only called to change from
    //column-major to row-major ordering
    
    //Note, we pass in the # of dimensions since mxGetNumberOfDimensions
    //truncates all trailing 1d dimensions, i.e. so if we have an array
    //of size [3,1,1,1] it would get permuted to [1,3] and not [1,1,1,3]
    
    //int n_dimensions = mxGetNumberOfDimensions(temp_array);
    
    mxArray* second_dims = mxCreateNumericMatrix(1,n_dimensions,mxDOUBLE_CLASS,0);
    double* output_array_dims = mxGetData(second_dims);
    
    for (int i = 0; i < n_dimensions; i++){
        //
        //  Example for 3d array
        //  0, 1, 2 - output index
        //  3, 2, 1 - value
        //
        //  0 = 3 - 0 = 3
        //  1 = 3 - 1 = 2
        //  2 = 3 - 2 = 1
        output_array_dims[i] = n_dimensions - i;
    }
    
    //B = permute(A,ORDER)
    //int mexCallMATLAB(int nlhs, mxArray *plhs[], int nrhs, mxArray *prhs[], const char *functionName);   
    //
    //  plhs    = output
    //  prhs[0] = input_array;
    //  prhs[1] = order
    
    mxArray* plhs;
    mxArray* prhs[2];
    prhs[0] = temp_array;
    prhs[1] = second_dims;
            
    mexCallMATLAB(1,&plhs, 2, prhs, "permute");

    return plhs;
}


void populate_dims__row_major(mwSize *dims, int *d1, 
        int *child_count_array, int array_data_index, 
        int array_md_index, int n_dimensions){    
    //
    //  row-major ordering - i.e. highest dimension changes quickest
    //
    //  e.g. [[5,4],[2,3],[7,8]] -> size => [3,2]
    //
    //  5 4
    //  2 3
    //  7 8
    
    dims[0] = child_count_array[array_data_index];
    for (int iDim = 1; iDim < n_dimensions; iDim++){
        array_data_index = d1[++array_md_index];
        dims[iDim] = child_count_array[array_data_index];
    }
}

void populate_dims__column_major(mwSize *dims, int *d1, 
        int *child_count_array, int array_data_index, 
        int array_md_index, int n_dimensions){
    //
    //  column-major ordering - i.e. low dimension changes quickest
    //
    //  e.g. [[5,4],[2,3],[7,8]] -> size => [2,3]
    //
    //  5 2 7
    //  4 3 8
    
    dims[n_dimensions-1] = child_count_array[array_data_index];
    
    for (int iDim = n_dimensions-2; iDim >= 0; iDim--){
        array_data_index = d1[++array_md_index];
        dims[iDim] = child_count_array[array_data_index];
    }   
}
//=========================================================================
//---------------------   Empty Array Parsing  ----------------------------
//=========================================================================
mxArray* parse_empty_numeric_array(mwSize *dims, int array_size){
    
    if (array_size > MAX_ARRAY_DIMS){
        mexErrMsgIdAndTxt("turtle_json:max_nd_array_depth",
                "The maximum nd array depth depth was exceeded");
    }
    
    for (int iDim = 0; iDim < array_size; iDim++){
        dims[iDim] = 0;
    }
    
    return mxCreateNumericArray(array_size,dims,mxDOUBLE_CLASS,0);
}


//=========================================================================
//=========================================================================
//---------------       Numerical Array Parsing         -------------------
//=========================================================================
mxArray* parse_1d_numeric_array_row_major(int *d1, double *numeric_data, 
        int array_size, int array_md_index){
    
    int first_numeric_md_index = array_md_index + 1;
    int first_numeric_data_index = d1[first_numeric_md_index];
    
    mxArray *output = mxCreateNumericMatrix(1,0,mxDOUBLE_CLASS,0);

    double *temp_value = mxMalloc(array_size*sizeof(double));
    memcpy(temp_value,&numeric_data[first_numeric_data_index],array_size*sizeof(double));
    mxSetData(output,temp_value);
	mxSetN(output,array_size);
    
    return output;
}

mxArray* parse_1d_numeric_array_column_major(int *d1, double *numeric_data, 
        int array_size, int array_md_index){
    
    int first_numeric_md_index = array_md_index + 1;
    int first_numeric_data_index = d1[first_numeric_md_index];
    
    mxArray *output = mxCreateNumericMatrix(0,1,mxDOUBLE_CLASS,0);

    double *temp_value = mxMalloc(array_size*sizeof(double));
    memcpy(temp_value,&numeric_data[first_numeric_data_index],array_size*sizeof(double));
    mxSetData(output,temp_value);
	mxSetM(output,array_size);
    
    return output;
}

mxArray* parse_nd_numeric_array_column_major(int *d1, mwSize *dims, 
        int *child_count_array, double *numeric_data, int array_md_index, 
        uint8_t *array_depths, int *next_sibling_index_array){
    
    int array_data_index = d1[array_md_index];
    int array_depth = array_depths[array_data_index];
    
    //TODO: We could avoid this check if we allocated 'dims' based on the max
    //TODO: Alternatively, we could allocate this permanently for mex
    //and recycle between mex calls
    
    if (array_depth > MAX_ARRAY_DIMS){
        mexErrMsgIdAndTxt("turtle_json:max_nd_array_depth",
                "The maximum nd array depth depth was exceeded");
    }
    
    //The -1 is for previous value before the next sibling
    // "my_data": [[1,2],[3,4],[5,6]], "next_data": ...
    //            s                    n   (s start, n next)
    //                            ^ => (n - 1)
    int last_numeric_md_index  = next_sibling_index_array[array_data_index]-1;
    //
    // [ [ [ 23, 15 ], [ ...
    // s   
    // 0 1 2 3  <= indices
    // 3 2 1    <= array depths
    //       ^ => (s + array_depth[s])
    int first_numeric_md_index = array_md_index + array_depth;
    int first_numeric_data_index = d1[first_numeric_md_index];
    
    int n_numbers = d1[last_numeric_md_index] - first_numeric_data_index + 1;
    
    double *data = mxMalloc(n_numbers*sizeof(double));
    memcpy(data,&numeric_data[first_numeric_data_index],n_numbers*sizeof(double));
    
    populate_dims__column_major(dims, d1, child_count_array, array_data_index, array_md_index, array_depth);
    
    mxArray *output = mxCreateNumericArray(0,0,mxDOUBLE_CLASS,0);
    mxSetData(output,data);
    mxSetDimensions(output,dims,array_depth);
    return output;
}

mxArray* parse_nd_numeric_array_row_major(int *d1, mwSize *dims, 
        int *child_count_array, double *numeric_data, int array_md_index, 
        uint8_t *array_depths, int *next_sibling_index_array){
    
	mxArray* temp_array = parse_nd_numeric_array_column_major(d1, 
            dims, child_count_array, numeric_data, array_md_index, 
            array_depths, next_sibling_index_array);
    
    int array_data_index = d1[array_md_index];
    int array_depth = array_depths[array_data_index];
    
    return permuteArray(temp_array, array_depth);
    
   
}

//Old version, may incorporate into new version eventually ...

// // // mxArray* parse_nd_numeric_array_row_major(int *d1, mwSize *dims, 
// // //         int *child_count_array, double *numeric_data, int array_md_index, 
// // //         uint8_t *array_depths, int *next_sibling_index_array){
// // //     
// // //     int array_data_index = d1[array_md_index];
// // //     int array_depth = array_depths[array_data_index];
// // //     
// // //     //TODO: We could avoid the check below if we allocated 'dims' based on the max
// // //     //TODO: Alternatively, we could allocate this permanently for mex
// // //     //and recycle between mex calls - I think this is the better option ...
// // //     
// // //     if (array_depth > MAX_ARRAY_DIMS){
// // //         mexErrMsgIdAndTxt("turtle_json:max_nd_array_depth","The maximum nd array depth depth was exceeded");
// // //     }
// // //     
// // //     //The -1 is for previous value before the next sibling
// // //     // "my_data": [[1,2],[3,4],[5,6]], "next_data": ...
// // //     //            s                    n   (s start, n next)
// // //     //                            ^ => (n - 1)
// // //     int last_numeric_md_index  = next_sibling_index_array[array_data_index] - 1;
// // //     //
// // //     // [ [ [ 23, 15 ], [ ...
// // //     // s   
// // //     // 0 1 2 3  <= indices
// // //     // 3 2 1    <= array depths
// // //     //       ^ => (s + array_depth[s])
// // //     int first_numeric_md_index = array_md_index + array_depth;
// // //     int first_numeric_data_index = d1[first_numeric_md_index];
// // //     
// // //     int n_numbers = d1[last_numeric_md_index] - first_numeric_data_index + 1;
// // //     
// // //     double *data = mxMalloc(n_numbers*sizeof(double));
// // //     double *data_start = data;
// // //     
// // //     populate_dims__row_major(dims, d1, child_count_array, array_data_index, array_md_index, array_depth);
// // //         
// // //     int n_rows;
// // //     int n_columns;
// // //     int n_pages;
// // //     
// // //     double *source_data = &numeric_data[first_numeric_data_index];
// // //     //Looping offsets
// // //     // - let's say we have an array of size [5 7 6]
// // //     switch (array_depth) {
// // //         case 0:
// // //             mexErrMsgIdAndTxt("turtle_json:code_error","0d numeric array not supported for nd-array");
// // //             break;  
// // //         case 1:
// // //             mexErrMsgIdAndTxt("turtle_json:code_error","1d numeric array not supported for nd-array");
// // //             break;
// // //         case 2:
// // //             n_rows = dims[0];
// // //             n_columns = dims[1];
// // //             for (int col = 0; col < n_columns; col++){
// // //                 for (int row = 0; row < n_rows; row++){
// // //                     *data = source_data[col + row*n_columns];
// // //                     data++;
// // //                 }
// // //             }
// // //             break;
// // //         case 3:
// // //             n_rows = dims[0];
// // //             n_columns = dims[1];
// // //             n_pages = dims[2];
// // //             for (int page = 0; page < n_pages; page++){
// // //                 for (int col = 0; col < n_columns; col++){
// // //                     for (int row = 0; row < n_rows; row++){
// // //                         *data = source_data[page + col*n_pages + row*n_columns*n_pages];
// // //                         data++;
// // //                     }
// // //                 }
// // //             }
// // //             break;
// // //         default:
// // //             //   permuted_data = permute(data,reversed_dims)
// // //             //
// // //             //int mexCallMATLAB(int nlhs, mxArray *plhs[], int nrhs, 
// // //             //              mxArray *prhs[], const char *functionName);
// // //             mexErrMsgIdAndTxt("turtle_json:code_error","greater than 3d array not yet handled");
// // //     }
// // //             
// // //     mxArray *output = mxCreateNumericArray(0,0,mxDOUBLE_CLASS,0);
// // //     mxSetData(output,data_start);
// // //     mxSetDimensions(output,dims,array_depth);
// // //     return output;
// // // }




//---------------     Logical Array Parsing        -------------------
//=========================================================================
mxArray* parse_1d_logical_array_row_major(int *d1, uint8_t *types, 
        int array_size, int array_md_index){

    int md_index = array_md_index + 1;
    
    uint8_t *data = mxMalloc(array_size*sizeof(uint8_t));
    for (int iElem = 0; iElem < array_size; iElem++){
        data[iElem] = types[md_index] == TYPE_TRUE;
        md_index++;
    }
    
    mxArray *output = mxCreateLogicalMatrix(1,0);
    mxSetData(output,data);
    mxSetN(output,array_size);
    return output;
}

mxArray* parse_1d_logical_array_column_major(int *d1, uint8_t *types, 
        int array_size, int array_md_index){

    int md_index = array_md_index + 1;
    
    uint8_t *data = mxMalloc(array_size*sizeof(uint8_t));
    
    for (int iElem = 0; iElem < array_size; iElem++){
        data[iElem] = types[md_index] == TYPE_TRUE;
        md_index++;
    }
    
    mxArray *output = mxCreateLogicalMatrix(0,1);
    mxSetData(output,data);
    mxSetM(output,array_size);
    return output;
}

mxArray* parse_nd_logical_array_column_major(int *d1, uint8_t *types, mwSize *dims, 
        int *child_count_array, int array_md_index, uint8_t *array_depths, 
        int *next_sibling_index_array){

    int array_data_index = d1[array_md_index];
    int array_depth = array_depths[array_data_index];
    
    populate_dims__column_major(dims, d1, child_count_array, array_data_index, array_md_index, array_depth);

    //See explanation in parse_nd_numeric_array
    int last_logical_md_index  = next_sibling_index_array[array_data_index]-1;
    int first_logical_md_index = array_md_index + array_depth;
    int first_logical_count = d1[first_logical_md_index];
    int last_logical_count = d1[last_logical_md_index];
    
    int n_values = last_logical_count - first_logical_count + 1;
    
    uint8_t *data = mxMalloc(n_values*sizeof(uint8_t));
    
    int iData = 0;
    for (int iType = first_logical_md_index; iType <= last_logical_md_index; iType++){
        if (types[iType] != TYPE_ARRAY){
            data[iData] = types[iType] == TYPE_TRUE;
            iData++;
        }
    }
    
    mxArray *output = mxCreateLogicalArray(0,0);
    mxSetData(output,data);
    mxSetDimensions(output,dims,array_depth);
    return output;    
}


mxArray* parse_nd_logical_array_row_major(int *d1, uint8_t *types, mwSize *dims, 
        int *child_count_array, int array_md_index, uint8_t *array_depths, 
        int *next_sibling_index_array){

    mxArray* temp_array = parse_nd_logical_array_column_major(d1, types, 
            dims, child_count_array, array_md_index, array_depths, 
            next_sibling_index_array);
    
    
    int array_data_index = d1[array_md_index];
    int array_depth = array_depths[array_data_index];
    
    return permuteArray(temp_array, array_depth);
}


//---------------     String Array Parsing        -------------------
//=========================================================================
mxArray* parse_1d_string_array_column_major(int *d1, int array_size, int array_md_index, mxArray *strings){
    mxArray *output = mxCreateCellMatrix(array_size,1);
    int string_md_index = array_md_index + 1;
    int string_data_index = d1[string_md_index];
    for (int iData = 0; iData < array_size; iData++){
        mxSetCell(output, iData, mxCreateReference(mxGetCell(strings,string_data_index)));
        string_data_index++;
    }
    return output;
}

mxArray* parse_1d_string_array_row_major(int *d1, int array_size, int array_md_index, mxArray *strings){
    mxArray *output = mxCreateCellMatrix(1,array_size);
    int string_md_index = array_md_index + 1;
    int string_data_index = d1[string_md_index];
    for (int iData = 0; iData < array_size; iData++){
        mxSetCell(output, iData, mxCreateReference(mxGetCell(strings,string_data_index)));
        string_data_index++;
    }
    return output;
}

mxArray* parse_nd_string_array_column_major(int *d1, mwSize *dims, 
        int *child_count_array, int array_md_index, uint8_t *array_depths, 
        int *next_sibling_index_array, mxArray *strings){
    
    //[["a","b"],["c","d"]]

    int array_data_index = d1[array_md_index];
    int array_depth = array_depths[array_data_index];
    
    populate_dims__column_major(dims, d1, child_count_array, array_data_index, array_md_index, array_depth);
    
    //See explanation in parse_nd_numeric_array
    int last_string_md_index  = next_sibling_index_array[array_data_index]-1;
    int first_string_md_index = array_md_index + array_depth;
    int first_string_data_index = d1[first_string_md_index];
    
    int n_strings = d1[last_string_md_index] - first_string_data_index + 1;
    
    //mexPrintf("n_strings: %d\n",n_strings);
    
    mxArray *output = mxCreateCellArray(array_depth,dims);
    int string_data_index = first_string_data_index;
    for (int iString = 0; iString < n_strings; iString++){
        mxSetCell(output,iString,mxCreateReference(mxGetCell(strings,string_data_index)));
        string_data_index++;
    }
    return output;    
}

mxArray* parse_nd_string_array_row_major(int *d1, mwSize *dims, 
        int *child_count_array, int array_md_index, uint8_t *array_depths, 
        int *next_sibling_index_array, mxArray *strings){
    
    //This doesn't work if we lose dimensions due to collapsing
    //i.e. if we have the following as column major for size
    //[9,1,1,1]
    //In Matlab once created we only have [9,1] 
    //Which then gets permuted to be [1,9]
    
    mxArray* temp_array = parse_nd_string_array_column_major(d1, dims, 
        child_count_array, array_md_index, array_depths, 
        next_sibling_index_array, strings);
   
    
    int array_data_index = d1[array_md_index];
    int array_depth = array_depths[array_data_index];
    
    return permuteArray(temp_array, array_depth);
}

//=========================================================================
//=========================================================================
//=========================================================================
mxArray *parse_array(Data data, int md_index){
    //
    //  This code handles parsing of a heterogenous array. It doesn't
    //  actual
    //
    //  See Also
    //  --------
    //  parse_non_homogenous_array
    //  parse_1d_array_column_major
    //  parse_cellstr
    //  parse_logical_array
    //  parse_nd_numeric_array
    //  parse_nd_string_array
    //  parse_logical_nd_array
    
    int cur_array_data_index = data.d1[md_index];
    mxArray *output;
        
    int temp_count;
    int temp_data_index;
    int temp_md_index;
    //int temp_array_depth;
    //mwSize *dims;
    double *temp_value;
    
    mxArray *temp_obj;
    
//     mexPrintf("md_index: %d\n",md_index);
//     mexPrintf("data_index: %d\n",cur_array_data_index);
//     mexPrintf("Type: %d\n",data.array_types[cur_array_data_index]);
    //return output;
    
    switch (data.array_types[cur_array_data_index]){
        case ARRAY_OTHER_TYPE:
            //  [1,false,"apples"]
            output = parse_non_homogenous_array(data, cur_array_data_index, md_index);     
            break;
        case ARRAY_NUMERIC_TYPE:
            //  [1,2,3,4]
            output = parse_1d_numeric_array_column_major(data.d1,data.numeric_data,
                    data.child_count_array[cur_array_data_index],md_index);
            break;
        case ARRAY_STRING_TYPE:
            //  ['cheese','crow']
            output = parse_1d_string_array_column_major(data.d1,
                    data.child_count_array[cur_array_data_index],
                    md_index,data.strings);
            break;
        case ARRAY_LOGICAL_TYPE:
            //  [true, false, true]
            output = parse_1d_logical_array_column_major(data.d1, data.types, 
                    data.child_count_array[cur_array_data_index], md_index);
            break;
        case ARRAY_OBJECT_SAME_TYPE:
            //  [{'a':1,'b':2},{'a':3,'b':4}]
            temp_md_index = md_index + 1;
            temp_data_index = data.d1[temp_md_index];
            temp_count = data.child_count_array[cur_array_data_index];
            output = get_initialized_struct(data,temp_data_index,temp_count);
            for (int iObj = 0; iObj < temp_count; iObj++){
                parse_object(data, output, iObj, temp_md_index);
                temp_md_index = data.next_sibling_index_object[temp_data_index];
                temp_data_index = data.d1[temp_md_index];
            }
            break;
        case ARRAY_OBJECT_DIFF_TYPE:
            //  [{'a':1,'b':2},{'c':3,'a':4}]
            temp_count = data.child_count_array[cur_array_data_index];
            output = mxCreateCellMatrix(1,temp_count);
            temp_md_index = md_index + 1;
            for (int iData = 0; iData < temp_count; iData++){
                temp_data_index = data.d1[temp_md_index];
                temp_obj = get_initialized_struct(data,temp_data_index,1);
                parse_object(data, temp_obj, 0, temp_md_index);
                mxSetCell(output,iData,temp_obj);
                temp_md_index = data.next_sibling_index_object[temp_data_index];
            }
            break;
        case ARRAY_ND_NUMERIC:
            output = parse_nd_numeric_array_column_major(data.d1, data.dims, 
                    data.child_count_array, data.numeric_data, md_index, 
                    data.array_depths, data.next_sibling_index_array);
            break;
        case ARRAY_ND_STRING:
            output = parse_nd_string_array_column_major(data.d1, data.dims, 
                        data.child_count_array, md_index, data.array_depths,
                        data.next_sibling_index_array, data.strings);
            break;
        case ARRAY_ND_LOGICAL:
            output = parse_nd_logical_array_column_major(data.d1, data.types, data.dims, 
                    data.child_count_array, md_index, data.array_depths, 
                    data.next_sibling_index_array);
            break;
        case ARRAY_EMPTY_TYPE:
        case ARRAY_ND_EMPTY:
            output = parse_empty_numeric_array(data.dims, data.child_count_array[cur_array_data_index]);
            break;
            
    }
    return output;
}
//=========================================================================
//=========================================================================
mxArray *parse_array_with_options(Data data, int md_index, 
        FullParseOptions *options){
    //
    //  This code handles parsing of a heterogenous array. It doesn't
    //  actual
    //
    //  See Also
    //  --------
    //  parse_non_homogenous_array
    //  parse_1d_array
    //  parse_cellstr
    //  parse_logical_array
    //  parse_nd_numeric_array
    //  parse_nd_string_array
    //  parse_logical_nd_array
        
    int cur_array_data_index = data.d1[md_index];
    mxArray *output;
    
    bool collapse_objects;
    
    int n_dimensions;
    int temp_count;
    int temp_data_index;
    int temp_md_index;
    int temp_array_depth;
    mwSize *dims;
    double *temp_value;
    uint8_t *types;
    
    mxArray *temp_obj;
    
    //mexPrintf("type: %d\n",data.array_types[cur_array_data_index]);
    
    switch (data.array_types[cur_array_data_index]){
        case ARRAY_OTHER_TYPE:
            //  [1,false,"apples"]
            output = parse_non_homogenous_array_with_options(data, cur_array_data_index, md_index, options);     
            break;
        case ARRAY_NUMERIC_TYPE:
            //  [1,2,3,4]
            n_dimensions = data.array_depths[cur_array_data_index];
            if (options->max_numeric_collapse_depth == -1 || options->max_numeric_collapse_depth >= n_dimensions){
                if (options->column_major){
                    output = parse_1d_numeric_array_column_major(data.d1,data.numeric_data,
                                data.child_count_array[cur_array_data_index],md_index);
                }else{
                    output = parse_1d_numeric_array_row_major(data.d1,data.numeric_data,
                                data.child_count_array[cur_array_data_index],md_index);
                }
            }else{
                temp_count = data.child_count_array[cur_array_data_index];                
                output = mxCreateCellMatrix(1,temp_count);
                
                temp_md_index = md_index + 1;
                temp_data_index = data.d1[temp_md_index];
                temp_value = &(data.numeric_data[temp_data_index]);
                //Note, since we have a homogenous array we don't need
                //to go back to the md_index, we can just increment ...
                for (int iData = 0; iData < temp_count; iData++){
                    temp_obj = mxCreateDoubleScalar(*temp_value);
                    mxSetCell(output,iData,temp_obj);
                    temp_value++;
                }
            }
            break;
        case ARRAY_STRING_TYPE:
            //  ['cheese','crow']
            //  Note that not collapsing here doesn't make any sense
            // as all elements go in a cell regardless of options
            output = parse_1d_string_array_column_major(data.d1,
                    data.child_count_array[cur_array_data_index],
                    md_index,data.strings);
            break;
        case ARRAY_LOGICAL_TYPE:
            n_dimensions = data.array_depths[cur_array_data_index];
            if (options->max_bool_collapse_depth == -1 || options->max_bool_collapse_depth >= n_dimensions){
                if (options->column_major){
                    output = parse_1d_logical_array_column_major(data.d1, data.types, 
                            data.child_count_array[cur_array_data_index], md_index);
                }else{
                    output = parse_1d_logical_array_row_major(data.d1, data.types, 
                            data.child_count_array[cur_array_data_index], md_index);
                }
            }else{
                temp_count = data.child_count_array[cur_array_data_index];                
                output = mxCreateCellMatrix(1,temp_count);

                temp_md_index = md_index + 1;
                types = &(data.types[temp_md_index]);
                for (int iData = 0; iData < temp_count; iData++){
                    temp_obj = mxCreateLogicalScalar(*types == TYPE_TRUE);
                    mxSetCell(output,iData,temp_obj);
                    types++;
                }
            }
    
//             //  [true, false, true]
//             output = parse_1d_logical_array_column_major(data.d1, data.types, 
//                     data.child_count_array[cur_array_data_index], md_index);
            break;
        case ARRAY_OBJECT_SAME_TYPE:
        case ARRAY_OBJECT_DIFF_TYPE:    
            collapse_objects = options->collapse_objects && 
                    ARRAY_OBJECT_SAME_TYPE == data.array_types[cur_array_data_index];
            
            
            temp_md_index = md_index + 1;
            temp_count = data.child_count_array[cur_array_data_index];
            
            if (collapse_objects){
                //In this case the output is a structure array
                temp_data_index = data.d1[temp_md_index];
                output = get_initialized_struct(data,temp_data_index,temp_count);
                for (int iObj = 0; iObj < temp_count; iObj++){
                    parse_object_with_options(data, output, iObj, temp_md_index, options);
                    temp_md_index = data.next_sibling_index_object[temp_data_index];
                    temp_data_index = data.d1[temp_md_index];
                }

            }else{
                //In this case the output is a cell array
                output = mxCreateCellMatrix(1,temp_count);
                for (int iData = 0; iData < temp_count; iData++){
                    temp_data_index = data.d1[temp_md_index];
                    temp_obj = get_initialized_struct(data,temp_data_index,1);
                    parse_object_with_options(data, temp_obj, 0, temp_md_index, options);
                    mxSetCell(output,iData,temp_obj);
                    temp_md_index = data.next_sibling_index_object[temp_data_index];
                }
            }
            break;
        case ARRAY_ND_NUMERIC:
            n_dimensions = data.array_depths[cur_array_data_index];
            //mexPrintf("option: %d\n",options->max_numeric_collapse_depth);
            //mexPrintf("n_dimensions: %d\n",n_dimensions);
            
            if (options->max_numeric_collapse_depth == -1 || options->max_numeric_collapse_depth >= n_dimensions){
                if (options->column_major){
                    output = parse_nd_numeric_array_column_major(data.d1, data.dims, 
                            data.child_count_array, data.numeric_data, md_index, 
                            data.array_depths, data.next_sibling_index_array);
                }else{
                    output = parse_nd_numeric_array_row_major(data.d1, data.dims, 
                        data.child_count_array, data.numeric_data, md_index, 
                        data.array_depths, data.next_sibling_index_array);
                }
            }else{
                //Options specify not to collapse, so instead we
                //loop over each sub-array and parse it, populating 
                //this array as a cell array
                temp_count = data.child_count_array[cur_array_data_index];
                
                //Should this be many rows or columns? Leaving as rows
                //for now ... 
                //
                //We might want a 1d array shape preference ...
                output = mxCreateCellMatrix(1,temp_count);
                temp_md_index = md_index + 1;
                for (int iData = 0; iData < temp_count; iData++){
                    temp_data_index = data.d1[temp_md_index];
                    temp_obj = parse_array_with_options(data, temp_md_index, options);
                    mxSetCell(output,iData,temp_obj);
                    temp_md_index = data.next_sibling_index_array[temp_data_index];
                }
            }
            break;
        case ARRAY_ND_STRING:
            n_dimensions = data.array_depths[cur_array_data_index];
            
          	if (options->max_string_collapse_depth == -1 || options->max_string_collapse_depth >= n_dimensions){
                if (options->column_major){
                    output = parse_nd_string_array_column_major(data.d1, data.dims, 
                        data.child_count_array, md_index, data.array_depths,
                        data.next_sibling_index_array, data.strings);
                }else{
                    output = parse_nd_string_array_row_major(data.d1, data.dims, 
                        data.child_count_array, md_index, data.array_depths,
                        data.next_sibling_index_array, data.strings);
                }
            }else{
                //Options specify not to collapse, so instead we
                //loop over each sub-array and parse it, populating 
                //this array as a cell array
                
                //TODO: Ideally this should be a function since it is shared
                //by number and bool
                temp_count = data.child_count_array[cur_array_data_index];
                output = mxCreateCellMatrix(1,temp_count);
                temp_md_index = md_index + 1;
                for (int iData = 0; iData < temp_count; iData++){
                    temp_data_index = data.d1[temp_md_index];
                    temp_obj = parse_array_with_options(data, temp_md_index, options);
                    mxSetCell(output,iData,temp_obj);
                    temp_md_index = data.next_sibling_index_array[temp_data_index];
                }
            }
            break;
        case ARRAY_ND_LOGICAL:
          	n_dimensions = data.array_depths[cur_array_data_index];
            
          	if (options->max_bool_collapse_depth == -1 || options->max_bool_collapse_depth >= n_dimensions){
                if (options->column_major){
                    output = parse_nd_logical_array_column_major(data.d1, data.types, data.dims, 
                        data.child_count_array, md_index, data.array_depths, 
                        data.next_sibling_index_array);
                }else{
                    output = parse_nd_logical_array_row_major(data.d1, data.types, data.dims, 
                        data.child_count_array, md_index, data.array_depths, 
                        data.next_sibling_index_array);
                }
            }else{
                //Options specify not to collapse, so instead we
                //loop over each sub-array and parse it, populating 
                //this array as a cell array
                
                //TODO: Ideally this should be a function since it is shared
                //by number and string
                temp_count = data.child_count_array[cur_array_data_index];
                output = mxCreateCellMatrix(1,temp_count);
                temp_md_index = md_index + 1;
                for (int iData = 0; iData < temp_count; iData++){
                    temp_data_index = data.d1[temp_md_index];
                    temp_obj = parse_array_with_options(data, temp_md_index, options);
                    mxSetCell(output,iData,temp_obj);
                    temp_md_index = data.next_sibling_index_array[temp_data_index];
                }
            }     
            break;
        case ARRAY_EMPTY_TYPE:
        case ARRAY_ND_EMPTY:
            output = parse_empty_numeric_array(data.dims, data.child_count_array[cur_array_data_index]);
            break;
            
    }
    return output;
} //end parse_array_with_options()
//=========================================================================
//=========================================================================
mxArray* parse_non_homogenous_array(Data data, int array_data_index, int array_md_index){

    //This is the "messiest" array option of all. Since we need to go through item
    //by item and parse the result ...
    int array_size = data.child_count_array[array_data_index];
    mxArray* output = mxCreateCellMatrix(1,array_size);

    int current_md_index = array_md_index + 1;
    int current_data_index;
    for (int iData = 0; iData < array_size; iData++){
        switch (data.types[current_md_index]){
            case TYPE_OBJECT:
                current_data_index = data.d1[current_md_index];
                mxArray* temp_obj = get_initialized_struct(data,current_data_index,1);
                parse_object(data, temp_obj, 0, current_md_index);
                mxSetCell(output,iData,temp_obj);
                current_md_index = data.next_sibling_index_object[current_data_index];
                break;
            case TYPE_ARRAY:
                current_data_index = data.d1[current_md_index];
                mxSetCell(output, iData, parse_array(data,current_md_index));
                current_md_index = data.next_sibling_index_array[current_data_index];
                break;
            case TYPE_KEY:
                mexErrMsgIdAndTxt("turtle_json:code_error",
                        "Found key type as child of array");
                break;
            case TYPE_STRING:
                mxSetCell(output, iData, getString(data.d1,data.strings,current_md_index));
                current_md_index++;
                break;
            case TYPE_NUMBER:
                mxSetCell(output, iData, getNumber(data,current_md_index));
                current_md_index++;
                break;
            case TYPE_NULL:
                mxSetCell(output, iData, getNull(data,current_md_index));
                current_md_index++;
                break;
            case TYPE_TRUE:
                mxSetCell(output, iData, getTrue(data,current_md_index));
                current_md_index++;
                break;
            case TYPE_FALSE:
                mxSetCell(output, iData, getFalse(data,current_md_index));
                current_md_index++;
                break;
        }
    }   
    return output;
}

mxArray* parse_non_homogenous_array_with_options(Data data, int array_data_index, 
        int array_md_index, FullParseOptions *options){

    //This is the "messiest" array option of all. Since we need to go through item
    //by item and parse the result ...
    int array_size = data.child_count_array[array_data_index];
    mxArray* output = mxCreateCellMatrix(1,array_size);

    //[1,"test",{"cheese":3}]
    
    int current_md_index = array_md_index + 1;
    int current_data_index;
    for (int iData = 0; iData < array_size; iData++){
        switch (data.types[current_md_index]){
            case TYPE_OBJECT:
                current_data_index = data.d1[current_md_index];
                mxArray* temp_obj = get_initialized_struct(data,current_data_index,1);
                //Currently no options for an object
                parse_object(data, temp_obj, 0, current_md_index);
                mxSetCell(output,iData,temp_obj);
                current_md_index = data.next_sibling_index_object[current_data_index];
                break;
            case TYPE_ARRAY:
                current_data_index = data.d1[current_md_index];
                mxSetCell(output, iData, 
                        parse_array_with_options(data,current_md_index,options));
                current_md_index = data.next_sibling_index_array[current_data_index];
                break;
            case TYPE_KEY:
                mexErrMsgIdAndTxt("turtle_json:code_error",
                        "Found key type as child of array");
                break;
            case TYPE_STRING:
                mxSetCell(output, iData, getString(data.d1,data.strings,current_md_index));
                current_md_index++;
                break;
            case TYPE_NUMBER:
                mxSetCell(output, iData, getNumber(data,current_md_index));
                current_md_index++;
                break;
            case TYPE_NULL:
                mxSetCell(output, iData, getNull(data,current_md_index));
                current_md_index++;
                break;
            case TYPE_TRUE:
                mxSetCell(output, iData, getTrue(data,current_md_index));
                current_md_index++;
                break;
            case TYPE_FALSE:
                mxSetCell(output, iData, getFalse(data,current_md_index));
                current_md_index++;
                break;
        }
    }   
    return output;
}

