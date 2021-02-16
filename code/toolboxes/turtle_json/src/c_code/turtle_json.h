#include "stdio.h" //fopen_s?
#include <stdlib.h>
#include <ctype.h>
#include "mex.h"        //Matlab mex
#include <math.h>
#include "stdint.h"     //uint_8
#include <string.h>     //strchr()
#include <time.h>       //clock()
#include <sys/time.h>   //for gettimeofday

//Name: turtle_json.h

#ifdef _WIN32
#include <windows.h> //QPC
#endif

//Added for tj_get_log_struct_as_mx
//Currently required for main program ...
#ifndef NO_OPENMP
#include <omp.h>        //openmp
#endif


#include "turtle_json_memory.h"
//TODO: Need to build in checks for support 
//SSE4.2
#include "nmmintrin.h"


//=========================================================================
//  Define Options
//  --------------
//
//  Note, the LOG options aren't that critical because I'm now writing
//  the times into a c-structure, rather than a Matlab structure, which is
//  way more memory efficient for scalars.
//
//  LOG_TIME - If defined no timing will occur. Internally I track a fair
//            amount of timing information and this disables the logging
//            behavior. For large files this is trivial but it may
//            add up for 1000s of small files.
//  LOG_ALLOC - NYI - goal is to be able to disable logging 
//              
//=========================================================================



//Note these must be related ...
//I'm not sure how to make this happen automatically ...
//
//Note we start at depth 0 for root 
//so a depth of 20 corresponds to 21 depths
#define MAX_DEPTH_ARRAY_LENGTH 21
#define MAX_DEPTH_ARRAY_LENGTH_BYTES 168
#define MAX_DEPTH 20

//TODO: This could be based on the threads. In general
//I haven't tested what a good cutoff is. Note this only has 
//a roughly 150 us overhead so it's not critical.
#define N_NUMBERS_FOR_PARALLEL 2001

//This is our guess for the # of unique objects. An object is unique
//if its field names are unique (order matters - i.e. 'a','b' is not 'b','a')
//
//See turtle_json_pp_objects.c
#define N_INITIAL_UNIQUE_OBJECTS 40


#define MAX_OPENMP_THREADS 16


//AVX
//#include "immintrin.h"


//TODO: Consider making these enumerations ...
//Type Definitions
//-------------------------------------------
#define TYPE_OBJECT 1
#define TYPE_ARRAY  2
#define TYPE_KEY    3
#define TYPE_STRING 4
#define TYPE_NUMBER 5
#define TYPE_NULL   6
#define TYPE_TRUE   7
#define TYPE_FALSE  8

//Array Flags
//-------------------------------------------
//see populate_array_flags
#define ARRAY_OTHER_TYPE   0 //Not one of the other types below - default
#define ARRAY_NUMERIC_TYPE 1 //1D numeric
#define ARRAY_STRING_TYPE  2 //1D string
#define ARRAY_LOGICAL_TYPE 3 //1D logical
#define ARRAY_OBJECT_SAME_TYPE  4 //All objects with same field names (order matters)
#define ARRAY_OBJECT_DIFF_TYPE 5 //All objects but with different field names (or order)
#define ARRAY_ND_NUMERIC 6 
#define ARRAY_ND_STRING 7
#define ARRAY_ND_LOGICAL 8
#define ARRAY_EMPTY_TYPE 9 //Array with no elements
#define ARRAY_ND_EMPTY 10


//String Parsing Flags
//-------------------------------------------
//
//  turtle_json_post_process.c
//  TODO: mention code that uses this ...
#define STRING_PARSE_NOT_DONE 0
#define STRING_PARSE_DONE 1
#define STRING_PARSE_INVALID_ESCAPE 2
#define STRING_PARSE_INVALID_HEX 3
#define STRING_PARSE_NON_CONTINUED_UTF8 4
#define STRING_PARSE_INVALID_LONG_UTF8 5
#define STRING_PARSE_INVALID_FIRST_BYTE_UTF8 6

