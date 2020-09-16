#include "turtle_json.h"
#include "json_info_to_data.h"

//-------------------------------------------------------------------------
//  
//  Functions:
//  

//-------------------------------------------------------------------------

mwSize *dims_file_scope[MAX_DEPTH_ARRAY_LENGTH_BYTES]; //= mxMalloc(MAX_DEPTH_ARRAY_LENGTH_BYTES);

Data populate_data(const mxArray *s){
    
    Data data;
    
    //Main Data -----------------------------------------------------------
    int n_md_values;
    data.types = get_u8_field_safe(s,"types");
    data.d1 = get_int_field_and_length_safe(s,"d1",&n_md_values);
    data.n_md_values = n_md_values;
    
    //Object Data  --------------------------------------------------------
    const mxArray *object_info = s; //mxGetField(s,0,"object_info");
    int n_objects;
    data.object_ids = get_int_field_and_length_safe(object_info,"obj__object_ids",&n_objects);
    
    if (n_objects){
        data.child_count_object = get_int_field_safe(object_info,"obj__child_count_object");
        data.next_sibling_index_object = get_int_field_safe(object_info,"obj__next_sibling_index_object");
        data.objects = get_mx_field_safe(object_info,"obj__objects");
        const mxArray *key_info = s;
        data.next_sibling_index_key = get_int_field_safe(key_info,"key__next_sibling_index_key");
    }
    
    //Array Data  ---------------------------------------------------------
    const mxArray *array_info = s;
    data.child_count_array = get_int_field_safe(array_info,"arr__child_count_array");
    data.next_sibling_index_array = get_int_field_safe(array_info,"arr__next_sibling_index_array");
    data.array_types = get_u8_field_safe(array_info,"arr__array_types");
    data.array_depths = get_u8_field_safe(array_info,"arr__array_depths");
    
    //String Data --------------------------
    data.strings = get_mx_field_safe(s,"strings");
    
    data.dims = dims_file_scope;
    
    //Numeric Data -------------------------
    data.numeric_data = (double *)mxGetData(mxGetField(s,0,"numeric_p"));
    
    return data;
    
} //end populate_data()
//-------------------------------------------------------------------------

//0 =======================================================================
void f0__full_parse(int nlhs, mxArray *plhs[], int nrhs, const mxArray*prhs[]){
    //
    //  data = json_info_to_data(0, mex_struct, md_index_1b)
    //
    //  Inputs
    //  -----------------------
    //  struct mex_struct
    //  double md_index_1b
        
    if (nrhs != 3){
        mexErrMsgIdAndTxt("turtle_json:invalid_input",
                "json_info_to_data.f0__full_parse requires 3 inputs");
    }else if (!mxIsClass(prhs[1],"struct")){
        mexErrMsgIdAndTxt("turtle_json:invalid_input",
                "2nd input to json_info_to_data.f0__full_parse needs to be a structure");
    }else if (!mxIsClass(prhs[2],"double")){
        mexErrMsgIdAndTxt("turtle_json:invalid_input",
                "3rd input to json_info_to_data.f0__full_parse needs to be a double");
    }
    
    if (nlhs != 1){
        mexErrMsgIdAndTxt("turtle_json:invalid_output",
                "json_info_to_data.f0 requires 1 output");
    }
    
    const mxArray *s = prhs[1];
    int md_index = ((int) mxGetScalar(prhs[2]))-1;
    
    Data data = populate_data(s);
    
    if (md_index < 0 || md_index >= data.n_md_values){
        mexErrMsgIdAndTxt("turtle_json:invalid_input","md_index out of range for f0");
    }
    
    if (data.types[md_index] == TYPE_KEY){
        //We'll return what the key points to
        ++md_index;
    }
    
    int data_index;
    switch (data.types[md_index]){
        case TYPE_OBJECT:
            data_index = data.d1[md_index];
            plhs[0] = get_initialized_struct(data, data_index, 1);
            parse_object(data, plhs[0], 0, md_index);
            break;
        case TYPE_ARRAY:
            plhs[0] = parse_array(data, md_index);
            break;
        case TYPE_KEY:
            //We should already check against this ...
            mexErrMsgIdAndTxt("turtle_json:code_error","key child of key found, code error made somewhere");
            break;
        case TYPE_STRING:
            plhs[0] = getString(data.d1,data.strings,md_index);
            break;
        case TYPE_NUMBER:
            plhs[0] = getNumber(data,md_index);
            break;
        case TYPE_NULL:
            plhs[0] = getNull(data,md_index);
            break;
        case TYPE_TRUE:
            plhs[0] = getTrue(data,md_index);
            break;
        case TYPE_FALSE:
            plhs[0] = getFalse(data,md_index);
            break;
    }
}

