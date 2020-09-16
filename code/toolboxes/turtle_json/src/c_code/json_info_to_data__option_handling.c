#include "turtle_json.h"
#include "json_info_to_data.h"

double get_double_option_field(const mxArray *s, const char *field_name, double default_value){
    //
    //  This function retrieves a double scalar from a structure, and if
    //  the field is missing or contains an empty array, returns the
    //  default value.
    
    mxArray *field = mxGetField(s,0,field_name);
    if (field != NULL){
        if (mxIsClass(field,"double")){
            if (mxIsEmpty(field)){
                return default_value;
            }else{
                return mxGetScalar(field);
            }
        }else{
        	mexErrMsgIdAndTxt("turtle_json:invalid_input",
                    "Invalid type (non-double) for optional field: %s",field_name);
        }
    }
    else{
        return default_value;
    }
}

bool get_bool_option_field(const mxArray *s,const char *field_name, bool default_value){
    //
    //
    //
    
    mxArray *field = mxGetField(s,0,field_name);
    if (field != NULL){
     	if (mxIsEmpty(field)){
            return default_value;
      	}else if (mxIsClass(field,"double")){
            return (bool) mxGetScalar(field);
        }else if (mxIsClass(field,"logical")){
            bool *data  = mxGetLogicals(field);
//             mexPrintf("wtf: %d\n",data);
//             mexPrintf("wtf2: %d\n",*data);
            return *data;
        }else{
        	mexErrMsgIdAndTxt("turtle_json:invalid_input",
                    "Invalid type (non-logical or non-double) for optional field");
        }
    }
    else{
        return default_value;
    }
}


FullParseOptions get_default_parse_options(){
    FullParseOptions options;
    options.max_numeric_collapse_depth = -1;
    options.max_string_collapse_depth = -1;
    options.max_bool_collapse_depth = -1;
    options.column_major = 1;
    options.collapse_objects = 1;
}

FullParseOptions populate_parse_options(const mxArray *s){

    FullParseOptions options; 
    
    //TODO: Replace with defaults and only update the value
    //i.e. change the above functions to take in pointers and update
    //from default only if necessary - so that the default values
    //aren't in 2 locations

    options.max_numeric_collapse_depth = (int)get_double_option_field(s,"max_numeric_collapse_depth",-1);
    options.max_string_collapse_depth = (int)get_double_option_field(s,"max_string_collapse_depth",-1);
    options.max_bool_collapse_depth = (int)get_double_option_field(s,"max_bool_collapse_depth",-1);
    options.column_major = get_bool_option_field(s,"column_major",1);
    options.collapse_objects = get_bool_option_field(s,"collapse_objects",1);
    
    return options;
    
}