//C Structure for fixed size output data
//-----------------------------------------------------
//
//This is a C structure for logging data. It gets put into "slog" in the
//output structure (shows up as an array of uint8). Using a C structure
//has much less memory and performance overhead than using a Matlab structure.
//
//If the user wishes to inspect this structure in Matlab it needs to be 
//converted to a Matlab structure. This can be done by passing the output
//from turtle_json_mex to json.utils.getMexC().
//
//***Updating this requires updating tj_get_log_struct_as_mx.c
//
//  See Also
//  tj_get_log_struct_ax_mx.c
struct sdata{
    int obj__n_objects_at_depth[MAX_DEPTH_ARRAY_LENGTH];
    int arr__n_arrays_at_depth[MAX_DEPTH_ARRAY_LENGTH];
	int buffer_added;
	int alloc__n_tokens_allocated;
	int alloc__n_objects_allocated;
	int alloc__n_arrays_allocated;
	int alloc__n_keys_allocated;
	int alloc__n_strings_allocated;
    int alloc__n_numbers_allocated;
    int alloc__n_data_allocations;
    int alloc__n_object_allocations;
    int alloc__n_array_allocations;
    int alloc__n_key_allocations;
    int alloc__n_string_allocations;
    int alloc__n_numeric_allocations;
    int obj__max_keys_in_object;
    int obj__n_unique_objects;
    double time__elapsed_read_time;
    double time__c_parse_init_time;
    double time__c_parse_time;
    double time__parsed_data_logging_time;
    double time__total_elapsed_parse_time;
    double time__object_parsing_time;
    double time__object_init_time;
    double time__array_parsing_time;
    double time__number_parsing_time;
    double time__string_memory_allocation_time;
    double time__string_parsing_time;
    double time__total_elapsed_pp_time;
    double time__total_elapsed_time_mex;
    double qpc_freq;
    int n_nulls;
    int n_tokens;
    int n_arrays;
    int n_numbers;
    int n_objects;
    int n_keys;
    int n_strings;
};

//Options structure
//-------------------------------------------------------
//  These are options that the parser can use to change parsing behavior.
//
//  TODO: Where are these defined. Potentially this should just be done here.
typedef struct {
   bool has_raw_string;
   bool has_raw_bytes;
   bool parse_strings;
   bool read_file_only;
   int n_tokens;
   int n_strings;
   int n_keys;
   int n_numbers;
   int chars_per_token;
} Options;

//TODO: Who uses this and why ...

//This used to make copies of cells or structures.
//
//  e.g. in Matlab code:
//  a = struct('b',2);
//  c.b = a.b %b is copied from a to c, so only 1 version exists
//  This would change on rewrite ...
//
//  Used by:
//  mxCreateReference -> json_info_to_data__utils.c
//  mxCreateReference -> turtle_json_mex_helpers.c



//Pretty sure this is not used, implementation doesn't exist
extern mxArray *mxCreateSharedDataCopy(const mxArray *pr);

//Created using prepStructs.m
//-------------------------------------------------
//Change this and fieldnames_out in turtle_json_mex simultaneously
//
//These are fields in the output mex strcture.
//
//When setting structure fields we set them by number. This is our
//numbering system. Turtle_json_mex defines the fieldnames (key strings) 
//of the structure.
enum OUT_FIELD {
     E_json_string,
     E_types,
     E_d1,
     E_obj__child_count_object,
     E_obj__next_sibling_index_object,
     E_obj__object_depths,
     E_obj__unique_object_first_md_indices,
     E_obj__object_ids,
     E_obj__objects,
     E_arr__child_count_array,
     E_arr__next_sibling_index_array,
     E_arr__array_depths,
     E_arr__array_types,
     E_key__key_p,
     E_key__key_sizes,
     E_key__next_sibling_index_key,
     E_string_p,
     E_string_sizes,
     E_numeric_p,
     E_strings,
     E_slog}; 

//For below since mxCreateStructMatrix requires a size input
#define ARRAY_SIZE(names) (sizeof(names)/sizeof((names)[0]))



//Consider renaming to STORE_MD_INDEX
#define STORE_DATA_INDEX(x) d1[current_data_index] = x;

#define RETRIEVE_DATA_INDEX(x) d1[x]

//TODO: I'd like to rename cur_key__key_index to cur_key_data_index
#define NEXT_KEY__KEY_INDEX(cur_key__key_index) \
        RETRIEVE_DATA_INDEX(next_sibling_index_key[cur_key__key_index])
/*
 *
 *  Example Usage:
 *  TIC(start_parse)
 *  //run parsing code
 *  TOC(start_parse,parsing_time)
 *
 *
 */

//mac ns
//https://stackoverflow.com/questions/361363/how-to-measure-time-in-milliseconds-using-ansi-c/37920181#37920181
        
//http://stackoverflow.com/questions/10673732/openmp-time-and-clock-calculates-two-different-results
//These two MACROS are meant to be used like TIC and TOC in Matlab
//These were added when I got an error declaring TIC(x) immediately
//after a label
 