//=========================================================================
void f1__get_key_index(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]){
    //
    //  index_1b = json_info_to_data(1, mex_struct, obj_md_index, key_name)
    //
    //  Given an object and a key name, get the index of the key in the
    //  object. An additional check is made to verify that the key is
    //  in the object.
    //
    //  Inputs
    //  ---------------------
    //  struct mex_struct
    //  double obj_md_index
    //  char   key_name
    //
    //  Outputs
    //  ----------------------
    //  double index_1b
    //      The index of the specified key in the object. If the specified
    //      key does not exist, an error is thrown:
    //          ID: "turtle_json:invalid_key_for_object"
    //
    //  Inputs: object, key name
    //  Returns: the index of the key in the object
    //
    //      Note, this function also tests that the key exists. If it
    //      doesn't it throws an error.
    //
    //
    //  Given an object and a key name, get the key index. We also check
    //  that the key exists.
    //
    //
    
    if (nrhs != 4){
        mexErrMsgIdAndTxt("turtle_json:invalid_input",
                "json_info_to_data.f1__get_key_index requires at four inputs");
    }else if (!mxIsClass(prhs[1],"struct")){
        mexErrMsgIdAndTxt("turtle_json:invalid_input",
                "2nd input to json_info_to_data.f1__get_key_index needs to be a structure");
    }else if (!mxIsClass(prhs[2],"double")){
        mexErrMsgIdAndTxt("turtle_json:invalid_input",
                "3rd input to json_info_to_data.f1__get_key_index needs to be a double");
    }else if (!mxIsClass(prhs[3],"char")){
        mexErrMsgIdAndTxt("turtle_json:invalid_input",
                "4th input to json_info_to_data.f1__get_key_index needs to be a char");
    }
    
    if (nlhs != 1){
        mexErrMsgIdAndTxt("turtle_json:invalid_output",
                "json_info_to_data.f1__get_key_index requires 1 output");
    }
    
    const mxArray *mex_input = prhs[1];
    
    //Validation of specifics for md_index
    //---------------------------------------------------------------------
    //The following code could be made into a generic validator for
    //and input md_index that is supposed to be an object ...
    //-1 from 1b to 0b
    int object_md_index = ((int)mxGetScalar(prhs[2])) - 1;
    int n_values;
    int *d1 = get_int_field_and_length_safe(mex_input,"d1",&n_values);
    uint8_t *types = get_u8_field_safe(mex_input,"types");
    
    if (object_md_index < 0 || object_md_index >= n_values){
        mexErrMsgIdAndTxt("turtle_json:invalid_input",
                "md_index input is out of range for f1__get_key_index");
    }else if (types[object_md_index] != TYPE_OBJECT){
        mexErrMsgIdAndTxt("turtle_json:invalid_input",
                "md_index input is not an object for f1__get_key_index");
    }
    
    //The actual finding of the key
    //---------------------------------------------------------------------
    int object_data_index = d1[object_md_index];
    const mxArray *object_info = mex_input;
    int *object_ids = get_int_field_safe(object_info,"obj__object_ids");
    int object_id = object_ids[object_data_index];
    const mxArray *objects = get_mx_field_safe(object_info,"obj__objects");
    mxArray *s = mxGetCell(objects,object_id);
    
    char *field_name = mxArrayToString(prhs[3]);
    //+1 to make 1b
    int index_1b = mxGetFieldNumber(s,field_name)+1;
    mxFree(field_name);
    
    if (index_1b == 0){
        mexErrMsgIdAndTxt("turtle_json:invalid_key_for_object",
                "the specified key is not a member of the specified object");
    }
    
    set_double_output(&plhs[0],(double)index_1b);
}

