#include "turtle_json.h"

//  File: turtle_json_post_process.c

//In this file:
//-------------
//+ post_process - main file
//  - populate_object_flags - in turtle_json_pp_objects.c
//  - initialize_unique_objects
//  - populate_array_flags
//  - parse_numbers
//  - parse_char_data
//
//+ populateProcessingOrder - helper for specifying order of processing for objects and arrays
//+ check_for_nd_array - 
//+ populate_array_flags - 
//   - flags include
//+ parse_char_data
//+ parse_utf8_char



//UTF-8 parsing related
//-------------------------------------------------------------------------
//https://en.wikipedia.org/wiki/UTF-8#Description
//The 1st utf8 byte specifies how many bytes belong to a single character
//subsequent bytes are identified by a leading 10 bit pattern
#define IS_CONTINUATION_BYTE *p >> 6 == 0b10

#define ADD_CONTINUATION_BYTE_VALUE utf8_value = (utf8_value << 6) + (*p & 0b111111)

//https://en.wikipedia.org/wiki/Specials_(Unicode_block)#Replacement_character
//Matlab uses DE0B - invalid character :/ native2unicode()
#define UNREPRESENTABLE_UTF8_CHAR 0xFFFD

//Not sure if we would ever want to change this ...
//TODO: Document what this means
#define ERROR_UTF_CHAR 0

//-------------------------------------------------------------------------





//=========================================================================
//=========================================================================
//=========================================================================

void populateProcessingOrder(int *process_order, uint8_t *types, 
        int n_entries, uint8_t type_to_match, int *n_values_at_depth, 
        int n_depths, uint8_t *value_depths){
    //
    //  This is a helper function which orders data by depth (nesting level).
    //  Processing starts at the lowest depth first, which is important
    //  for arrays and determining homogeneity.
    //
    //  For objects this allows us to try and find objects of the type type.
    //
    //  The names have been made generic to accomodate both arrays and objects.
    //
    //  Inputs
    //  ------
    //  types : array (length => n_entries)
    //  n_entries : 
    //  type_to_match : scalar
    //          
    //  n_values_at_depth: array
    //  n_depths:
    //  value_depths:
    //
    //  Output
    //  ------
    //  process_order : array, length == n_arrays or n_objects
    //       
    //       - order in which to process array objects, from the 0th index
    //       to the end of the array
    //       - values of the array are md_indices of the specified caller
    //       type (array or object)
    //
    //  Memory Allocations
    //  ------------------
    //  none
    
    int cur_depth_index[MAX_DEPTH_ARRAY_LENGTH];
    

    //This is a temporary variable, we could malloc/free it ...
    //int *cur_depth_index = mxMalloc(n_depths*sizeof(int));
    
    int cur_running_index = 0;
    //- This sets the start index in 'process_order' for each depth
    //- The order is based on how many arrays came at lower depths
    //- Note that we start from lowest depth first
    //- Depth currently starts at 1 (0 index is empty) ... 
    //      TODO: We should code this (that 0 is empty) in 
    //            with defined levels in some header
    //
    //- e.g. if we have the following numbers of 
    //              things (arrays or objects) at each depth:
    //
    //   0 1 2 3  <= depths
    //  [2 3 4 1] <= n values at depth
    //
    //  cur_depth_index[3] = 0
    //  cur_depth_index[2] = 1 (only 1 value at depth 3)
    //  cur_depth_index[1] = 5 (since 4 values at depth 2, i.e. 1 + 4)
    //  cur_depth_index[0] = 8 (since 3 values at depth 1, i.e. 5 + 3)
    //
    //
    //  With this info we can populate an array whereby all indices
    //  of a given depth preceed indices of a shallower depth, allowing
    //  us to process info from deepest to shallowest.
    for (int iDepth = n_depths - 1; iDepth > 0; iDepth--){
        cur_depth_index[iDepth] = cur_running_index;
        cur_running_index += n_values_at_depth[iDepth];
    }
    
    int cur_value_index = 0;
    int cur_process_index;
    //- Now we actually log the order in which to process the arrays
    //- For every array, log when to process it, placing it as the 'next'
    //  arrray to process based on its depth
    for (int iData = 0; iData < n_entries; iData ++){
        //TODO: We could do both arrays and objects at the same time ...
        //i.e. if not an array, it might be an object - low priority
        if (types[iData] == type_to_match){
            cur_process_index = cur_depth_index[value_depths[cur_value_index]]++;
            process_order[cur_process_index] = iData;
            cur_value_index++;
        }
    }    
    //mxFree(cur_depth_index);
}
//=========================================================================
//=========================================================================

