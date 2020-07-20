//TODO: Move the storage code here as well ...

//=========================================================================
//              Data Allocation and index advancement
//=========================================================================  

//Comment out to test with no memory checks
//This should only be done for files that we know won't cause memory
//reallocations ...
#define MEM_CHECK 1

#define INITIALIZE_MAIN_DATA \
    uint8_t *types = mxMalloc(data_size_allocated); \
    int *d1 = mxMalloc(data_size_allocated * sizeof(int)); 


#ifdef MEM_CHECK
#define INCREMENT_MD_INDEX \
    ++current_data_index; \
	if (current_data_index > data_size_index_max){ \
        ++n_data_allocations; \
        data_size_allocated = ceil(1.5*data_size_allocated); \
        data_size_index_max = data_size_allocated-1; \
        \
        types = mxRealloc(types,data_size_allocated); \
        d1 = mxRealloc(d1,data_size_allocated*sizeof(int)); \
    }
#else
#define INCREMENT_MD_INDEX ++current_data_index;    
#endif
    
#define TRUNCATE_MAIN_DATA \
    types = mxRealloc(types,(current_data_index + 1)); \
    d1 = mxRealloc(d1,(current_data_index + 1)*sizeof(int));         
    
//-----------------   Object Memory Management ----------------------------
#define INITIALIZE_OBJECT_DATA \
    int *child_count_object = mxMalloc(object_size_allocated * sizeof(int)); \
    int *next_sibling_index_object = mxMalloc(object_size_allocated * sizeof(int)); \
    uint8_t *object_depths = mxMalloc(object_size_allocated);   

#ifdef MEM_CHECK    
#define INCREMENT_OBJECT_INDEX \
    ++current_object_index; \
    if (current_object_index > object_size_index_max){ \
        ++n_object_allocations; \
        object_size_allocated = ceil(1.5*object_size_allocated); \
        object_size_index_max = object_size_allocated - 1; \
        child_count_object = mxRealloc(child_count_object,object_size_allocated * sizeof(int)); \
        next_sibling_index_object = mxRealloc(next_sibling_index_object,object_size_allocated * sizeof(int)); \
     	object_depths = mxRealloc(object_depths,object_size_allocated*sizeof(uint8_t)); \
    }
#else
#define INCREMENT_OBJECT_INDEX ++current_object_index;
#endif

    
#define TRUNCATE_OBJECT_DATA \
    child_count_object = mxRealloc(child_count_object,(current_object_index + 1) * sizeof(int)); \
    next_sibling_index_object = mxRealloc(next_sibling_index_object,(current_object_index + 1) * sizeof(int)); \
    object_depths = mxRealloc(object_depths,(current_object_index + 1)*sizeof(uint8_t));
    
//-----------------  Array Memory Management  ------------------
#define INITIALIZE_ARRAY_DATA \
    int *child_count_array = mxMalloc(array_size_allocated * sizeof(int)); \
    int *next_sibling_index_array = mxMalloc(array_size_allocated * sizeof(int)); \
    uint8_t *array_depths = mxMalloc(array_size_allocated);        

#ifdef MEM_CHECK    
#define INCREMENT_ARRAY_INDEX \
    ++current_array_index; \
    if (current_array_index > array_size_index_max){ \
        ++n_array_allocations; \
        array_size_allocated = ceil(1.5*array_size_allocated); \
        array_size_index_max = array_size_allocated - 1; \
        child_count_array = mxRealloc(child_count_array,array_size_allocated * sizeof(int)); \
        next_sibling_index_array = mxRealloc(next_sibling_index_array,array_size_allocated * sizeof(int)); \
        array_depths = mxRealloc(array_depths,array_size_allocated*sizeof(uint8_t)); \
    }
#else
#define INCREMENT_ARRAY_INDEX ++current_array_index;
#endif    
    