//=========================================================================
void f2__get_key_value_type_and_index(int nlhs, mxArray *plhs[], int nrhs, const mxArray*prhs[]){
    //
    //   [key_value_type,md_index_1b] = json_info_to_data(2,mex_struct,obj_md_index,key_index_1b)
    //
    //
    //   Inputs
    //   ------
    //   double obj_index_1b :
    //   double key_index_1b :  
    //
    //   Given an object and key index, return:
    //   1) the type of the key value, e.g. string, number, array, etc.
    //   2) the unique md_index (1 based) for the key value - note this is 
    //      different than the key index
    //
    //   See Also
    //  ----------
    //
    
    if (nrhs != 4){
        mexErrMsgIdAndTxt("turtle_json:invalid_input",
                "json_info_to_data.f2__get_key_value_type_and_index requires 4 inputs");
    }else if (!mxIsClass(prhs[1],"struct")){
        mexErrMsgIdAndTxt("turtle_json:invalid_input",
                "2nd input to json_info_to_data.f2__get_key_value_type_and_index needs to be a structure");
    }else if (!mxIsClass(prhs[2],"double")){
        mexErrMsgIdAndTxt("turtle_json:invalid_input",
                "3rd input to json_info_to_data.f2__get_key_value_type_and_index needs to be a double");
    }else if (!mxIsClass(prhs[3],"double")){
        mexErrMsgIdAndTxt("turtle_json:invalid_input",
                "4th input to json_info_to_data.f2__get_key_value_type_and_index needs to be a double");
    }
    
    if (nlhs != 2){
        mexErrMsgIdAndTxt("turtle_json:invalid_output",
                "json_info_to_data.getKeyIndex requires 2 output");
    }
    
    const mxArray *mex_input = prhs[1];
    
    //Object MD Retrieval and Validation
    //---------------------------------------------------------------------
    int object_md_index = ((int)mxGetScalar(prhs[2])) - 1;
    int n_values;
    int *d1 = get_int_field_and_length_safe(mex_input,"d1",&n_values);
    uint8_t *types = get_u8_field_safe(mex_input,"types");
    
    if (object_md_index < 0 || object_md_index >= n_values){
        mexErrMsgIdAndTxt("turtle_json:invalid_input",
                "object_md_index input is out of range for f2__get_key_value_type_and_index");
    }else if (types[object_md_index] != TYPE_OBJECT){
        mexErrMsgIdAndTxt("turtle_json:invalid_input",
                "object_md_index input is not an object for f2__get_key_value_type_and_index");
    }
    
    //Object Info Setup
    //-----------------------------------------------------------
    int object_data_index = d1[object_md_index];
    const mxArray *object_info = mex_input; //mxGetField(mex_input,0,"object_info");
    int *object_counts = get_int_field_and_length_safe(object_info,"obj__child_count_object",&n_values);
    
    //Key Retrieval and Validation
    //---------------------------------------------------------------------
    int key_index = ((int)mxGetScalar(prhs[3]))-1;
    int n_keys = object_counts[object_data_index];
    if (key_index < 0 || key_index >= n_keys){
        mexErrMsgIdAndTxt("turtle_json:invalid_input",
                "key_index input is out of range for f2__get_key_value_type_and_index");
    }
    
    //All inputs have been validated at this point
    
    //Now we walk along the object keys until we get to the specified index
    //---------------------------------------------------------------------
    mxArray *key_info = mex_input; //mxGetField(mex_input,0,"key_info");
    int *next_sibling_index_key = get_int_field_safe(key_info,"key__next_sibling_index_key");
    
    //-----------------------------------------------
    
    int md_index = (++object_md_index);
    int key_data_index;
    
    for (int iKey = 0; iKey < key_index; iKey++){
        key_data_index = d1[md_index];
        md_index = next_sibling_index_key[key_data_index];
    }
    
    //md_index should now point to the key, but we want the key's value
    md_index++;
    
    set_double_output(&plhs[0],(double)types[md_index]);
    //+1 for 0b to 1b
    set_double_output(&plhs[1],(double)(md_index+1));
}