void check_for_nd_array(int array_md_index, int array_data_index, 
        uint8_t *array_types, int *child_count_array, 
        uint8_t *array_depths, int* child_size_stack, int *next_sibling_index_array,
        uint8_t *types, int *d1, int n_children){
    //
    //  
    //
    //  Populates
    //  ---------
    //  array_types[array_data_index]
    //
    //  An ND array is an array that contains arrays of the same type
    //  and shape
    //
    //  Inputs
    //  ------
    //  array_md_index :
    //      Index into the d1 and types arrays.
    //  array_data_index :
    //      The array counter value i.e. d1[array_md_index]
    //  array_types : length n_arrays
    //      see specifics in turtle_json.h
    //  child_count_array : 
    //  array_depths : 
    //  child_size_stack :
    //  next_sibling_index_array : 
    //  types : length n_tokens
    //  d1 : length n_tokens
    //  n_children : 
    //
    //  See Also
    //  --------
    //  populate_array_flags (caller)
    //
    
    
    //mexPrintf("Running check_for_nd_array\n");
    
    //- Input (index) is the type of processed array
    //- Output (value) is the new type of processed array
    const uint8_t array_type_map2[11] = { 
        ARRAY_OTHER_TYPE,   //Nothing
        ARRAY_ND_NUMERIC,   //numeric - i.e. if children contain numeric arrays (1d), then we become a 2d numeric array
        ARRAY_ND_STRING,    //string
        ARRAY_ND_LOGICAL,   //logical
        ARRAY_OTHER_TYPE,   //object same type
        ARRAY_OTHER_TYPE,   //object diff type
        ARRAY_ND_NUMERIC,   //nd_numeric
        ARRAY_ND_STRING,    //nd_string
        ARRAY_ND_LOGICAL,   //nd_logical     
        ARRAY_ND_EMPTY,     //empty    
        ARRAY_ND_EMPTY};    //nd_empty
    
    
    int child_md_index = array_md_index + 1;
    int child_data_index = array_data_index + 1;
    uint8_t first_child_array_type = array_types[child_data_index];
    
    //0 indicates that the child array does not hold homogenous data
    //
    //If the child is not-homogenous, then the parent can't be either
    if (first_child_array_type == 0){
        return;
    }

    int first_child_size = child_count_array[child_data_index];
    uint8_t first_child_depth = array_depths[child_data_index];
    
    int moving_child_data_index;
    
    //Log the sizes of the first arrays
    //i.e length(x[0]), length(x[0][0]), etc.
    if (first_child_depth > 1){
       moving_child_data_index = child_data_index + 1; 
       for (int iDepth = first_child_depth-1; iDepth > 0; iDepth--){
           child_size_stack[iDepth] = child_count_array[moving_child_data_index];
           moving_child_data_index++;
       } 
    }
    
    bool is_nd_array = true;
    
    //Algorithm explanation:
    //----------------------
    //Approach, for each child of the current array, compare its
    //"first sizes" to the "first sizes" of the first child array
    //
    //i.e. does length(x[i]) == length(x[0]) and
    //          length(x[i][0] == length(x[0][0]) and
    //          length(x[i][0][0] == length(x[0][0][0]) etc.
    //     for all 'i' where this current area equals:
    //     current_array = [x[0],x[1],x[2],...,x[n]]
    //
    //     Note, we also verify that all of these entries have the same
    //     dimensionaility, e.g. if x[0] is 3D, then x[1] must be as well
    //     and so on, otherwise the current_array won't be 4D
    //
    //  We don't need to check something like the following:
    //      length(x[i][1]) == length(x[0][0])
    //
    //  This is because we have already verified that all children
    //  are the same (based on the array type). In other words, we
    //  already know that if x[i] is an nd-array type (as opposed to
    //  a non-homogenous array), that
    //  length(x[i][0]) == length(x[i][1]) == length(x[i][2]) etc.
    //
    //  Thus, checking length(x[i][1]) == length(x[0][0]) is 
    //  redundant if we know length(x[i][0]) == length(x[0][0])
    //
    //  In the end, this approach means we don't need to look at all of
    //  the child arrays, which saves time.
    
    for (int iChild = 1; iChild < n_children; iChild++){

        child_md_index = next_sibling_index_array[child_data_index];

        child_data_index = d1[child_md_index];
        
        //This is a data type check, not an array type check ...
        if (types[child_md_index] != TYPE_ARRAY){
            is_nd_array = false;
            break;
        }
         
        if (first_child_size == child_count_array[child_data_index] &&
                first_child_depth == array_depths[child_data_index] &&
                first_child_array_type == array_types[child_data_index]){
            
            //Depth verification
            moving_child_data_index = child_data_index+1;
            for (int iDepth = first_child_depth-1; iDepth > 0; iDepth--){
                if (child_size_stack[iDepth] != child_count_array[moving_child_data_index]){
                    is_nd_array = false;
                    break;
                } 
                moving_child_data_index++;
            }
        }else{
            is_nd_array = false;
        }
    }
        
    if (is_nd_array){
        array_types[array_data_index]  = array_type_map2[array_types[child_data_index]];
        //Bump up the dimension => e.g. 1d to 2d
        array_depths[array_data_index] = array_depths[child_data_index] + 1;
    }
}



