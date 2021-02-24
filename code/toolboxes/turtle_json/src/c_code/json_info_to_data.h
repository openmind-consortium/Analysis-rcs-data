#define MAX_ARRAY_DIMS 10

//  Name: json_info_to_data.h
    
// see populate_data in json_info_to_data.c
typedef struct {
    uint8_t *types;
    int *d1;
    int n_md_values;
    
    //This is for arrays
    mwSize *dims;
    
    int *child_count_object;
    int *next_sibling_index_object;
    int *object_ids;
    mxArray *objects;
    
    int *next_sibling_index_key;
    
    int *child_count_array;
    int *next_sibling_index_array;
    uint8_t *array_depths;
    uint8_t *array_types;
    
    mxArray *strings;
    
    double *numeric_data;
    
    mxArray *mxfalse;
    mxArray *mxtrue;
    mxArray *mxnan;
    
} Data;

typedef struct {
    int max_numeric_collapse_depth;
    int max_string_collapse_depth;
    int max_bool_collapse_depth;
    bool column_major;
    bool collapse_objects;
} FullParseOptions;

//Utils
//-------------------------------------------------------------------------
mxArray* getString(int *d1, mxArray *strings, int md_index);
mxArray* getNumber(Data data, int md_index);
mxArray* getNull(Data data, int md_index);
mxArray* getTrue(Data data, int md_index);
mxArray* getFalse(Data data, int md_index);

uint8_t* get_u8_field_safe(const mxArray *s,const char *fieldname);
int* get_int_field_safe(const mxArray *s,const char *fieldname);
int* get_int_field_and_length_safe(const mxArray *s,const char *fieldname,int *n_values);
mxArray* get_mx_field_safe(const mxArray *s,const char *fieldname);


void set_double_output(mxArray **s, double value);
mxArray* mxCreateReference(const mxArray *mx);

//Options
//-------------------------------------------------------------------------
FullParseOptions populate_parse_options(const mxArray *s);
FullParseOptions get_default_parse_options();

//Object related
//-------------------------------------------------------------------------
mxArray* get_initialized_struct(Data data, int object_data_index, 
        int n_objects);
void parse_object(Data data, mxArray *obj, int ouput_struct_index, 
        int object_md_index);
void parse_object_with_options(Data data, mxArray *obj, 
        int ouput_struct_index, int object_md_index, FullParseOptions *options);

//Array related
//-------------------------------------------------------------------------
mxArray* parse_array(Data data, int md_index);
mxArray* parse_non_homogenous_array(Data data, int array_data_index, 
        int array_md_index);
mxArray* parse_non_homogenous_array_with_options(Data data, int array_data_index, 
        int array_md_index, FullParseOptions *options);
mxArray *parse_array_with_options(Data data, int md_index, 
        FullParseOptions *options);