void f3__get_homogenous_array(int nlhs, mxArray *plhs[], int nrhs, const mxArray*prhs[]){
    //
    //  cellstr = json_info_to_data(3,mex_struct,array_md_index)
    //
    //  TODO: This and 4 should be merged along with supporting options
    //
    //  f3_get_array
    //
    //                           0  1           2               3              4              5              6
    //  data = json_info_to_data(3, mex_struct, array_md_index, expected_type, min_dimension, max_dimension, *options)
    //
    //  Inputs
    //  ------
    //  struct mex_struct
    //  double array_md_index
    //  double expected_type
    //  double min_dimension
    //      -1 indicates that any size is fine
    //  double max_dimension
    //  struct options
    
    if (!(nrhs == 6 || nrhs == 7)){
        mexErrMsgIdAndTxt("turtle_json:invalid_input",
                "json_info_to_data.f3__get_homogenous_array requires 5 or 6 inputs");
    }else if (!mxIsClass(prhs[1],"struct")){
        mexErrMsgIdAndTxt("turtle_json:invalid_input",
                "2nd input to json_info_to_data.f3__get_homogenous_array needs to be a structure");
    }else if (!mxIsClass(prhs[2],"double")){
        mexErrMsgIdAndTxt("turtle_json:invalid_input",
                "3rd input to json_info_to_data.f3__get_homogenous_array needs to be a double");
    }else if (!mxIsClass(prhs[3],"double")){
        mexErrMsgIdAndTxt("turtle_json:invalid_input",
                "4th input to json_info_to_data.f3__get_homogenous_array needs to be a double");
    }else if (!mxIsClass(prhs[4],"double")){
        mexErrMsgIdAndTxt("turtle_json:invalid_input",
                "5th input to json_info_to_data.f3__get_homogenous_array needs to be a double");
    }else if (!mxIsClass(prhs[5],"double")){
        mexErrMsgIdAndTxt("turtle_json:invalid_input",
                "6th input to json_info_to_data.f3__get_homogenous_array needs to be a double");
    }
    
    if (nrhs == 7 && !mxIsClass(prhs[6],"struct")){
        mexErrMsgIdAndTxt("turtle_json:invalid_input",
                "7th input to json_info_to_data.f3__get_homogenous_array needs to be a structure");
    }
    
    if (nlhs != 1){
        mexErrMsgIdAndTxt("turtle_json:invalid_output",
                "json_info_to_data.f3__get_homogenous_array requires 1 output");
    }
    
    const mxArray *mex_input = prhs[1];
    
    int n_values;
    int *d1 = get_int_field_and_length_safe(mex_input,"d1",&n_values);
    uint8_t *types = get_u8_field_safe(mex_input,"types");
    
    //Retrieval and validation of MD as index
    //------------------------------------------------------
    int array_md_index = ((int)mxGetScalar(prhs[2]))-1;
    if (array_md_index < 0 || array_md_index >= n_values){
        mexErrMsgIdAndTxt("turtle_json:invalid_input",
                "array_md_index input is out of range for f3__get_homogenous_array");
    }else if (types[array_md_index] != TYPE_ARRAY){
        mexErrMsgIdAndTxt("turtle_json:invalid_input",
                "array_md_index input is not an object for f3__get_homogenous_array");
    }
    
    int array_data_index = d1[array_md_index];
    
    //Other options
    //---------------------------------------------------------------------
    uint8_t expected_array_type = ((uint8_t)mxGetScalar(prhs[3]));
    int min_dimension = ((int)mxGetScalar(prhs[4]));
    int max_dimension = ((int)mxGetScalar(prhs[5]));
    
    //TODO: This could be improved ...
    FullParseOptions options = get_default_parse_options();
    if (nrhs == 7){
        options = populate_parse_options(prhs[6]);
    }
    
    //Array info extraction
    //---------------------------------------------------------------------
    const mxArray *array_info = mex_input; //mxGetField(mex_input,0,"array_info");
    uint8_t *array_types = get_u8_field_safe(array_info,"arr__array_types");
    int *child_count_array = get_int_field_safe(array_info,"arr__child_count_array");
    int *next_sibling_index_array = get_int_field_safe(array_info,"arr__next_sibling_index_array");
    uint8_t *array_depths = get_u8_field_safe(array_info,"arr__array_depths");
    
    mxArray *strings = get_mx_field_safe(mex_input,"strings");
    double *numeric_data = (double *)mxGetData(mxGetField(mex_input,0,"numeric_p"));
    
    uint8_t observed_array_type = array_types[array_data_index];
    
    int n_dimensions = child_count_array[array_data_index];
    
    //Dimension check
    //---------------------------------------------------------------------
    if (min_dimension == -1){
        //Then we are ok
    }else{
        if (min_dimension  > n_dimensions){
            mexErrMsgIdAndTxt("turtle_json:option_error",
                    "Min dimension is greater than the # of available dimensions");
        }else if (n_dimensions > max_dimension){
            mexErrMsgIdAndTxt("turtle_json:option_error",
                    "# of available dimensions is greater than the max requested dimension");
        }
    }
    
    //For right now we'll make this not as direct as it could be ...
    Data data = populate_data(mex_input);
    
    switch (observed_array_type){
        case ARRAY_OTHER_TYPE:
            mexErrMsgIdAndTxt("turtle_json:invalid_input",
                    "nd_array option not support for non nd-array");
            break;
        case ARRAY_NUMERIC_TYPE:
            if (expected_array_type == 0){
                plhs[0] = parse_array_with_options(data, array_md_index, &options);
            }else{
                mexErrMsgIdAndTxt("turtle_json:invalid_input",
                        "numeric array observed but not expected");
            }
            break;
        case ARRAY_STRING_TYPE:
            if (expected_array_type == 1){
                plhs[0] = parse_array_with_options(data, array_md_index, &options);
//                 plhs[0] = parse_cellstr(d1,
//                     child_count_array[cur_array_data_index],
//                     array_md_index,strings);
            }else{
                mexErrMsgIdAndTxt("turtle_json:invalid_input",
                        "nd_array string observed but not expected");
            }
            break;
        case ARRAY_LOGICAL_TYPE:
            if (expected_array_type == 2){
                plhs[0] = parse_array_with_options(data, array_md_index, &options);
            }else{
                mexErrMsgIdAndTxt("turtle_json:invalid_input",
                        "nd_array logical observed but not expected");
            }
            break;
        case ARRAY_OBJECT_SAME_TYPE:
            mexErrMsgIdAndTxt("turtle_json:invalid_input",
                    "nd_array option not support for non nd-array");
            break;
        case ARRAY_OBJECT_DIFF_TYPE:
            mexErrMsgIdAndTxt("turtle_json:invalid_input",
                    "nd_array option not support for non nd-array");
            break;
        case ARRAY_ND_NUMERIC:
            if (expected_array_type == 0){
                plhs[0] = parse_array_with_options(data, array_md_index, &options);
            }else{
                mexErrMsgIdAndTxt("turtle_json:invalid_input",
                        "nd_array numeric observed but not expected");
            }
            break;
        case ARRAY_ND_STRING:
            if (expected_array_type == 1){
                plhs[0] = parse_array_with_options(data, array_md_index, &options);
            }else{
                mexErrMsgIdAndTxt("turtle_json:invalid_input",
                        "nd_array string observed but not expected");
            }
            break;
        case ARRAY_ND_LOGICAL:
            if (expected_array_type == 2){
                plhs[0] = parse_array_with_options(data, array_md_index, &options);
            }else{
                mexErrMsgIdAndTxt("turtle_json:invalid_input",
                        "nd_array logical observed but not expected");
            }
            break;
    }
}