//=========================================================================
//=========================================================================
//                          Array Flags
//=========================================================================
//=========================================================================
void populate_array_flags(unsigned char *js,mxArray *plhs[], struct sdata *slog){
//
//  This function populates:
//  --------------------------------------------
//  array_depths - actually, it just redefines it
//      - input definition: level of nesting in the JSON structure
//      - output definition: dimensionality of the array
//  array_types
    
    //TODO: I need to go through and rename things 
    
    //---- array info ------
    mxArray *array_info = plhs[0];
    mwSize n_arrays = get_field_length2(array_info,"arr__next_sibling_index_array");
    
    if (n_arrays == 0){
        //Set arr_array_types to empty ...
        //TODO: Can this be a fixed array???
        setStructField2(array_info,0,mxUINT8_CLASS,0,E_arr__array_types);
        return;
    }
    uint8_t *array_depths = get_u8_field_by_number(array_info,E_arr__array_depths);
    int *child_count_array = get_int_field_by_number(array_info,E_arr__child_count_array);
    int *next_sibling_index_array = get_int_field_by_number(array_info,E_arr__next_sibling_index_array);
    
    //Extraction of relevant local variables
    //---------------------------------------------------------------------
    //---- main data info -----
    uint8_t *types = get_u8_field_by_number(plhs[0],E_types);
    int *d1 = get_int_field_by_number(plhs[0],E_d1);
    mwSize n_entries = get_field_length(plhs,"d1");
    
    //---- depth info ------
    int *n_arrays_at_depth = slog->arr__n_arrays_at_depth;
    mwSize n_depths = MAX_DEPTH_ARRAY_LENGTH;
    
    //---- object info ------
    mxArray *object_info = plhs[0];
    int n_objects = get_field_length2(object_info,"obj__next_sibling_index_object");
    
    int *object_ids;
    int *next_sibling_index_object;
    if (n_objects != 0){
        //object_ids could be null, which is fine
        //but we are running a check to make sure it is not null so
        //that we don't run into problems later on (from trying to use a 
        //null field)
        //
        //  i.e. we can't distinguish between a null pointer and
        //  a missing call to mxGetField
        
        object_ids = get_int_field_by_number(object_info,E_obj__object_ids);  
        next_sibling_index_object = get_int_field_by_number(object_info,E_obj__next_sibling_index_object);
    }
        
    //Determining the order to process arrays
    //---------------------------------------------------------------------
    //We process arrays from deepest in the JSON structure to shallowest
    //This allows us to make claims about the parent array type
    //with a bit less hassle since the child array types have already
    //been processed (since they are deeper structures
    //
    //  process_order = 
    int *process_order = malloc(n_arrays*sizeof(int));
    populateProcessingOrder(process_order, types, n_entries, TYPE_ARRAY, 
            n_arrays_at_depth, n_depths, array_depths);

    //Variable setup for actual processing
    //---------------------------------------------------------------------

    //Map the input types of an array to more generic mixed types
    //e.g. true and false to logical
    //
    //  We process the children of arrays.
    //  [ [ => need to process a nd array
    //  [ 4 => could be a homogenous numeric array
    //  [ "test" => could be a homogenous string array
    //  
    //  This variable only handles non-array types (possible 1d values)
    //  
    //  Thus if we detect all strings (type 4) in an array then we mark 
    //  the array as a 1d array string type.
    //
    //  i.e. array_type[i] = array_type_map1[4] = ARRAY_STRING_TYPE
    
    uint8_t array_type_map1[9] = { 
        ARRAY_OTHER_TYPE,    //Nothing - i.e. not specified
        ARRAY_OTHER_TYPE,    //Object
        ARRAY_OTHER_TYPE,    //Array
        ARRAY_OTHER_TYPE,    //Key
        ARRAY_STRING_TYPE,   //String
        ARRAY_NUMERIC_TYPE,  //Number
        ARRAY_NUMERIC_TYPE,  //Null
        ARRAY_LOGICAL_TYPE,  //True
        ARRAY_LOGICAL_TYPE}; //False
     
    bool is_nd_array;
    int object_array_type;
    int n_children;
    int child_size;
    int child_depth;
    int cur_child_array_index;
    int cur_child_data_index;
    
    int cur_md_index; //md - Main Data
    
    int cur_object_data_index;
    
    int cur_child_array_index2;
    int cur_child_data_index2;
    int cur_process_index;
    int cur_array_index;
    
    int reference_object_id;
    
    int n_object_keys;
    
    int child_size_stack[MAX_DEPTH_ARRAY_LENGTH];

    
    //This is the output that is getting populated in this function
    uint8_t *array_types = mxCalloc(n_arrays,sizeof(uint8_t));
    
    uint8_t cur_child_array_type;
    for (int iArray = 0; iArray < n_arrays; iArray++){
        cur_process_index = process_order[iArray];
        cur_array_index = d1[cur_process_index];
        
        //We are redefining what array_depths means at this point
        //since the memory isn't needed
        //OLD: - how deep in the JSON structure, 1 => root, 2 => level below root
        //NEW: 1 means the array holds raw data (numeric, string, logical)
        //     2 means that the array holds arrays which hold raw data (i.e. 2d array)
        array_depths[cur_array_index] = 0;
        n_children = child_count_array[cur_array_index];
        if (n_children){
            //We are switching on the contents of the array, and we want
            //to use this to determine the type of the array
            switch (types[cur_process_index+1]){
                case TYPE_OBJECT:
                    //
                    //[ {'a':1,'b':2},{'a':1,'b':2}]
                    //  o1            o2      <= both objects are the same,
                    //                          create a struct array
                    //
                    //[ {'a':1,'b':2},{'a':1,'b':2},{'a':1,'b':2,'c':3}]
                    //  o1            o2            o3    <= objects are not 
                    //                              the same, cell array of structs
                    
                    cur_object_data_index = d1[cur_process_index+1];
                    reference_object_id = object_ids[cur_object_data_index];
                    
                    //We need to check 2 things:
                    //1 - do we have an object in the next entry
                    //2 - is the object of the same type?
                    //
                    //Three possible outcomes:
                    //1 - all of the same type
                    //2 - all objects, but different types
                    //3 - not all objects
                    object_array_type = ARRAY_OBJECT_SAME_TYPE;
                    for (int iChild = 1; iChild < n_children; iChild++){
                        cur_md_index = next_sibling_index_object[cur_object_data_index];
                        if (types[cur_md_index] == TYPE_OBJECT){
                            cur_object_data_index = d1[cur_md_index];
                            if (reference_object_id != object_ids[cur_object_data_index]){
                                object_array_type = ARRAY_OBJECT_DIFF_TYPE;
                            }
                        }else{
                            object_array_type = ARRAY_OTHER_TYPE;
                            //This is the most generic case, so we break
                            //after this
                            break;
                        }
                    }
                    array_types[cur_array_index] = object_array_type;
                    break;
                case TYPE_ARRAY:
                    //This indicates that our array holds an array.
                    
                    check_for_nd_array(cur_process_index, 
                            cur_array_index, 
                            array_types, 
                            child_count_array, 
                            array_depths, 
                            child_size_stack, 
                            next_sibling_index_array,
                            types, d1, n_children);

                    break;
                case TYPE_KEY:
                    mexErrMsgIdAndTxt("turtle_json:code_error", 
                            "Code error detected, key was found as child of array in post-processing");
                    break;
                //---------------------------------------------------------    
                case TYPE_STRING:
                case TYPE_NUMBER:
                case TYPE_NULL:
                    //Here we are checking for a 1d array
                    //
                    //  n_children - # of elements in the array (of any type)
                    //  d1 - increments for any token and points to 
                    //  another indexthat increments based on type
                    //
                    //  Consider:
                    //  -------------------------
                    //  [3,4,5,[6],7,8]
                    //  - n_children = 6
                    //  - n_tokens = 7  (3,4,5,[],6,7,8)
                    //  - [  d1[x+0] => current array, let's say 10
                    //  - 3  d1[x+1] => current # count, let's say 1
                    //  - 4  d1[x+2] => 1 + 1 => 2 (since d1[1] is 1
                    //  - 5  d1[x+3] => 3
                    //  - [  d1[x+4] => 10 + 1 => 11 (since array type and d1[0] = 10
                    //  - 6  d1[x+5] => 4 (back to numbers type, last one was 3)
                    //  - 7  d1[x+6] => 5 (4 + 1)
                    //  - 8  d1[x+7] => 6 (note, this is the last element in the array)
                    //
                    //
                    //  d1[cur_process_index+n_children] => 5
                    //  d1[cur_process_index+1] => 1
                    //  n_children != (5 - 1 + 1)  => since array is present
                    //
                    //  [4,5,6]
                    //  - n_children = 3
                    //  - n_tokens = 3
                    //  - [   d1[x+0] => let's say 25
                    //  - 4   d1[x+1] => let's say 32
                    //  - 5   d1[x+2] => 33 (32 + 1)
                    //  - 6   d1[x+3] => 34
                    //  d1[cur_process_index+n_children] => 34
                    //  d1[cur_process_index+1] => 32
                    //  n_children == (34 - 32 + 1) => thus 1d numeric array
                    //
                    //  [6,7,[],8]
                    //  - n_children = 4
                    //  - n_tokens = 4
                    //  - [   d1[x+0] => let's say 105
                    //  - 6   d1[x+1] => let's say 53
                    //  - 7   d1[x+2] => 54
                    //  - [   d1[x+3] => 106
                    //  - 8   d1[x+4] => 55
                    //  d1[cur_process_index+n_children] => 55
                    //  d1[cur_process_index+1] => 53
                    //  n_children != (55 - 53 + 1)
                    
                    if (n_children == (d1[cur_process_index+n_children] - d1[cur_process_index+1] + 1) && \
                            types[cur_process_index+1] == types[cur_process_index+n_children]){
                        //homogeneous, assign to appropriate type
                        array_types[cur_array_index] = array_type_map1[types[cur_process_index+1]];
                    }
                    array_depths[cur_array_index] = 1;
                    break;
                case TYPE_TRUE:
                case TYPE_FALSE:
                    if (n_children == (d1[cur_process_index+n_children] - d1[cur_process_index+1] + 1) && \
                            types[cur_process_index+1] >= TYPE_TRUE && \
                            types[cur_process_index+n_children] >= TYPE_TRUE){
                        //homogeneous, assign to appropriate type
                        array_types[cur_array_index] = array_type_map1[types[cur_process_index+1]];
                    }
                    array_depths[cur_array_index] = 1;
                    break;
                //---------------------------------------------------------  
                default:
                    mexErrMsgIdAndTxt("turtle_json:code_error", "Code error detected, unrecognized type in post-processing");
                    break;
            }
                    
        }else{
            array_types[cur_array_index] = ARRAY_EMPTY_TYPE;
        }
    }
    
    free(process_order);
    setStructField2(array_info,array_types,mxUINT8_CLASS,n_arrays,E_arr__array_types); 
}

