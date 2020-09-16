#include "turtle_json.h"

//File: turtle_json_pp_objects.c

//In this file:
//-------------
//- populate_object_flags - called by post_process() in turtle_json_post_process.c
//- initialize_unique_objects - called by post_process() in turtle_json_post_process.c
//
//


//=========================================================================
//=========================================================================
void initialize_unique_objects(unsigned char *js,mxArray *plhs[], struct sdata *slog){
    //
    //  This code will initialize unique objects (structures) with keys, 
    //  based on already having identified unique objects earlier.
    //
    //  This function populates
    //  -----------------------
    //  objects : cell array of empty structs with fields
    
    
    int n_unique_objects = slog->obj__n_unique_objects;
    
    if (n_unique_objects == 0){
        return;
    }
    
    int *d1 = get_int_field_by_number(plhs[0],E_d1);
    
    mxArray *object_info = plhs[0];
    
    int *child_count_object = get_int_field_by_number(object_info,E_obj__child_count_object);    
    int *unique_object_first_md_indices = get_int_field_by_number(object_info,E_obj__unique_object_first_md_indices);
    
    int max_keys_in_object = slog->obj__max_keys_in_object;
    
    if (max_keys_in_object == 0){
        //We have at least one objects, but none of the objects have keys
        //Create a single unique object with no fields ...
        mxArray *all_objects = mxCreateCellMatrix(1,1);
        mxArray *s = mxCreateStructMatrix(1,0,0,0);
        mxSetCell(all_objects, 0, s);
        mxSetFieldByNumber(object_info,0,E_obj__objects,all_objects);
        return;
    }
    
    //TODO: Define this here ...
    int *object_ids = get_int_field_by_number(object_info,E_obj__object_ids);
     
    mxArray *key_info = plhs[0];
    mxArray *temp_key_p = mxGetFieldByNumber(key_info,0,E_key__key_p);
    
    unsigned char **key_p = (unsigned char **)mxGetData(temp_key_p);
    
    
    int *key_sizes = get_int_field_by_number(key_info,E_key__key_sizes);
    int *next_sibling_index_key = get_int_field_by_number(key_info,E_key__next_sibling_index_key);
    
    //Note, Matlab does a deep copy of this field, so we are only
    //allocating a temporary array, note the final values.
    const char **fieldnames = mxMalloc(max_keys_in_object*sizeof(char *));
    
    //This is the output, stored in our output structure as "objects"
    mxArray *all_objects = mxCreateCellMatrix(1, n_unique_objects);
     
    mxArray *s;
    
    unsigned char *cur_key_p;
    int cur_key_md_index;
    int cur_key_data_index;
    int cur_key_size;
    int temp_key_index;
    
    int cur_object_md_index;
    int cur_object_data_index;
    int n_keys_in_object;
    
    //  For each unique object, get an example object and grab the fields
    //  of that object.
    
    for (int iObj = 0; iObj < n_unique_objects; iObj++){   
        cur_object_md_index = unique_object_first_md_indices[iObj];
        cur_object_data_index = d1[cur_object_md_index]; 
        n_keys_in_object = child_count_object[cur_object_data_index];

        cur_key_md_index = cur_object_md_index + 1;
        cur_key_data_index = d1[cur_key_md_index];
                
        for (int iKey = 0; iKey < n_keys_in_object; iKey++){
            cur_key_p = key_p[cur_key_data_index];
            cur_key_size = key_sizes[cur_key_data_index];
                        
            //JAH Notes 2018-09
            //1) This is modifying the original the JSON string
            //   which should be documented ...
            //      - we could fix this by writing the " back in
            //      - "my_string" => "my_string\0 => "my_string"
            //      - Matlab is deep copying the strings in
            //        mxCreateStructMatrix
            //2) We are not parsing for UTF-8, Matlab only supports
            //   ASCII for fields, this should be documented
            
            //At a minimum, we'll zero out the key to specify length
            //for Matlab. Matlab takes in an array of pointers to 
            //null-terminated strings rather than allowing us to specify
            //the size. So here we add null termination into the string.
            //Note that we are always zeroing a terminating quote symbol.
            *(cur_key_p + cur_key_size) = 0;
            
            fieldnames[iKey] = cur_key_p;
            
            //TODO: It is not obvious how the next sibling behaves at the
            //end - comment on this here ...
            cur_key_md_index = next_sibling_index_key[cur_key_data_index];
            cur_key_data_index = d1[cur_key_md_index];            
        }
        
        //We'll initialize as empty here, because we don't get much of 
        //an advantage of preinitializing if we are going to chop this up later
        //Initialing to zero still logs the field names
        //Any advantage of 1,0 vs 0,0?, vs even 1,1?
        //1,1 might be good if we only have 1 example, then we could
        //just use it later ... - this would require counting how many
        //objects take on this value ...
        s = mxCreateStructMatrix(1,0,n_keys_in_object,fieldnames);
        mxSetCell(all_objects, iObj, s);
    }
    
    mxFree(fieldnames);
    mxSetFieldByNumber(object_info,0,E_obj__objects,all_objects);
    
}
//=====================      End of Key Processing    =====================
//=========================================================================