void f6__partial_object_parsing(int nlhs, mxArray *plhs[], int nrhs, const mxArray*prhs[]){
    //
    //
    //                                            0  1           2             3              4
    //  [struct,key_location] = json_info_to_data(6, mex_struct, object_index, keys_no_parse, keep_all_keys)
    //
    //      0) 6
    //      1) mex_structure
    //      2) object_md_index - md_index for the object we are parsing
    //      3) keys_not_to_parse - cellstr
    //      4) include_non_parsed_keys
    //
    //  Outputs
    //  0) struct
    //  1) key_location (1 based)
    //      Location of the keys to ignore ...
    //  
    
    if (nrhs != 5){
        mexErrMsgIdAndTxt("turtle_json:invalid_input",
                "json_info_to_data.f6 requires 5 inputs");
    }else if (!mxIsClass(prhs[1],"struct")){
        mexErrMsgIdAndTxt("turtle_json:invalid_input",
                "2nd input to json_info_to_data.f6 needs to be a structure");
    }else if (!mxIsClass(prhs[2],"double")){
        mexErrMsgIdAndTxt("turtle_json:invalid_input",
                "3rd input to json_info_to_data.f6 needs to be a double");
    }else if (!mxIsClass(prhs[3],"cell")){
        mexErrMsgIdAndTxt("turtle_json:invalid_input",
                "4th input to json_info_to_data.f6 needs to be a cell");
    }else if (!mxIsClass(prhs[4],"logical")){
        mexErrMsgIdAndTxt("turtle_json:invalid_input",
                "5th input to json_info_to_data.f6 needs to be a logical");
    }
    
    if (nlhs != 2){
        mexErrMsgIdAndTxt("turtle_json:invalid_output","json_info_to_data.f6 requires 2 outputs");
    }
    
    //Algorithm get object_info
    //Check # of keys
    //Walk along keys until specified value
    //Return results
    const mxArray *s = prhs[1];
    
    Data data = populate_data(s);
    
    int object_md_index = ((int)mxGetScalar(prhs[2]))-1;
    
    if (object_md_index < 0 || object_md_index >= data.n_md_values){
        mexErrMsgIdAndTxt("turtle_json:invalid_input",
                "md_index out of range for f6");
    }else if (data.types[object_md_index] != TYPE_OBJECT){
        mexErrMsgIdAndTxt("turtle_json:invalid_input",
                "md_index does not point to an object");
    }
    
    int object_data_index = data.d1[object_md_index];
    int object_id = data.object_ids[object_data_index];
    int n_keys = data.child_count_object[object_data_index];
    
    //Default false (i.e. parse)
    bool *dont_parse = mxCalloc(n_keys,1);
    
    mxArray *example_object = mxGetCell(data.objects,object_id);
    
    const mxArray *keys_to_ignore = prhs[3];
    size_t n_keys_to_ignore = mxGetNumberOfElements(keys_to_ignore);
    
    double *key_locations = mxMalloc(n_keys*sizeof(double));
    
    int field_number;
    char *field_name;
    for (int iKey = 0; iKey < n_keys_to_ignore; iKey++){
        //If not a string then field name is null - so yes ...
        field_name = mxArrayToString(mxGetCell(keys_to_ignore,iKey));
        //Note this approach assumes failure returns null
        if (!field_name){
        	mexErrMsgIdAndTxt("turtle_json:invalid_input",
                    "not all keys to ignore were strings");
        }
        field_number = mxGetFieldNumber(example_object,field_name);
        key_locations[iKey] = (double)(field_number+1);
        if (field_number >= 0){
            dont_parse[field_number] = 1;
        }
    }
    
    mxFree(field_name);
    
    plhs[1] = mxCreateNumericMatrix(1,0,mxDOUBLE_CLASS,0);
    mxSetN(plhs[1],n_keys_to_ignore);
    mxSetData(plhs[1],key_locations);
    
    plhs[0] = get_initialized_struct(data,data.d1[object_md_index],1);
    mxArray *obj = plhs[0];
    
    mxArray *temp_mxArray;
    
    const int *next_sibling_index_key = data.next_sibling_index_key;
    const uint8_t *types = data.types;
    
    int cur_key_md_index = object_md_index + 1;
    int cur_key_data_index = data.d1[cur_key_md_index];
    for (int iKey = 0; iKey < n_keys; iKey++){
        if (!dont_parse[iKey]){
            int cur_key_value_md_index = cur_key_md_index + 1;
            switch (types[cur_key_value_md_index]){
                case TYPE_OBJECT:
                    temp_mxArray = get_initialized_struct(data,data.d1[cur_key_value_md_index],1);
                    parse_object(data,temp_mxArray,0,cur_key_value_md_index);
                    mxSetFieldByNumber(obj,0,iKey,temp_mxArray);
                    break;
                case TYPE_ARRAY:
                    mxSetFieldByNumber(obj,0,iKey,
                            parse_array(data,cur_key_value_md_index));
                    break;
                case TYPE_KEY:
                    mexErrMsgIdAndTxt("turtle_json:code_error",
                            "Found key type as child of key");
                    break;
                case TYPE_STRING:
                    mxSetFieldByNumber(obj,0,iKey,getString(data.d1,data.strings,cur_key_value_md_index));
                    break;
                case TYPE_NUMBER:
                    mxSetFieldByNumber(obj,0,iKey,getNumber(data,cur_key_value_md_index));
                    break;
                case TYPE_NULL:
                    mxSetFieldByNumber(obj,0,iKey,getNull(data,cur_key_value_md_index));
                    break;
                case TYPE_TRUE:
                    mxSetFieldByNumber(obj,0,iKey,getTrue(data,cur_key_value_md_index));
                    break;
                case TYPE_FALSE:
                    mxSetFieldByNumber(obj,0,iKey,getFalse(data,cur_key_value_md_index));
                    break;
            }
        }
        cur_key_md_index = next_sibling_index_key[cur_key_data_index];
        cur_key_data_index = data.d1[cur_key_md_index];
    }
    
    bool *keep_keys = mxGetData(prhs[4]);
    if (!(*keep_keys)){
        // - need to remove these fields
        for (int iKey = n_keys - 1; iKey >= 0; iKey--){
            if (dont_parse[iKey]){
                mxRemoveField(obj, iKey);
            }
        }
    }
    
    //prhs[4]
    //=> logical
    //JAH: Should be all done, just need to test ...
}