//=========================================================================
//=========================================================================
void parse_char_data(unsigned char *js,mxArray *plhs[],struct sdata *slog){
    //
    //  Parses string characters into Matlab strings
    //  
    //  This includes:
    //  1) Initializaton of cell arrays and string Matlab objects
    //  2) Processing of character escapes, e.g. \n to newline
    //  3) Unicode escapes - code assumes UTF-8 encoding
    //
    //  Note, not a lot of time was spent on trying to be clever in this 
    //  section. The majority of 
    
    
        
    mxArray *temp = mxGetFieldByNumber(plhs[0],0,E_string_p);
    unsigned char **char_p = (unsigned char **)mxGetData(temp);
    int n_entries = mxGetN(temp);
    int *start_indices;
    int *end_indices;
    
    //TODO: rename to string sizes
    int *sizes = get_int_field_by_number(plhs[0],E_string_sizes);

    
    //Initial allocation of memory
    //---------------------------------------------------------------------
    //  This takes forever relative to everything else.
    TIC(string_memory_allocation);
    int n_chars_max_in_string;
    mxArray *cell_array = mxCreateCellMatrix(1,n_entries);
    mxArray *temp_mx_array;
    uint16_t *cell_data;
    uint16_t **all_cells_data = mxMalloc(n_entries*sizeof(cell_data));
    
    for (int i = 0; i < n_entries; i++){
        n_chars_max_in_string = sizes[i];
        
        //String initialization
        //--------------------------------------
        //mxCreateUninitNumericMatrix is an option but it is
        //relatively new so we'll avoid it(2015a or newer :/)
        temp_mx_array = mxCreateNumericMatrix(1,0,mxCHAR_CLASS,mxREAL);
        cell_data = mxMalloc(n_chars_max_in_string*2);
        //This approach avoids initialization of the data
        mxSetData(temp_mx_array,cell_data);
        mxSetN(temp_mx_array,n_chars_max_in_string);
        
        //Hold onto for populating the actual data (next loop)
        all_cells_data[i] = cell_data;
        
        //Put the string in the cell array
        mxSetCell(cell_array,i,temp_mx_array); 
    } 
    TOC(string_memory_allocation,time__string_memory_allocation_time);
    
    
    //Parsing of the string into proper UTF-8
    //---------------------------------------------------------------------
    TIC(string_parse);

    
    //  Character Escapes
    //  -----------------
    //  Goal is to replace escape characters with their values.
    //
    //  When an escape is detected, then if the next character is:
    //  1) '"' (ASCII 34), then the output is '"'
    //  i.e. escape_values[34] => '"'
    //  2) 'n' (ASCII 110), then the output is is '\n' (i.e. newline)
    //  i.e. escape_values[110] => '\n'
    //
    //  Note that the input chars are 1 based (UTF-8/ASCII) and are not 
    //  being used as indices (which you might expect to be zero based)
    //
    //  Default value is 0, which indicates an invalid escape
    const uint16_t escape_values[256] = {
        [34] = '"',
        [47] = '/',
        [92] = '\\',
        [98] = '\b',
        [102] = '\f',
        [110] = '\n',
        [114] = '\r',
        [116] = '\t'};
    
    unsigned char *p;
    uint16_t *output_data;
    bool shrink_string; //Set true when we reduce the # of characters in 
    //the string due to escapes or UTF-8 conversion
    int parse_status;
    int escape_value;
    int cur_index;
    uint16_t escape_char;
    
    //OPENMP LOOP
    for (int i = 0; i < n_entries; i++){
        
        p = char_p[i];
        output_data = all_cells_data[i];
        cur_index = -1;
        shrink_string = false;
        parse_status = STRING_PARSE_NOT_DONE;
        
        
        //This is where we put in the state machine
        //for now let's keep it simple ...
        //
        //Depending on length, we may want to try SIMD
        
        //Note, we could allow the user to specify a string processing
        //algorithm ...
        //1) Current
        //2) Assume no escapes, quick search for escapes
        //     then apply a memcpy
        
        //parse the current string
        //--------------------------
        while (!parse_status) {
            if (*p == '"'){
                parse_status = STRING_PARSE_DONE;
            }else if(*p == '\\'){
            	++p; //Move onto the next character that is escaped
                shrink_string = true;
                if (*p == 'u'){
                    output_data[++cur_index] = parse_escaped_unicode_char(&p,p,&parse_status);
                }else{
                    escape_char = escape_values[*p];
                    //Here 0 represents an in invalid escape
                    if(escape_char){
                        output_data[++cur_index] = escape_char;
                    }else{
                        parse_status = STRING_PARSE_INVALID_ESCAPE;
                    }   
                }
            }else if(*p > 127){
                //> 127 indicates non-ASCII
                shrink_string = true;
                output_data[++cur_index] = parse_utf8_char(&p,p,&parse_status);
            }else{
                //Just a regular old character to store   
                output_data[++cur_index] = *p;    
            }
            ++p;
        } // End of while statement ...
        
        //Handling output
        //------------------------------------------------
        if (parse_status == STRING_PARSE_DONE){
            if (shrink_string){
                //Don't we have pointers from above
                //no, we have pointers to data, not the cell
                mxSetN(mxGetCell(cell_array,i),cur_index+1);
            }
        }else{  
            //TODO: We need to throw errors with more context ...
            switch (parse_status){
                case STRING_PARSE_INVALID_ESCAPE:
                    mexErrMsgIdAndTxt("turtle_json:invalid_char_escape",
                        "Invalid character escape string");
                    break;
                case STRING_PARSE_INVALID_HEX:
                    mexErrMsgIdAndTxt("turtle_json:invalid_char_hex",
                        "Invalid hex character value");
                    break;
                case STRING_PARSE_NON_CONTINUED_UTF8:
                    //TODO: This needs more info ...
                    mexErrMsgIdAndTxt("turtle_json:invalid_utf8",
                        "Invalid non-continued UTF8");
                    break;
                case STRING_PARSE_INVALID_LONG_UTF8:
                    //TODO: This needs more info ...
                    mexErrMsgIdAndTxt("turtle_json:invalid_utf8",
                        "Invalid too long UTF8");
                    break;
                case STRING_PARSE_INVALID_FIRST_BYTE_UTF8:
                    //TODO: This needs more info ...
                    //>127 but not a continuation????
                    mexErrMsgIdAndTxt("turtle_json:invalid_utf8",
                        "Invalid first bytes UTF8");
                    break;    
                default:
                    mexErrMsgIdAndTxt("turtle_json:code_error",
                    "Unexpected error when parsing string");
            }
        }
    }

    mxFree(all_cells_data);
    
    //Storage of the data for later
    //---------------------------------------------------
    TOC(string_parse,time__string_parsing_time);
    mxSetFieldByNumber(plhs[0],0,E_strings,cell_array); 

}