#define TRUNCATE_ARRAY_DATA \
    child_count_array = mxRealloc(child_count_array,(current_array_index + 1) * sizeof(int)); \
    next_sibling_index_array = mxRealloc(next_sibling_index_array,(current_array_index + 1) * sizeof(int)); \
    array_depths = mxRealloc(array_depths,(current_array_index + 1)*sizeof(uint8_t));
    
//-----------------   Key Memory Management ------------------------------- 
#define INITIALIZE_KEY_DATA \
    unsigned char **key_p = mxMalloc(key_size_allocated * sizeof(unsigned char *)); \
    int *key_sizes =  mxMalloc(key_size_allocated * sizeof(int)); \
    int *next_sibling_index_key = mxMalloc(key_size_allocated * sizeof(int));
 
#ifdef MEM_CHECK    
#define INCREMENT_KEY_INDEX \
    ++current_key_index; \
    if (current_key_index > key_size_index_max) { \
        ++n_key_allocations; \
        key_size_allocated = ceil(1.5*key_size_allocated); \
        key_size_index_max = key_size_allocated - 1; \
        key_p = mxRealloc(key_p,key_size_allocated * sizeof(unsigned char *)); \
        key_sizes = mxRealloc(key_sizes,key_size_allocated * sizeof(int)); \
        next_sibling_index_key = mxRealloc(next_sibling_index_key,key_size_allocated * sizeof(int)); \
    }
#else
#define INCREMENT_KEY_INDEX ++current_key_index;
#endif 
    
#define TRUNCATE_KEY_DATA \
    key_p = mxRealloc(key_p,(current_key_index + 1)*sizeof(unsigned char *)); \
    key_sizes = mxRealloc(key_sizes,(current_key_index + 1) * sizeof(int)); \
    next_sibling_index_key = mxRealloc(next_sibling_index_key,(current_key_index + 1) * sizeof(int));
    
//-----------------   String Memory Management ----------------------------    
#define INITIALIZE_STRING_DATA \
    unsigned char **string_p = mxMalloc(string_size_allocated * sizeof(unsigned char *)); \
    int *string_sizes = mxMalloc(string_size_allocated * sizeof(int));

#ifdef MEM_CHECK    
#define INCREMENT_STRING_INDEX \
    ++current_string_index; \
    if (current_string_index > string_size_index_max) { \
        ++n_string_allocations; \
        string_size_allocated = ceil(1.5*string_size_allocated); \
        string_size_index_max = string_size_allocated - 1; \
        string_p = mxRealloc(string_p,string_size_allocated * sizeof(unsigned char *)); \
        string_sizes = mxRealloc(string_sizes,string_size_allocated * sizeof(int)); \
    }
#else
#define INCREMENT_STRING_INDEX ++current_string_index;
#endif 
    
#define TRUNCATE_STRING_DATA \
    string_p = mxRealloc(string_p,(current_string_index + 1)*sizeof(unsigned char *)); \
	string_sizes = mxRealloc(string_sizes,(current_string_index + 1) * sizeof(int));
    
//-----------------   Numeric Memory Management ---------------------------
#define INITIALIZE_NUMERIC_DATA unsigned char **numeric_p = mxMalloc(numeric_size_allocated * sizeof(unsigned char *));  

#ifdef MEM_CHECK    
#define INCREMENT_NUMERIC_INDEX \
    ++current_numeric_index; \
    if (current_numeric_index > numeric_size_index_max) { \
        ++n_numeric_allocations; \
        numeric_size_allocated = ceil(1.5*numeric_size_allocated); \
        numeric_size_index_max = numeric_size_allocated - 1; \
        numeric_p = mxRealloc(numeric_p,numeric_size_allocated * sizeof(unsigned char *)); \
    }
#else
#define INCREMENT_NUMERIC_INDEX ++current_numeric_index;
#endif     
    
#define TRUNCATE_NUMERIC_DATA \
    numeric_p = mxRealloc(numeric_p,(current_numeric_index + 1)*sizeof(unsigned char *));
    