void f7__full_options_parse(int nlhs, mxArray *plhs[], int nrhs, const mxArray*prhs[]){
    //
    //  data = json_info_to_data(7,mex_struct,start_index,options)
    //
    //
    
    if (nrhs != 4){
        mexErrMsgIdAndTxt("turtle_json:invalid_input",
                "json_info_to_data.f7 requires 4 inputs");
    }else if (!mxIsClass(prhs[1],"struct")){
        mexErrMsgIdAndTxt("turtle_json:invalid_input",
                "2nd input to json_info_to_data.f7 needs to be a structure");
    }else if (!mxIsClass(prhs[2],"double")){
        mexErrMsgIdAndTxt("turtle_json:invalid_input",
                "3rd input to json_info_to_data.f7 needs to be a double");
    }else if (!mxIsClass(prhs[3],"struct")){
        mexErrMsgIdAndTxt("turtle_json:invalid_input",
                "4th input to json_info_to_data.f7 needs to be a structure");
    }
    
    if (nlhs != 1){
        mexErrMsgIdAndTxt("turtle_json:invalid_output",
                "json_info_to_data.f0 requires 1 output");
    }
    
    const mxArray *s = prhs[1];
    int md_index = ((int) mxGetScalar(prhs[2]))-1;
    
    Data data = populate_data(s);
    
    FullParseOptions options = populate_parse_options(prhs[3]);
    
    if (md_index < 0 || md_index >= data.n_md_values){
        mexErrMsgIdAndTxt("turtle_json:invalid_input",
                "md_index out of range for f0");
    }
    
    if (data.types[md_index] == TYPE_KEY){
        //We'll return what the key points to
        ++md_index;
    }
    
    int data_index;
    switch (data.types[md_index]){
        case TYPE_OBJECT:
            data_index = data.d1[md_index];
            plhs[0] = get_initialized_struct(data, data_index,1);
            parse_object(data, plhs[0], 0, md_index);
            break;
        case TYPE_ARRAY:
            plhs[0] = parse_array_with_options(data, md_index, &options);
            break;
        case TYPE_KEY:
            //We should already check against this ...
            mexErrMsgIdAndTxt("turtle_json:code_error",
                    "key child of key found, code error made somewhere");
            break;
        case TYPE_STRING:
            plhs[0] = getString(data.d1,data.strings,md_index);
            break;
        case TYPE_NUMBER:
            plhs[0] = getNumber(data,md_index);
            break;
        case TYPE_NULL:
            plhs[0] = getNull(data,md_index);
            break;
        case TYPE_TRUE:
            plhs[0] = getTrue(data,md_index);
            break;
        case TYPE_FALSE:
            plhs[0] = getFalse(data,md_index);
            break;
    }
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray*prhs[])
{
    
    //  Calling Forms
    //  ----------------------------------------------
    //  0: full parsing
    //      data = json_info_to_data(0,mex_struct,start_index)
    //
    //  1: object key name to key_index (in struct)
    //      index_1b = json_info_to_data(1,mex_struct,obj_md_index,key_name)
    //
    //  2: key_index to (type,md_index_1b)
    //      [type,md_index_1b] = json_info_to_data(2,mex_struct,obj_md_index,key_index_1b)
    //
    //  3: Retrieve cellstr
    //      cellstr = json_info_to_data(3,mex_struct,array_md_index)
    //
    //  4: Retrieve nd-array
    //      nd_arrray = json_info_to_data(4,mex_struct,array_md_index,expected_array_type)
    //      expected_array_type:
    //          0 - numeric
    //          1 - string
    //          2 - logical
    //
    //  5: Retrieve cell of 1d numeric arrays
    //      cell_output = json_info_to_data(5,mex_struct,array_md_index);
    //
    //  6: Retrieve partial object
    //      [struct,key_locations] = json_info_to_data(6,mex_struct,object_md_index,keys_not_parse,include_non_parsed_keys);
    //
    //  json_info_to_data(mex_struct)
    //
    //  Inputs
    //  ------
    //  mex_struct : output structure from turtle_json
    
    if (nrhs < 1){
        mexErrMsgIdAndTxt("turtle_json:invalid_input",
                "json_info_to_data.mex requires at least one input");
    }
    
    //Ideally we could allow any number, but Matlab tends to use doubles
    if (!mxIsClass(prhs[0],"double")){
        mexErrMsgIdAndTxt("turtle_json:invalid_input",
                "First input needs to be a double");
    }
    
    switch ((int)mxGetScalar(prhs[0])){
        case 0:
            f0__full_parse(nlhs,plhs,nrhs,prhs);
            break;
        case 1:
            f1__get_key_index(nlhs,plhs,nrhs,prhs);
            break;
        case 2:
            f2__get_key_value_type_and_index(nlhs,plhs,nrhs,prhs);
            break;
        case 3:
            f3__get_homogenous_array(nlhs,plhs,nrhs,prhs);
            break;
//         case 4:
//             f4__get_nd_array(nlhs,plhs,nrhs,prhs);
//             break;
//         case 5:
//             f5__get_cell_of_1d_numeric_arrays(nlhs,plhs,nrhs,prhs);
//             break;
        case 6:
            f6__partial_object_parsing(nlhs,plhs,nrhs,prhs);
            break;
        case 7:
            f7__full_options_parse(nlhs,plhs,nrhs,prhs);
            break;
        default:
            mexErrMsgIdAndTxt("turtle_json:invalid_input",
                    "Function option not recognized");
            
    }
}