uint16_t parse_escaped_unicode_char(unsigned char **pp, unsigned char *p, int *parse_status){
    
    
    //Outputs
    //pp - new location for pointer
    //parse_status
    //
    //Inputs    
    //p -starting point for pointer
    //
    //Returns
    //parsed character
    
    //Unicode escapes
    //---------------------------------------------------------------------
    //Input character
    //Output, numerical value to add, unless invalid then -1
    //e.g. a => 10 (hex a has value 10)
    //     C => 12 (hex C has value 12, handling lower and upper case)
    const int hex_numerical_values[256] = {
        [0 ... 47] = -1,
        [48] = 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, // '0 ... 9'
        [58 ... 64] = -1,
        [65] = 10, 11, 12, 13, 14, 15,      // 'A - F'
        [71 ... 96] = -1,
        [97] = 10, 11, 12, 13, 14, 15, 
        [103 ... 255] = -1};
            
    //      Things to parse:
    //      \t, \n <= escaped characters
    //      \u   <= unicode escape
    //      \u00C8 => È
    
    int hex_numerical_value; //TODO: This could be uint8_t

 //Process a unicode escape value e.g. \u00C8 => È
 //---------------------------------------------------------

     uint16_t unicode_char_value = 0;
     for (int iHex = 0; iHex < 4; iHex++){
         //Go from hex char to numerical value, e.g. from f to 15
         ++p;
         hex_numerical_value = hex_numerical_values[*p];
         //-1 is internal value for not valid
         //  (i.e. not 0-9,a-f, or A-F)
         // Couldn't use 0, as 0 is a valid value
         if (hex_numerical_value == -1){
             *parse_status == STRING_PARSE_INVALID_HEX;
             break;
         }else{
             unicode_char_value = (unicode_char_value << 4) + hex_numerical_value;
         }
     }
     *pp = p;
     return unicode_char_value;

}

