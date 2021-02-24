//This code snippet can be placed at the end of the main
//parsing code to add the x,y,z values in the 1.json file

//-----------------------------------------------
//                             json_string: [1�224698929 uint8]
//                                   types: [1�15000005 uint8]
//                                      d1: [1�15000005 int32]
//                 obj__child_count_object: [1�2000001 int32]
//          obj__next_sibling_index_object: [1�2000001 int32]
//                      obj__object_depths: [1�2000001 uint8]
//     obj__unique_object_first_md_indices: [1�3 int32]
//                         obj__object_ids: [1�2000001 int32]
//                            obj__objects: {1�3 cell}
//                  arr__child_count_array: [1�1000001 int32]
//           arr__next_sibling_index_array: [1�1000001 int32]
//                       arr__array_depths: [1�1000001 uint8]
//                        arr__array_types: [1�1000001 uint8]
//                              key__key_p: [1�6000002 uint64]
//                          key__key_sizes: [1�6000002 int32]
//             key__next_sibling_index_key: [1�6000002 int32]
//                                string_p: [1�1000001 uint64]
//                            string_sizes: [1�1000001 int32]
//                               numeric_p: [1�4000000 double]
//                                 strings: {1�1000001 cell}
//                                    slog: [376�1 uint8]   
    
    
    uint8_t *types = mxGetData(mxGetFieldByNumber(plhs[0],0,E_types));
    int32_t *d1 = mxGetData(mxGetFieldByNumber(plhs[0],0,E_d1));
    double *numeric_data = mxGetData(mxGetFieldByNumber(plhs[0],0,E_numeric_p));
    int32_t *next_obj = mxGetData(mxGetFieldByNumber(plhs[0],0,E_obj__next_sibling_index_object));
    uint8_t *arr_types = mxGetData(mxGetFieldByNumber(plhs[0],0,E_arr__array_types));
    int32_t *key_sizes = mxGetData(mxGetFieldByNumber(plhs[0],0,E_key__key_sizes));
    char **key_pointers = mxGetData(mxGetFieldByNumber(plhs[0],0,E_key__key_p));
    int32_t *arr_size = mxGetData(mxGetFieldByNumber(plhs[0],0,E_arr__child_count_array));
    
    //Technically we need to add on a couple of checks
    //n_keys in first object
    //
    
    
    
    
    
    //Format
    //{ coordinates: [ {} {} {}
    if (types[0] != TYPE_OBJECT){
        mexErrMsgTxt("Expected object");
    }
    //skipped # of keys check
    int key_id = d1[1]; //Should be 0 - i.e. first key
    int key_size = key_sizes[key_id];
    char *key_p = key_pointers[key_id];
    if (memcmp(key_p,"coordinates",11) != 0){
        mexErrMsgTxt("First key not coordinates as expected");
    }
    if (types[2] != TYPE_ARRAY){
        mexErrMsgTxt("Expected array");
    }
    
    int array_id = d1[2]; //should be 1
    //TODO: length check on # of array
    
    //mexPrintf("Array length: %d\n",arr_size[array_id]);
    if (arr_types[array_id] != ARRAY_OBJECT_SAME_TYPE){
        mexErrMsgTxt("Expected homogenous object array");
    }
    
    //TODO: Add on x,y,z check 
    
    //{ x:#, y:#, z:#,...
    //3 4 5  6 7  8 9   
    
    //mexPrintf("Type of x: %d\n",types[5]);
    
    double x = 0;
    double y = 0;
    double z = 0;
    int obj_d1_I = 3;
    int obj_I;
    int double_I;
    int temp_I;
    for (int i = 0; i < arr_size[array_id]; i++){
        //This relationship could be verified from homo array and string testing
        obj_I = d1[obj_d1_I];
        
        temp_I = obj_d1_I + 2;
        double_I = d1[temp_I];
        x += numeric_data[double_I];
        
        temp_I = temp_I + 2;
        double_I = d1[temp_I];
        y += numeric_data[double_I];
        
        temp_I = temp_I + 2;
        double_I = d1[temp_I];
        z += numeric_data[double_I];
        
        obj_d1_I = next_obj[obj_I];
        
//         if (i == 0){
//             mexPrintf("x: %0.5f\n",x);
//             mexPrintf("y: %0.5f\n",y);
//             mexPrintf("z: %0.5f\n",z);
//         }
    }
    
//     mexPrintf("x: %0.5f\n",x);
//     mexPrintf("y: %0.5f\n",y);
//     mexPrintf("z: %0.5f\n",z);
    
    