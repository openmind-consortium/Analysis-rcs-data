#include "turtle_json.h"
#include "json_info_to_data.h"

mxArray* get_initialized_struct(Data data, int object_data_index, int n_objects){
    //
    //  The goal of this function is to allocate memory for the fields
    //  in a structure array. We take a reference structure that is empty
    //  but that has its fields defined, and we:
    //  1) duplicate it
    //  2) initialize its data - this part was tricky, since apparently
    //  the "data" of a structure array is an array of mxArrays, 1 for each
    //  field per object.
    
    int object_id = data.object_ids[object_data_index];
    mxArray *ref_object = mxGetCell(data.objects,object_id);
    //Copies the field names from one to the other
    mxArray *return_obj = mxDuplicateArray(ref_object);
    
    //Not sure which is better ...
    //int n_fields = data.child_count_object[object_data_index];
    int n_fields  = mxGetNumberOfFields(return_obj);
    
    mxArray **object_data = mxCalloc(n_fields*n_objects,sizeof(mxArray*));
    
    mxSetData(return_obj,object_data);
    
    mxSetN(return_obj,n_objects);
    return return_obj;
}

//=========================================================================
void parse_object(Data data, mxArray *obj, int ouput_struct_index, int object_md_index){
    //
    //  Inputs
    //  ------
    //  obj : the structure or structure array to populate
    //  ouput_struct_index : index in that structure
    //  md_index: TODO: rename to md_index
    //
    
    int object_data_index = data.d1[object_md_index];
    int n_keys = data.child_count_object[object_data_index];
        
    mxArray *temp_mxArray;
    
    const int *next_sibling_index_key = data.next_sibling_index_key;
    const uint8_t *types = data.types;
    
    int cur_key_md_index = object_md_index + 1;
    int cur_key_data_index = data.d1[cur_key_md_index];
    for (int iKey = 0; iKey < n_keys; iKey++){
        int cur_key_value_md_index = cur_key_md_index + 1;
        switch (types[cur_key_value_md_index]){
            case TYPE_OBJECT:
                temp_mxArray = get_initialized_struct(data,data.d1[cur_key_value_md_index],1);
                parse_object(data,temp_mxArray,0,cur_key_value_md_index);
                mxSetFieldByNumber(obj,ouput_struct_index,iKey,temp_mxArray);
                break;
            case TYPE_ARRAY:
                mxSetFieldByNumber(obj,ouput_struct_index,iKey,
                        parse_array(data,cur_key_value_md_index));
                break;
            case TYPE_KEY:
                mexErrMsgIdAndTxt("turtle_json:code_error",
                        "Found key type as child of key");
                break;
            case TYPE_STRING:
                mxSetFieldByNumber(obj,ouput_struct_index,iKey,getString(data.d1,data.strings,cur_key_value_md_index));
                break;
            case TYPE_NUMBER:
                mxSetFieldByNumber(obj,ouput_struct_index,iKey,getNumber(data,cur_key_value_md_index));
                break;
            case TYPE_NULL:
                mxSetFieldByNumber(obj,ouput_struct_index,iKey,getNull(data,cur_key_value_md_index));
                break;
            case TYPE_TRUE:
                mxSetFieldByNumber(obj,ouput_struct_index,iKey,getTrue(data,cur_key_value_md_index));
                break;
            case TYPE_FALSE:
                mxSetFieldByNumber(obj,ouput_struct_index,iKey,getFalse(data,cur_key_value_md_index));
                break;
        }
        cur_key_md_index = next_sibling_index_key[cur_key_data_index];
        cur_key_data_index = data.d1[cur_key_md_index];
    }
}
//=========================================================================
void parse_object_with_options(Data data, mxArray *obj, int ouput_struct_index, 
        int object_md_index, FullParseOptions *options){
    //
    //  Inputs
    //  ------
    //  obj : the structure or structure array to populate
    //  ouput_struct_index : index in that structure
    //  object_md_index: 
    //
    
    int object_data_index = data.d1[object_md_index];
    int n_keys = data.child_count_object[object_data_index];
        
    mxArray *temp_mxArray;
    
    const int *next_sibling_index_key = data.next_sibling_index_key;
    const uint8_t *types = data.types;
    
    int cur_key_md_index = object_md_index + 1;
    int cur_key_data_index = data.d1[cur_key_md_index];
    for (int iKey = 0; iKey < n_keys; iKey++){
        int cur_key_value_md_index = cur_key_md_index + 1;
        switch (types[cur_key_value_md_index]){
            case TYPE_OBJECT:
                temp_mxArray = get_initialized_struct(data,data.d1[cur_key_value_md_index],1);
                parse_object_with_options(data,temp_mxArray,0,cur_key_value_md_index, options);
                mxSetFieldByNumber(obj,ouput_struct_index,iKey,temp_mxArray);
                break;
            case TYPE_ARRAY:
                mxSetFieldByNumber(obj,ouput_struct_index,iKey,
                        parse_array_with_options(data,cur_key_value_md_index,options));
                break;
            case TYPE_KEY:
                mexErrMsgIdAndTxt("turtle_json:code_error","Found key type as child of key");
                break;
            case TYPE_STRING:
                mxSetFieldByNumber(obj,ouput_struct_index,iKey,getString(data.d1,data.strings,cur_key_value_md_index));
                break;
            case TYPE_NUMBER:
                mxSetFieldByNumber(obj,ouput_struct_index,iKey,getNumber(data,cur_key_value_md_index));
                break;
            case TYPE_NULL:
                mxSetFieldByNumber(obj,ouput_struct_index,iKey,getNull(data,cur_key_value_md_index));
                break;
            case TYPE_TRUE:
                mxSetFieldByNumber(obj,ouput_struct_index,iKey,getTrue(data,cur_key_value_md_index));
                break;
            case TYPE_FALSE:
                mxSetFieldByNumber(obj,ouput_struct_index,iKey,getFalse(data,cur_key_value_md_index));
                break;
        }
        cur_key_md_index = next_sibling_index_key[cur_key_data_index];
        cur_key_data_index = data.d1[cur_key_md_index];
    }
}