uint16_t parse_utf8_char(unsigned char **pp, unsigned char *p, int *parse_status){
    //
    //
    //  This should be encapsulated by:
    //  if(*p > 127) - i.e. this should only be run if the ascii value is above 127
    //
    // 
    //
    //  Inputs
    //  ------
    //  p - pointer to first character (that is above 127)
    //  
    //  Outputs
    //  -------
    //  pp - pointer to next char after utf8 char
    //  parse_status
    // 
    //  Returns
    //  -------
    //  parsed UTF8 character as UTF-16 (ish?)
    //
    //  See Also
    //  --------
    //  parse_char_data

    //Implementation Details
    //===============================================
    //Inspect first byte to get # of bytes
    //2 bytes 110...   >> 5 == 6 - switch to 0b110
    //3 bytes 1110.... >> 4 == 14
    //4 bytes 11110... >> 3 == 30
    //are 5 & 6 valid?
    //
    //  Errors (parse status # listed)
    //  ---------------------------
    //- 10 - invalid first byte (currently no distinction
    //       between 5 & 6 bytes, or other alternatives:
    //       10... or 11111110 or 11111111
    //        
    //- 11 - invalid # of continuation bytes (given first byte)
    //       continuation byte is 10...
    //- 12 - not 2 byte compatible - TODO: Allow warning or 
    //       error, on warning, write value as whatever the
    //       unicode value is for not-representable or whatever
    //       the proper terminology is ..

    //TODO: technically we should check for null values
    //in each of the bytes, as this is not valid utf-8 
    //(overlong encoding)

    uint32_t utf8_value;
    
    //2 bytes
    //----------------------
    if ((*p >> 5) == 0b110){ 
        //# of bits in each byte
        //
        //  byte   # bits
        //  1      5
        //  2      6 
        //         11 total bits

        //Keep 5 bits of first byte
        utf8_value = *p & 0b11111;
        ++p;

        if (IS_CONTINUATION_BYTE){
            ADD_CONTINUATION_BYTE_VALUE;
            *pp = p;
            return (uint16_t) utf8_value;
        }else{
            //TODO: Make this a macro
            *parse_status = STRING_PARSE_NON_CONTINUED_UTF8;
            return ERROR_UTF_CHAR;
        }

    //3 bytes    
    }else if((*p >> 4) == 0b1110){
    //# of bits in each byte
    // byte     # bits
    //  1   ->  4
    //  2   ->  6
    //  3    -> 6   => 16 total bits => fits into 2 bytes
    //    
    //This also means that anything that is 4 bytes will
    //never be valid when stored as 2 bytes

        //With 3 byte utf-8, keep 4 bits
        utf8_value = *p & 0b1111;
        ++p;

        if (IS_CONTINUATION_BYTE){
            ADD_CONTINUATION_BYTE_VALUE;
            ++p;
            if (IS_CONTINUATION_BYTE){
                ADD_CONTINUATION_BYTE_VALUE;
                *pp = p;
                return (uint16_t) utf8_value;
            }else{
                *parse_status = 11;
                return ERROR_UTF_CHAR;
            }
        }else{
            *parse_status = 11;
            return ERROR_UTF_CHAR;
        }

    //4 bytes     
    }else if((*p >> 3) == 0b11110){
        //not 2 byte compatible
        //TODO: Need to verify that we have 3 continuation bytes ...
        p+=3;
        *pp = p;
        return UNREPRESENTABLE_UTF8_CHAR;
        //return ERROR_UTF_CHAR;
        //parse_status = 12;
        
    
    //TODO: We should explicitly check for 5 & 6 bytes
    //This is not utf-8, but it would help anyone that has
    //tried to use these high encoding values ...
    }else if((*p >> 2) == 0b111110){   
        *parse_status = STRING_PARSE_INVALID_LONG_UTF8;
        return ERROR_UTF_CHAR;
    }else{
        //mexPrintf("first byte: %d\n",*p);
        //invalid first byte
        *parse_status = STRING_PARSE_INVALID_FIRST_BYTE_UTF8;
        return ERROR_UTF_CHAR;
    }

}

void post_process(unsigned char *json_string,mxArray *plhs[], struct sdata *slog){
    
    TIC(start_pp);
    
    //mexPrintf("Object flags\n");
    //File: turtle_json_pp_objects.c
    TIC(object_parse);
    populate_object_flags(json_string,plhs,slog);
    TOC(object_parse,time__object_parsing_time);
    
    //mexPrintf("Key chars\n");
    //File: turtle_json_pp_objects.c
    TIC(init_objects)
    initialize_unique_objects(json_string,plhs,slog);
    TOC(init_objects,time__object_init_time);
    
    //mexPrintf("Array parse\n");
    TIC(array_parse);
    populate_array_flags(json_string,plhs,slog);
    TOC(array_parse,time__array_parsing_time);
    
    //mexPrintf("Number parase\n");
    TIC(number_parse);
    parse_numbers(json_string,plhs);
    TOC(number_parse,time__number_parsing_time);
    
    //mexPrintf("char data\n");
    //TIC(char_parse);
    //TODO: Break this up into parts
    //- string allocation
    //- 
    parse_char_data(json_string,plhs,slog);
    //TOC(char_parse,char_parsing_time);
        
    TOC(start_pp,time__total_elapsed_pp_time);  
    
}