//          DEFINE_TIC
//-----------------------------------
#ifdef LOG_TIME
    #ifdef _WIN32
        #define DEFINE_TIC(x)  \
        LARGE_INTEGER x ## _0; \
        LARGE_INTEGER x ## _1;  
    #else
        #define DEFINE_TIC(x)   \
        struct timeval x ## _0; \
        struct timeval x ## _1;    
    #endif
#else
    #define DEFINE_TIC(x) do {} while (0)      
#endif

//          START_TIC
//--------------------------------------------
#ifdef LOG_TIME   
    #ifdef _WIN32 
        #define START_TIC(x) QueryPerformanceCounter(&x##_0);
    #else    
        #define START_TIC(x) gettimeofday(&x##_0,NULL);
    #endif
#else
    #define START_TIC(x) do {} while (0) 
#endif    
    
//          TIC
//--------------------------------------------        
#ifdef LOG_TIME    
#define TIC(x) \
    DEFINE_TIC(x); \
    START_TIC(x);            
#else
#define TIC(x) do {} while (0)     
#endif    

//          TOC
//--------------------------------------------     
//x->name of structure
//y->output name
#ifdef LOG_TIME   
    #ifdef _WIN32 
        #define TOC(x,y) \
            QueryPerformanceCounter(&x##_1); \
            slog->y = (double)(x##_1.QuadPart - x##_0.QuadPart)*1000000;
    #else
        #define TOC(x,y) \
            gettimeofday(&x##_1,NULL); \
            slog->y = (double)(x##_1.tv_sec - x##_0.tv_sec) + (double)(x##_1.tv_usec - x##_0.tv_usec)/1e6;
    #endif
#else
#define TOC(x,y) do {} while (0)     
#endif

    
    
    
    
//This  should no longer be used because we're not adding
//any fields dynamically
#define ADD_STRUCT_FIELD(name,pointer) \
    mxAddField(plhs[0],#name); \
    mxSetField(plhs[0],0,#name,pointer);    
    
//Number Parsing
//-------------------------------------------------------------------------
void string_to_double(double *value_p, char *p, int i, int *error_p, int *error_value);

void string_to_double_v2(double *value_p, char *p, int i, int *error_p, int *error_value);

//Main parsing
//-------------------------------------------------------------------------
void parse_json(unsigned char *js, size_t len, mxArray *plhs[], Options *options, struct sdata *slog);

//

//Helpers
//-------------------------------------------------------------------------
mxArray *mxCreateReference(const mxArray *mx);

//http://stackoverflow.com/questions/18847833/is-it-possible-return-cell-array-that-contains-one-instance-in-several-cells

void setIntScalar(mxArray *s, const char *fieldname, int value);    
    
void setStructField2(mxArray *s, void *pr, mxClassID classid, mwSize N, int field_id);

void setStructField(mxArray *s, void *pr, const char *fieldname, mxClassID classid, mwSize N);

void *get_field(mxArray *plhs[],const char *fieldname);

mwSize get_field_length(mxArray *plhs[],const char *fieldname);

uint8_t *get_u8_field_by_number(mxArray *p, int fieldnumber);

uint8_t * get_u8_field(mxArray *p,const char *fieldname);

int *get_int_field_by_number(mxArray *p, int fieldnumber);

int *get_int_field(mxArray *p,const char *fieldname);

mwSize get_field_length2(mxArray *p,const char *fieldname);


//Post-processing related
//-------------------------------------------------------------------------
uint16_t parse_escaped_unicode_char(unsigned char **pp, unsigned char *p, int *parse_status);

uint16_t parse_utf8_char(unsigned char **pp, unsigned char *p, int *parse_status);

void populateProcessingOrder(int *process_order, uint8_t *types, int n_entries, 
        uint8_t type_to_match, int *n_values_at_depth, int n_depths, uint8_t *value_depths);

void post_process(unsigned char *js,mxArray *plhs[], struct sdata *slog);

//turtle_json_pp_objects.c
void populate_object_flags(unsigned char *js,mxArray *plhs[], struct sdata *slog);

//turtle_json_pp_objects.c
void initialize_unique_objects(unsigned char *js,mxArray *plhs[], struct sdata *slog);

void populate_array_flags(unsigned char *js,mxArray *plhs[], struct sdata *slog);

void parse_char_data(unsigned char *js,mxArray *plhs[], struct sdata *slog);

//turtle_json_number_parsing.c
void parse_numbers(unsigned char *js, mxArray *plhs[]);