//=========================================================================
void populate_object_flags(unsigned char *js,mxArray *plhs[], struct sdata *slog){
    //
    //  For each object, identify which "unique" object it belongs to and
    //  which index it has in that object.
    //
    //  Populates (into object_info structure)
    //  ---------------------------------------
    //  max_keys_in_object
    //  n_uniqe_objects: scalar 
    //  object_ids: array
    //  unique_object_first_md_indices: array
    //
    
    mxArray *object_info = plhs[0]; //mxGetField(plhs[0],0,"object_info");
    
    //TODO: Change this to numeric ...
    int n_objects = get_field_length2(object_info,"obj__next_sibling_index_object");
    
    if (n_objects == 0){
        slog->obj__n_unique_objects = 0;
        setStructField2(object_info,0,mxINT32_CLASS,0,E_obj__object_ids); 
        return;
    }
    
    
    //Main data info
    //-------------------------------------
    uint8_t *types = get_u8_field_by_number(plhs[0],E_types);
    int *d1 = get_int_field_by_number(plhs[0],E_d1);
    
    //TODO: Change this to numeric ...
    mwSize n_entries = get_field_length(plhs,"d1");

    //Information needed for this processing
    //---------------------------------------------------------------------
    //Object related
    uint8_t *object_depths = get_u8_field_by_number(object_info,E_obj__object_depths);
    int *child_count_object = get_int_field_by_number(object_info,E_obj__child_count_object);
    int *next_sibling_index_object = get_int_field_by_number(object_info,E_obj__next_sibling_index_object);
    int *n_objects_at_depth = slog->obj__n_objects_at_depth;
    
    mwSize n_depths = MAX_DEPTH_ARRAY_LENGTH; //get_field_length2(object_info,"n_objects_at_depth");
    
    //Some initial - meta setup
    //---------------------------------------------------------------------
    int *process_order = mxMalloc(n_objects*sizeof(int));
    populateProcessingOrder(process_order, types, n_entries, TYPE_OBJECT, n_objects_at_depth, n_depths, object_depths);
    
    //What is the max # of keys per object?
    int max_children = 0;
    for (int iObject = 0; iObject < n_objects; iObject++){
        if (child_count_object[iObject] > max_children){
            max_children = child_count_object[iObject];
        }
    }
    slog->obj__max_keys_in_object = max_children;
    
    if (max_children == 0){
        //So we only have an empty object
        int *unique_object_first_md_indices = mxMalloc(1*sizeof(int));
        unique_object_first_md_indices[0] = process_order[0];
        int *object_ids = mxCalloc(n_objects,sizeof(int));
        
    	setStructField2(object_info,unique_object_first_md_indices,
                mxINT32_CLASS,1,E_obj__unique_object_first_md_indices);
        setStructField2(object_info,object_ids,mxINT32_CLASS,n_objects,E_obj__object_ids); 
        slog->obj__n_unique_objects = 1;
        return;
    }

    //Key related
    //---------------------------------
    mxArray *key_info = plhs[0];
    mxArray *temp_key_p = mxGetFieldByNumber(key_info,0,E_key__key_p);
    unsigned char **key_p = (unsigned char **)mxGetData(temp_key_p);
    int *key_sizes = get_int_field_by_number(key_info,E_key__key_sizes);
    int *next_sibling_index_key = get_int_field_by_number(key_info,E_key__next_sibling_index_key); 

    //These are our outputs
    //---------------------------------------------------------------------
    //Which unique object, each object entry belongs to
    int *object_ids = mxMalloc(n_objects*sizeof(int));
    
    int n_unique_allocated;
    if (n_objects > N_INITIAL_UNIQUE_OBJECTS){
        n_unique_allocated = N_INITIAL_UNIQUE_OBJECTS;
    }else{
        n_unique_allocated = n_objects;
    }
        
    //We need this so that later we can go back and parse the keys
    //TODO: We could technically parse the keys right away ...
    int *unique_object_first_md_indices = mxMalloc(n_unique_allocated*sizeof(int));
    //---------------------------------------------------------------------
    
    //Variables for the loop 
    int cur_object_id = -1; //-1, allows incrementing into current value

    //po - process order
    int cur_po_index = 0; 
    int cur_object_md_index;
    int cur_object_data_index;
    
    int cur_key_data_index;
    int temp_key_md_index;
    int n_keys_current_object;
    
    int *object_key_sizes = mxMalloc(max_children*sizeof(int));
    unsigned char **object_key_pointers = mxMalloc(max_children*sizeof(unsigned char *));
    
    
    int last_obj_iter = -1;
    
    bool done = false;
    bool diff_object;
    
    //  Main Loop
    //---------------------------------------------------------------------
    while (!done){
        
        //Creation of a Reference Object
        //-----------------------------------------------------------------
        // - other objects will be compared to this object
        cur_object_md_index = process_order[cur_po_index];
        cur_object_data_index = RETRIEVE_DATA_INDEX(cur_object_md_index);
        n_keys_current_object = child_count_object[cur_object_data_index];
        
        object_ids[cur_object_data_index] = ++cur_object_id;
        
        //Logging of unique_object_first_data_indices
        //Technically we could post-process this bit ...
        //i.e. after assigning all objects unique ids, run through
        //and populate unique_object_first_data_indices
        if (cur_object_id >= n_unique_allocated){
            n_unique_allocated = 2*n_unique_allocated;
            if (n_unique_allocated > n_objects){
                n_unique_allocated = n_objects;
            }
            unique_object_first_md_indices = mxRealloc(unique_object_first_md_indices,
                    n_unique_allocated*sizeof(int));
        }
        
        unique_object_first_md_indices[cur_object_id] = cur_object_md_index; 


        //-----------------------------------------------------------------
        //Store key information for comparison to other objects ...
        //-----------------------------------------------------------------
        cur_key_data_index = RETRIEVE_DATA_INDEX((cur_object_md_index + 1));
        for (int iKey = 0; iKey < n_keys_current_object; iKey ++){
            object_key_sizes[iKey] = key_sizes[cur_key_data_index];
            object_key_pointers[iKey] = key_p[cur_key_data_index];
            
            temp_key_md_index = next_sibling_index_key[cur_key_data_index];
            cur_key_data_index = RETRIEVE_DATA_INDEX(temp_key_md_index);
        }
        
        //-----------------------------------------------------------------
        //      Loop through the other objects and compare
        //-----------------------------------------------------------------
        diff_object = false;
        while (!diff_object){
            ++cur_po_index;
            if (cur_po_index == n_objects){
                done = true;
                break;
            }
            
            cur_object_md_index = process_order[cur_po_index];
            cur_object_data_index = RETRIEVE_DATA_INDEX(cur_object_md_index);
            
            if (n_keys_current_object == child_count_object[cur_object_data_index]){
                
                //TODO
                //It might be better to combine these two loops
                
                //Here we check if the keys are the same length
                //---------------------------------------------------------
                cur_key_data_index = RETRIEVE_DATA_INDEX((cur_object_md_index + 1));
                for (int iKey = 0; iKey < n_keys_current_object; iKey ++){
                    if (object_key_sizes[iKey] != key_sizes[cur_key_data_index]){
                        diff_object = true;
                        break;
                    }
                    temp_key_md_index = next_sibling_index_key[cur_key_data_index];
                    cur_key_data_index = RETRIEVE_DATA_INDEX(temp_key_md_index);
                }    
                
                //Here we check if the key values are the same
                //---------------------------------------------------------
                if (!diff_object){
                    cur_key_data_index = RETRIEVE_DATA_INDEX((cur_object_md_index + 1));
                    for (int iKey = 0; iKey < n_keys_current_object; iKey ++){
                        
                        if (memcmp(object_key_pointers[iKey],
                                key_p[cur_key_data_index],object_key_sizes[iKey])){
                            diff_object = true;
                            break;
                        };
                        temp_key_md_index = next_sibling_index_key[cur_key_data_index];
                        cur_key_data_index = RETRIEVE_DATA_INDEX(temp_key_md_index);
                    }  
                }
                
                if (!diff_object){
                    object_ids[cur_object_data_index] = cur_object_id;
                }
                
            }else{
                diff_object = true;
            }
        }   
    }
    
    mxFree(object_key_pointers);
    mxFree(object_key_sizes);
    mxFree(process_order);
    
    //TODO: We could truncate these ...
    //TODO: Change to #2 method with enumeration ...
    setStructField2(object_info,unique_object_first_md_indices,
            mxINT32_CLASS,cur_object_id+1,E_obj__unique_object_first_md_indices);    
    setStructField2(object_info,object_ids,
            mxINT32_CLASS,n_objects,E_obj__object_ids); 
    slog->obj__n_unique_objects = cur_object_id+1;
}