#include "turtle_json.h"

/*
 *  This file does the initial parsing of the file. After the parse_json()
 *  function has run, we know how many objects, arrays, etc. that we have
 *  and where they are located. Code in this file does not translate 
 *  characters into strings or numbers.
 *
 */

//=========================================================================
//=========================================================================
// The main code is essentially a state machine. States within the machine
// have the following rough layout:
//
//      1) key or array specific initialization code
//      2) common processing
//      3) navigation to the next state
//    

#define PRINT_CURRENT_POSITION mexPrintf("Current Position: %d\n",CURRENT_INDEX);
#define PRINT_CURRENT_CHAR  mexPrintf("Current Char: %c\n",CURRENT_CHAR);
   
//===================  Index functions  ===================================


//===================    Opening    [ { :    ==============================
#define INCREMENT_PARENT_SIZE \
    parent_sizes[current_depth] += 1
            
//example types include object, array, string, etc.            
#define SET_TYPE(x) \
    types[current_data_index] = x;            

//OA => stands for object/array
//1) Increase deapth
//2) set type -> object or array
//3) set index -> ??? Why is this needed????
//4) reset parent size
#define INITIALIZE_PARENT_INFO_OA(x) \
        ++current_depth; \
        if (current_depth > MAX_DEPTH){\
            goto S_ERROR_DEPTH_EXCEEDED; \
        }\
        parent_types[current_depth] = x; \
        parent_indices[current_depth] = current_data_index; \
        parent_sizes[current_depth] = 0;

//key does not care about size, size = 1
//=> parent type (x) could be hardcoded here ... (it is always key!)
#define INITIALIZE_PARENT_INFO_KEY(x) \
        ++current_depth; \
        if (current_depth > MAX_DEPTH){\
            goto S_ERROR_DEPTH_EXCEEDED; \
        }\
        parent_types[current_depth] = x; \
        parent_indices[current_depth] = current_data_index;        

//PROCESS_OPENING_ARRAY        
#define LOG_ARRAY_DEPTH \
        array_depths[current_array_index] = current_depth; \
        n_arrays_at_depth[current_depth] += 1;
        
#define LOG_OBJECT_DEPTH \
        object_depths[current_object_index] = current_depth; \
        n_objects_at_depth[current_depth] += 1;          
    
//========================      Closing     ===============================
#define RETRIEVE_CURRENT_PARENT_INDEX \
    current_parent_data_index = parent_indices[current_depth];
    
//Origin of +1 => points to element after current index
//TODO: We might want to redefine the sibling index to point to 
//The next value at the same level -> i.e. instead of current_data_index
// use something like cur_key_index, etc.
// - I think this redefinition might be most useful for keys
// - probably needs to stay this way for arrays
#define STORE_NEXT_SIBLING_OF_OBJECT \
    next_sibling_index_object[d1[current_parent_data_index]] = current_data_index + 1;

#define STORE_NEXT_SIBLING_OF_ARRAY \
    next_sibling_index_array[d1[current_parent_data_index]] = current_data_index + 1;
 
#define STORE_NEXT_SIBLING_KEY_COMPLEX \
    next_sibling_index_key[d1[current_parent_data_index]] = current_data_index + 1;
    
//This is called before the simple value, so we need to advance to the simple
//value and then do the next value (i.e the token after close)
//Note that we're working with the current_data_index since we haven't
//advanced it yet and don't need to rely on a parent index (which hasn't even
//been set since the value is simple)
#define STORE_NEXT_SIBLING_KEY_SIMPLE \
    next_sibling_index_key[current_key_index] = current_data_index + 2;
   
#define STORE_SIZE_OBJECT \
    child_count_object[d1[current_parent_data_index]] = parent_sizes[current_depth];
    
#define STORE_SIZE_ARRAY \
    child_count_array[d1[current_parent_data_index]] = parent_sizes[current_depth];    
        
#define MOVE_UP_PARENT_INDEX --current_depth;

#define IS_NULL_PARENT_INDEX current_depth == 0     
            
#define PARENT_TYPE parent_types[current_depth]         
        
//=========================================================================
//=================          Processing      ==============================
//=========================================================================
#define PROCESS_OPENING_OBJECT \
    INCREMENT_MD_INDEX; \
    INCREMENT_OBJECT_INDEX; \
    SET_TYPE(TYPE_OBJECT); \
    STORE_DATA_INDEX(current_object_index); \
    INITIALIZE_PARENT_INFO_OA(TYPE_OBJECT); \
    LOG_OBJECT_DEPTH;
    
#define PROCESS_OPENING_ARRAY \
    INCREMENT_MD_INDEX; \
    INCREMENT_ARRAY_INDEX; \
    SET_TYPE(TYPE_ARRAY); \
    STORE_DATA_INDEX(current_array_index); \
    INITIALIZE_PARENT_INFO_OA(TYPE_ARRAY); \
    LOG_ARRAY_DEPTH;        

#define PROCESS_STRING \
    INCREMENT_STRING_INDEX; \
    INCREMENT_MD_INDEX; \
    SET_TYPE(TYPE_STRING); \
    temp_p = CURRENT_POINTER; \
    /* +1 to point past the opening quote */ \
    string_p[current_string_index] = CURRENT_POINTER + 1; \
    STORE_DATA_INDEX(current_string_index); \
    seek_string_end(CURRENT_POINTER,&CURRENT_POINTER); \
    string_sizes[current_string_index] = CURRENT_POINTER - string_p[current_string_index]; \

#define PROCESS_KEY_NAME \
    INCREMENT_KEY_INDEX; \
    INCREMENT_MD_INDEX; \
    /* Parent info initialization now done in key values */ \
    SET_TYPE(TYPE_KEY); \
    /* We want to skip the opening quotes so + 1 */ \
    key_p[current_key_index] = CURRENT_POINTER + 1; \
    STORE_DATA_INDEX(current_key_index); \
    seek_string_end(CURRENT_POINTER,&CURRENT_POINTER); \
    /* We won't count the closing quote, but we would normally add 1 to */ \
    /* be inclusive on a count, so they cancel out */ \
    key_sizes[current_key_index] = CURRENT_POINTER - key_p[current_key_index]; \

            
// See Also:
// S_PARSE_NUMBER_IN_KEY
// S_PARSE_NUMBER_IN_ARRAY
#define PROCESS_NUMBER \
    INCREMENT_NUMERIC_INDEX; \
    INCREMENT_MD_INDEX; \
    SET_TYPE(TYPE_NUMBER); \
    numeric_p[current_numeric_index] = CURRENT_POINTER; \
    STORE_DATA_INDEX(current_numeric_index); \
    string_to_double_no_math(CURRENT_POINTER, &CURRENT_POINTER);    
    
#define PROCESS_NULL \
    ++n_nulls; \
    INCREMENT_NUMERIC_INDEX; \
    INCREMENT_MD_INDEX; \
    SET_TYPE(TYPE_NULL); \
    numeric_p[current_numeric_index] = 0; \
    STORE_DATA_INDEX(current_numeric_index); \
    /*TODO: Add null check ... */ \
	ADVANCE_POINTER_BY_X(3)    
           
#define PROCESS_TRUE \
    INCREMENT_MD_INDEX; \
    SET_TYPE(TYPE_TRUE); \
    /* Note, this storage is not critical */ \
    /* The main function here is to count the # of logical values */ \
    /* For later assessing array homogeneity */ \
    STORE_DATA_INDEX(++current_logical_index); \
    /*TODO: Add true check ... */ \
	ADVANCE_POINTER_BY_X(3);
            
#define PROCESS_FALSE \
    INCREMENT_MD_INDEX; \
    SET_TYPE(TYPE_FALSE); \
    STORE_DATA_INDEX(++current_logical_index); \
    /*TODO: Add false check ... */ \
	ADVANCE_POINTER_BY_X(4);
                
           

  
//========================       Navigation       =========================
#define CURRENT_CHAR   *p
#define CURRENT_POINTER p
#define CURRENT_INDEX   p - js
#define ADVANCE_POINTER_AND_GET_CHAR_VALUE *(++p)
#define DECREMENT_POINTER --p 
#define ADVANCE_POINTER_BY_X(x) p += x;
#define REF_OF_CURRENT_POINTER &p;
    
//Hex of 9,     10,     13,     32
//      htab    \n      \r     space
#define INIT_LOCAL_WS_CHARS \
    const __m128i whitespace_characters = _mm_set1_epi32(0x090A0D20);

//We are trying to get to the next non-whitespace character as fast as possible
//Ideally, there are 0 or 1 whitespace characters to the next value
//
//With human-readable JSON code there may be many spaces for indentation
//e.g.    
//          {
//                   "key1":1,
//                   "key2":2,
// -- whitespace --  "key3":3, etc.
//
#define ADVANCE_TO_NON_WHITESPACE_CHAR  \
    /* Ideally, we want to quit early with a space, and then no-whitespace */ \
    if (*(++p) == ' '){ \
        ++p; \
    } \
    /* All whitespace are less than or equal to the space character (32) */ \
    if (*p <= ' '){ \
        chars_to_search_for_ws = _mm_loadu_si128((__m128i*)p); \
        ws_search_result = _mm_cmpistri(whitespace_characters, chars_to_search_for_ws, SIMD_SEARCH_MODE); \
        p += ws_search_result; \
        if (ws_search_result == 16) { \
            while (ws_search_result == 16){ \
                chars_to_search_for_ws = _mm_loadu_si128((__m128i*)p); \
                ws_search_result = _mm_cmpistri(whitespace_characters, chars_to_search_for_ws, SIMD_SEARCH_MODE); \
                p += ws_search_result; \
            } \
        } \
    } \

            
#define DO_KEY_JUMP   goto *key_jump[CURRENT_CHAR]
#define DO_ARRAY_JUMP goto *array_jump[CURRENT_CHAR]
                
#define NAVIGATE_AFTER_OPENING_OBJECT \
	ADVANCE_TO_NON_WHITESPACE_CHAR; \
    switch (CURRENT_CHAR) { \
        case '"': \
            goto S_PARSE_KEY; \
        case '}': \
            goto S_CLOSE_OBJECT; \
        default: \
            goto S_ERROR_OPEN_OBJECT; \
    }            
                        
#define PROCESS_END_OF_ARRAY_VALUE \
	ADVANCE_TO_NON_WHITESPACE_CHAR; \
	switch (CURRENT_CHAR) { \
        case ',': \
            ADVANCE_TO_NON_WHITESPACE_CHAR; \
            DO_ARRAY_JUMP; \
        case ']': \
            goto S_CLOSE_ARRAY; \
        default: \
            goto S_ERROR_END_OF_VALUE_IN_ARRAY; \
	}
    
//This is for values following a key that are simple such as:
//number, string, null, false, true    
#define PROCESS_END_OF_KEY_VALUE_SIMPLE \
    ADVANCE_TO_NON_WHITESPACE_CHAR; \
	switch (CURRENT_CHAR) { \
        case ',': \
            ADVANCE_TO_NON_WHITESPACE_CHAR; \
            if (CURRENT_CHAR == '"') { \
                goto S_PARSE_KEY; \
            } \
            else { \
                goto S_ERROR_BAD_TOKEN_FOLLOWING_OBJECT_VALUE_COMMA; \
            } \
        case '}': \
            goto S_CLOSE_OBJECT; \
        default: \
            goto S_ERROR_END_OF_VALUE_IN_KEY; \
	}          

#define PROCESS_END_OF_KEY_VALUE_SIMPLE_AT_COMMA \
        ADVANCE_TO_NON_WHITESPACE_CHAR; \
        if (CURRENT_CHAR == '"') { \
            goto S_PARSE_KEY; \
        } else { \
            goto S_ERROR_BAD_TOKEN_FOLLOWING_OBJECT_VALUE_COMMA; \
        }
    
#define PROCESS_END_OF_KEY_VALUE_COMPLEX \
    ADVANCE_TO_NON_WHITESPACE_CHAR; \
	switch (CURRENT_CHAR) { \
        case ',': \
            RETRIEVE_CURRENT_PARENT_INDEX; \
            STORE_NEXT_SIBLING_KEY_COMPLEX; \
            MOVE_UP_PARENT_INDEX; \
            ADVANCE_TO_NON_WHITESPACE_CHAR; \
            if (CURRENT_CHAR == '"') { \
                goto S_PARSE_KEY; \
            } \
            else { \
                goto S_ERROR_BAD_TOKEN_FOLLOWING_OBJECT_VALUE_COMMA; \
            } \
        case '}': \
            goto S_CLOSE_KEY_COMPLEX_AND_OBJECT; \
        default: \
            goto S_ERROR_END_OF_VALUE_IN_KEY; \
	}
    
#define NAVIGATE_AFTER_OPENING_ARRAY \
    ADVANCE_TO_NON_WHITESPACE_CHAR; \
    if (CURRENT_CHAR == ']'){ \
       goto S_CLOSE_ARRAY; \
    }else{ \
       DO_ARRAY_JUMP; \
    }
    
#define NAVIGATE_AFTER_CLOSING_COMPLEX \
	if (IS_NULL_PARENT_INDEX) { \
		goto S_PARSE_END_OF_FILE; \
	} else if (PARENT_TYPE == TYPE_KEY) { \
        PROCESS_END_OF_KEY_VALUE_COMPLEX; \
    } else { \
        PROCESS_END_OF_ARRAY_VALUE; \
    }    
    
//======================    End of  Navigation       ======================
    
    
//=========================================================================
//=========================================================================    
const int SIMD_SEARCH_MODE = _SIDD_UBYTE_OPS | _SIDD_CMP_EQUAL_ANY | _SIDD_NEGATIVE_POLARITY | _SIDD_BIT_MASK;
__m128i chars_to_search_for_ws;
int ws_search_result;            
//-------------------------------------------------------------------------

//=========================================================================
//=========================================================================
void string_to_double_no_math(unsigned char *p, unsigned char **char_offset) {

    //In this approach we look for math like characters. We parse for
    //validity at a later point in time.
    
    //These are all the valid characters in a number
    //-+0123456789.eE
    
    //Just playing around with this to see how bad it is
    //
//     while (*p != ',' && *p != ']'){
//         p++;
//     }
    
    const __m128i digit_characters = _mm_set_epi8('0','1','2','3','4','5','6','7','8','9','.','-','+','e','E','0');
    
    __m128i chars_to_search_for_digits;
    
    int digit_search_result;
    
    chars_to_search_for_digits = _mm_loadu_si128((__m128i*)p);
    digit_search_result = _mm_cmpistri(digit_characters, chars_to_search_for_digits, SIMD_SEARCH_MODE);
    p += digit_search_result;
    if (digit_search_result == 16){
        chars_to_search_for_digits = _mm_loadu_si128((__m128i*)p);
        digit_search_result = _mm_cmpistri(digit_characters, chars_to_search_for_digits, SIMD_SEARCH_MODE);
        p += digit_search_result;
        //At this point we've traversed 32 characters
        //This code is easily rewriteable if in reality we need more
        //TODO: I should explicitly describe the max here
        //####.#####E###
        if (digit_search_result == 16){
        	mexErrMsgIdAndTxt("turtle_json:too_long_math", "too many digits when parsing a number");
        }
    }
    *char_offset = p;    
}

//const __m256i double_quotes_32x = _mm256_set1_epi8;

//-------------------------------------------------------------------------
void seek_string_end(unsigned char *p, unsigned char **char_offset){

    //advance past initial double-quote character
    ++p;
    
//     while (1){
//         __m256i x = _mm_loadu_si256((__mm256i *) p);
//         __m256i result = _mm256_cmpeq_epi8 (x,double_quotes_32x);
//         
//         //How to find the bit answer?????
//         //ffsll
//     }
    
STRING_SEEK:    
    //Old code - strchr apparently will check for null, but currently
    //we are padding to ensure we only need to look for '"'
    //p = strchr(p+1,'"');
    
    //TODO: We could try more complicated string instructions
    //1) SIMD
    //2) Keys vs string values - assume keys are shorter
    
    
    while (*p != '"'){
      ++p;    
    }
    
    //Back up to verify
    if (*(--p) == '\\'){
        //See documentation on the buffer we've added to the string
        if (*(--p) == 0){
            mexErrMsgIdAndTxt("turtle_json:unterminated_string", 
                    "JSON string is not terminated with a double-quote character");
        }
        //At this point, we either have a true end of the string, or we've
        //escaped the escape character
        //
        //for example:
        //1) "this is a test\"    => so we need to keep going
        //2) "testing\\"          => all done
        //
        //This of course could keep going ...
        
        //Adding on one last check to try and avoid the loop
        if (*p == '\\'){
            //Then we need to keep looking, we might have escaped this character
            //we'll go into a loop at this point
            //
            // This is true if the escape character is really an escape
            //character, rather than escaping the double quote
            bool double_quote_is_terminating = true;
            unsigned char *next_char = p + 3; 
            while (*(--p) == '\\'){
                double_quote_is_terminating = !double_quote_is_terminating;
            }
            if (double_quote_is_terminating){
               *char_offset = next_char-1; 
            }else{
                p = next_char;
                //mexPrintf("Char2: %c\n",*(p-2));
                goto STRING_SEEK;
            }
        }else{
            //   this_char   \     "     next_char
            //     p         1     2     3
            p+=3;
            //mexPrintf("Char1: %c\n",*(p-2));
            goto STRING_SEEK;
        }        
    }else{
        *char_offset = p+1;
    } 
}
//=========================================================================
//=========================================================================
//=========================================================================
//              Parse JSON   -    Parse JSON    -    Parse JSON
//=========================================================================
//=========================================================================
//=========================================================================
void parse_json(unsigned char *js, size_t string_byte_length, mxArray *plhs[],
        Options *options, struct sdata *slog) {
    
    //TODO: Check string_byte_length - can't be zero ...
    TIC(c_parse_init_time);
    
    //This apparently needs to be done locally for intrinsics ...
    INIT_LOCAL_WS_CHARS;

    const void *array_jump[256] = {
        [0 ... 33]  = &&S_ERROR_TOKEN_AFTER_COMMA_IN_ARRAY,
        [34]        = &&S_PARSE_STRING_IN_ARRAY,            // "
        [35 ... 44] = &&S_ERROR_TOKEN_AFTER_COMMA_IN_ARRAY,
        [45]        = &&S_PARSE_NUMBER_IN_ARRAY,            // -
        [46 ... 47] = &&S_ERROR_TOKEN_AFTER_COMMA_IN_ARRAY,
        [48 ... 57] = &&S_PARSE_NUMBER_IN_ARRAY,            // #
        [58 ... 90] = &&S_ERROR_TOKEN_AFTER_COMMA_IN_ARRAY,
        [91]        = &&S_OPEN_ARRAY_IN_ARRAY,              // [
        [92 ... 101]  = &&S_ERROR_TOKEN_AFTER_COMMA_IN_ARRAY,
        [102]         = &&S_PARSE_FALSE_IN_ARRAY,           // false
        [103 ... 109] = &&S_ERROR_TOKEN_AFTER_COMMA_IN_ARRAY,
        [110]         = &&S_PARSE_NULL_IN_ARRAY,            // null
        [111 ... 115] = &&S_ERROR_TOKEN_AFTER_COMMA_IN_ARRAY,
        [116]         = &&S_PARSE_TRUE_IN_ARRAY,            // true
        [117 ... 122] = &&S_ERROR_TOKEN_AFTER_COMMA_IN_ARRAY,
        [123]         = &&S_OPEN_OBJECT_IN_ARRAY,           // {
        [124 ... 255] = &&S_ERROR_TOKEN_AFTER_COMMA_IN_ARRAY};

    const void *key_jump[256] = {
        [0 ... 33]  = &&S_ERROR_TOKEN_AFTER_KEY,
        [34]        = &&S_PARSE_STRING_IN_KEY,      // "
        [35 ... 44] = &&S_ERROR_TOKEN_AFTER_KEY,
        [45]        = &&S_PARSE_NUMBER_IN_KEY,      // -
        [46 ... 47] = &&S_ERROR_TOKEN_AFTER_KEY,    
        [48 ... 57] = &&S_PARSE_NUMBER_IN_KEY,      // 0-9
        [58 ... 90] = &&S_ERROR_TOKEN_AFTER_KEY,
        [91]        = &&S_OPEN_ARRAY_IN_KEY,        // [
        [92 ... 101]  = &&S_ERROR_TOKEN_AFTER_KEY,
        [102]         = &&S_PARSE_FALSE_IN_KEY,   //false
        [103 ... 109] = &&S_ERROR_TOKEN_AFTER_KEY,
        [110]         = &&S_PARSE_NULL_IN_KEY,    // null
        [111 ... 115] = &&S_ERROR_TOKEN_AFTER_KEY,
        [116]         = &&S_PARSE_TRUE_IN_KEY,    // true
        [117 ... 122] = &&S_ERROR_TOKEN_AFTER_KEY,
        [123]         = &&S_OPEN_OBJECT_IN_KEY,   // {
        [124 ... 255] = &&S_ERROR_TOKEN_AFTER_KEY};        
    
    unsigned char *p = js;    
    unsigned char *temp_p;
    
    DEFINE_TIC(parsed_data_logging);
        
    //---------------------------------------------------------------------
    int parent_types[MAX_DEPTH_ARRAY_LENGTH];
    int parent_indices[MAX_DEPTH_ARRAY_LENGTH];
    int parent_sizes[MAX_DEPTH_ARRAY_LENGTH];
    
    int *n_arrays_at_depth = slog->arr__n_arrays_at_depth;
    int *n_objects_at_depth = slog->obj__n_objects_at_depth;
    int current_parent_data_index;
    int current_depth = 0;
    //---------------------------------------------------------------------
    int current_logical_index = -1; 
    //---------------------------------------------------------------------
    int n_data_allocations = 1;
    int data_size_allocated;
    //TODO: Implement chars per token
    if (options->n_tokens){
        data_size_allocated = options->n_tokens;
    }else{
        data_size_allocated = ceil((double)string_byte_length/4);
    }
    int data_size_index_max = data_size_allocated - 1;
    int current_data_index = -1;
    INITIALIZE_MAIN_DATA;
    //---------------------------------------------------------------------
    int n_object_allocations = 1;
    int object_size_allocated = ceil((double)string_byte_length/100);
    int object_size_index_max = object_size_allocated - 1;
    int current_object_index = -1;
    INITIALIZE_OBJECT_DATA;
    //---------------------------------------------------------------------
    int n_array_allocations = 1;
    int array_size_allocated = ceil((double)string_byte_length/100);
    int array_size_index_max = array_size_allocated - 1;
    int current_array_index = -1;
    INITIALIZE_ARRAY_DATA;
    //---------------------------------------------------------------------
    int n_key_chars = 0;
    int n_key_allocations  = 1; //Not yet implemented
    int key_size_allocated;
    if (options->n_keys){
        key_size_allocated = options->n_keys;
    }else{
        key_size_allocated = ceil((double)string_byte_length/20);
    }
    int key_size_index_max = key_size_allocated-1;
    int current_key_index = -1;
    INITIALIZE_KEY_DATA;
    //---------------------------------------------------------------------
    int n_string_chars = 0;
    int n_string_allocations = 1;
    int string_size_allocated;
    if (options->n_strings){
        string_size_allocated = options->n_strings;
    }else{
        string_size_allocated = ceil((double)string_byte_length/20);
    }
    int string_size_index_max = string_size_allocated-1;
    int current_string_index = -1;
    INITIALIZE_STRING_DATA;
    //---------------------------------------------------------------------
    int n_numeric_allocations = 1;
    int n_nulls = 0;
    int numeric_size_allocated;
    if (options->n_numbers){
        numeric_size_allocated = options->n_numbers;
    }else{
        numeric_size_allocated = ceil((double)string_byte_length/4);
    }
    int numeric_size_index_max = numeric_size_allocated - 1;
    int current_numeric_index = -1;
    INITIALIZE_NUMERIC_DATA
            
    TOC(c_parse_init_time,time__c_parse_init_time);        
    //---------------------------------------------------------------------
//=========================================================================    
//        ================= Start of the parsing =================
//=========================================================================
        
    TIC(start_parse2);        
    //DEFINE_TIC(parsed_data_logging);        
            
    //We decrement so that we can use the same advance to non-whitespace
    //code that we use everywhere else, where we assume that we've already
    //consumed the current character, even though we may not have
    DECREMENT_POINTER;
	ADVANCE_TO_NON_WHITESPACE_CHAR;

	switch (CURRENT_CHAR) {
        case '{':
        	PROCESS_OPENING_OBJECT;
            NAVIGATE_AFTER_OPENING_OBJECT;
        case '[':
            PROCESS_OPENING_ARRAY;
            NAVIGATE_AFTER_OPENING_ARRAY;
        default:
            mexErrMsgIdAndTxt("turtle_json:invalid_start", 
                    "Starting token needs to be an opening object or array");
	}

//    [ {            ======================================================
S_OPEN_OBJECT_IN_ARRAY:
    INCREMENT_PARENT_SIZE;
    PROCESS_OPENING_OBJECT;
    NAVIGATE_AFTER_OPENING_OBJECT;

//   "key": {        ====================================================== 
S_OPEN_OBJECT_IN_KEY:
    INITIALIZE_PARENT_INFO_KEY(TYPE_KEY);
    PROCESS_OPENING_OBJECT;
    NAVIGATE_AFTER_OPENING_OBJECT;
  
//=============================================================
S_CLOSE_KEY_COMPLEX_AND_OBJECT:
    //We need to close both the key, and the object
    RETRIEVE_CURRENT_PARENT_INDEX; 
    STORE_NEXT_SIBLING_KEY_COMPLEX;
    
    //Move up to the object
    MOVE_UP_PARENT_INDEX;

    //Fall Through --
    //               |      !
    //               |    \O/ 
    //               |     |
    //               |    / \
    //               |
    //               |
S_CLOSE_OBJECT:
    RETRIEVE_CURRENT_PARENT_INDEX;
    STORE_NEXT_SIBLING_OF_OBJECT;
    STORE_SIZE_OBJECT;
    MOVE_UP_PARENT_INDEX;
    NAVIGATE_AFTER_CLOSING_COMPLEX;
    
//=============================================================
S_OPEN_ARRAY_IN_ARRAY:  
    INCREMENT_PARENT_SIZE;
    PROCESS_OPENING_ARRAY;   
    NAVIGATE_AFTER_OPENING_ARRAY;
    
//=============================================================
S_OPEN_ARRAY_IN_KEY:         
    INITIALIZE_PARENT_INFO_KEY(TYPE_KEY);
    PROCESS_OPENING_ARRAY;
	NAVIGATE_AFTER_OPENING_ARRAY;
            
//=============================================================
S_CLOSE_ARRAY:
    RETRIEVE_CURRENT_PARENT_INDEX;
    STORE_NEXT_SIBLING_OF_ARRAY;
    STORE_SIZE_ARRAY;

    //Ideally we could avoid the check on the parent_sizes
    //We run into a problem if we ever have an empty array
    //d1[current_parent_data_index+1] could access out of bounds memory
    //
    //TODO: We need to have a merged type (e.g. number or null) (true or false)
    //TODO: log logical types
    
//     if (parent_sizes[current_depth] && \
//             (parent_sizes[current_depth]  == (d1[current_data_index] - d1[current_parent_data_index+1] + 1))){
//         
//         //TODO: We may to log homogenous arrays separately, so that we only
//         //try and post-parse non-homogenous
//         //array_depths[RETRIEVE_DATA_INDEX(current_parent_data_index)] = array_type_map[types[current_data_index]];
//         
//         n_arrays_at_depth[current_parent_data_index] -= 1;
//     }

    MOVE_UP_PARENT_INDEX;
    NAVIGATE_AFTER_CLOSING_COMPLEX;

//=============================================================
S_PARSE_KEY:  
	INCREMENT_PARENT_SIZE;
    PROCESS_KEY_NAME;
    
    //Most JSON I've seen holds the ':' character
    //close the the key
    //
    //  e.g. "my_key": value
    //
    //  rather than:
    //       "my_key" : value
    //  or   "my_key"
    //              : value
    if (ADVANCE_POINTER_AND_GET_CHAR_VALUE == ':'){
        ADVANCE_TO_NON_WHITESPACE_CHAR;
        DO_KEY_JUMP;    
    }else{
        DECREMENT_POINTER;
        ADVANCE_TO_NON_WHITESPACE_CHAR;

        if (CURRENT_CHAR == ':') {
            ADVANCE_TO_NON_WHITESPACE_CHAR;
            DO_KEY_JUMP;
        }
        else {
            goto S_ERROR_MISSING_COLON_AFTER_KEY;
        }
    }

//=============================================================
S_PARSE_STRING_IN_ARRAY:
	INCREMENT_PARENT_SIZE;
    PROCESS_STRING
	PROCESS_END_OF_ARRAY_VALUE;

//=============================================================
S_PARSE_STRING_IN_KEY:
    STORE_NEXT_SIBLING_KEY_SIMPLE;
    PROCESS_STRING;
	PROCESS_END_OF_KEY_VALUE_SIMPLE


//=============================================================
S_PARSE_NUMBER_IN_KEY:
    STORE_NEXT_SIBLING_KEY_SIMPLE;
    PROCESS_NUMBER;
    
    //The number parser stops 1 past the last number
    //1.2345,
    //      ^
    if (CURRENT_CHAR == ',') {
       PROCESS_END_OF_KEY_VALUE_SIMPLE_AT_COMMA;
    }else{
        //Most processing starts from having consumed the current character
        //which we have not, so we backtrack to allow consumption
        //
        //This comes in where we do: 
        //  if (*(++p) == ' ')
        //      instead of:
        //  if (*(p) == ' ')
        //      for ADVANCE_TO_NON_WHITESPACE_CHAR
        //
        //TODO: We could rewrite the nav code so that everything else
        //manually advances, then use if(*(p)
        //e.g. for strings, null, true, false, just advance
        //DECREMENT_POINTER is wasted processing, since we just increment
        //it again
        DECREMENT_POINTER;
        PROCESS_END_OF_KEY_VALUE_SIMPLE;
    }
	

//=============================================================
S_PARSE_NUMBER_IN_ARRAY:    
	INCREMENT_PARENT_SIZE;
    PROCESS_NUMBER;
   
    //This normally happens, trying to optimize progression of #s in array
    if (CURRENT_CHAR == ','){
        ADVANCE_TO_NON_WHITESPACE_CHAR;
        DO_ARRAY_JUMP;
    }else{
        //See comment in S_PARSE_NUMBER_IN_KEY
        DECREMENT_POINTER;
        PROCESS_END_OF_ARRAY_VALUE;
    }

//=============================================================
S_PARSE_NULL_IN_KEY:
    STORE_NEXT_SIBLING_KEY_SIMPLE;
    PROCESS_NULL;
	PROCESS_END_OF_KEY_VALUE_SIMPLE;

//=============================================================
S_PARSE_NULL_IN_ARRAY:
	INCREMENT_PARENT_SIZE;
    PROCESS_NULL;
	PROCESS_END_OF_ARRAY_VALUE;

//=============================================================
S_PARSE_TRUE_IN_KEY:
    STORE_NEXT_SIBLING_KEY_SIMPLE;
    PROCESS_TRUE;
	PROCESS_END_OF_KEY_VALUE_SIMPLE;

S_PARSE_TRUE_IN_ARRAY:
	INCREMENT_PARENT_SIZE;
    PROCESS_TRUE;
    PROCESS_END_OF_ARRAY_VALUE;

S_PARSE_FALSE_IN_KEY:
    STORE_NEXT_SIBLING_KEY_SIMPLE;
    PROCESS_FALSE;
    PROCESS_END_OF_KEY_VALUE_SIMPLE;

S_PARSE_FALSE_IN_ARRAY:
	INCREMENT_PARENT_SIZE;
    PROCESS_FALSE;
	PROCESS_END_OF_ARRAY_VALUE;

	//=============================================================
S_PARSE_END_OF_FILE:
	ADVANCE_TO_NON_WHITESPACE_CHAR
    if (!(CURRENT_CHAR == '\0')) {
        goto S_ERROR_BAD_ENDING;
    }
	goto S_FINISH_GOOD;


//===============       ERRORS   ==========================================
//=========================================================================
//TODO: This is going to be redone. I'd like to have more central
//handling of errors along with the ability to inspect location/context
//as can be seen in my hacky comments below
 
S_ERROR_BAD_ENDING:
	//mexPrintf("Current char: %d",CURRENT_CHAR);
 	mexErrMsgIdAndTxt("turtle_json:invalid_end", 
                "non-whitespace characters found after end of root token close");   
  
S_ERROR_BAD_TOKEN_FOLLOWING_OBJECT_VALUE_COMMA:
    // {"key": value, #ERROR
    //  e.g.
    // {"key": value, 1
    //
	// mexPrintf("Position %d\n",CURRENT_INDEX); 
	mexErrMsgIdAndTxt("turtle_json:no_key", "Key or closing of object expected");

S_ERROR_DEPTH_EXCEEDED:
    mexErrMsgIdAndTxt("turtle_json:depth_exceeded", "Max depth was exceeded");

S_ERROR_DEPTH:
    mexErrMsgIdAndTxt("turtle_json:depth_limit","Max depth exceeded");    
    
S_ERROR_OPEN_OBJECT:
	mexErrMsgIdAndTxt("turtle_json:invalid_token", "S_ERROR_OPEN_OBJECT");

S_ERROR_MISSING_COLON_AFTER_KEY:
	mexErrMsgIdAndTxt("turtle_json:invalid_token", "S_ERROR_MISSING_COLON_AFTER_KEY");

//TODO: Describe when this error is called    
S_ERROR_END_OF_VALUE_IN_KEY:
	mexErrMsgIdAndTxt("turtle_json:invalid_token", "Token of key must be followed by a comma or a closing object ""}"" character");

//This error comes when we have a comma in an array that is not followed
// by a valid value => i.e. #, ", [, {, etc.
S_ERROR_TOKEN_AFTER_COMMA_IN_ARRAY:
    //mexPrintf("Current character: %c\n",CURRENT_CHAR);
    //mexPrintf("Current position in string: %d\n",CURRENT_INDEX);
	mexErrMsgIdAndTxt("turtle_json:invalid_token", "Invalid token found after opening of array or after a comma in an array");
	//mexErrMsgIdAndTxt("turtle_json:no_primitive","Primitive value was not found after the comma");
   
//TODO: Open array points here now too
S_ERROR_TOKEN_AFTER_KEY:
	mexErrMsgIdAndTxt("turtle_json:invalid_token", "S_ERROR_TOKEN_AFTER_KEY");
	//mexErrMsgIdAndTxt("turtle_json:no_primitive","Primitive value was not found after the comma");    
    

S_ERROR_END_OF_VALUE_IN_ARRAY:  
    //TODO: Print the character
	//mexPrintf("Current position: %d\n", CURRENT_INDEX);
	mexErrMsgIdAndTxt("turtle_json:invalid_token", "Token in array must be followed by a comma or a closing array ""]"" character ");    


    
S_ERROR_DEBUG:
    mexErrMsgIdAndTxt("turtle_json:debug_error","Debug error");
   
S_FINISH_GOOD:
    
    TOC(start_parse2, time__c_parse_time);
    
    
    
    //The normal TIC() approach was not working, so we iniitialize earlier
    //and start the TIC here.
    //TIC(parsed_data_logging);
    START_TIC(parsed_data_logging);
    
    //Meta data storage
    //--------------------
    //This information can be used to tell how efficient we were
    //relative to the allocation  
    slog->alloc__n_tokens_allocated = data_size_allocated;
    slog->alloc__n_objects_allocated = object_size_allocated;
    slog->alloc__n_arrays_allocated = array_size_allocated;
    slog->alloc__n_keys_allocated = key_size_allocated;
    slog->alloc__n_strings_allocated = string_size_allocated;
    slog->alloc__n_numbers_allocated = numeric_size_allocated;
    slog->alloc__n_data_allocations = n_data_allocations;
    slog->alloc__n_object_allocations = n_object_allocations;
    slog->alloc__n_array_allocations = n_array_allocations;
    slog->alloc__n_key_allocations = n_key_allocations;
    slog->alloc__n_string_allocations = n_string_allocations;
    slog->alloc__n_numeric_allocations = n_numeric_allocations;    
    


    
    //------------------------    Main Data   -----------------------------
    
    slog->n_nulls = n_nulls;
    
    TRUNCATE_MAIN_DATA
    slog->n_tokens = current_data_index+1;
    setStructField2(plhs[0],types,mxUINT8_CLASS,current_data_index + 1,E_types);
    setStructField2(plhs[0],d1,mxINT32_CLASS,current_data_index + 1,E_d1);
        
    TRUNCATE_OBJECT_DATA
    slog->n_objects = current_object_index + 1;
    setStructField2(plhs[0],child_count_object,
            mxINT32_CLASS,current_object_index + 1,E_obj__child_count_object); 
    setStructField2(plhs[0],next_sibling_index_object,
            mxINT32_CLASS,current_object_index + 1,E_obj__next_sibling_index_object);
    setStructField2(plhs[0],object_depths,
            mxUINT8_CLASS,current_object_index + 1,E_obj__object_depths);
  
    TRUNCATE_ARRAY_DATA
    slog->n_arrays = current_array_index + 1;
    setStructField2(plhs[0],child_count_array,mxINT32_CLASS,current_array_index + 1,E_arr__child_count_array); 
    setStructField2(plhs[0],next_sibling_index_array,mxINT32_CLASS,current_array_index + 1,E_arr__next_sibling_index_array);
    setStructField2(plhs[0],array_depths,mxUINT8_CLASS,current_array_index + 1,E_arr__array_depths);

    TRUNCATE_KEY_DATA
    slog->n_keys = current_key_index + 1;
    setStructField2(plhs[0],key_p,mxUINT64_CLASS,current_key_index + 1,E_key__key_p);
    setStructField2(plhs[0],key_sizes,mxINT32_CLASS,current_key_index + 1,E_key__key_sizes);
    setStructField2(plhs[0],next_sibling_index_key,mxINT32_CLASS,current_key_index + 1,E_key__next_sibling_index_key);
        
    TRUNCATE_STRING_DATA
    slog->n_strings = current_string_index + 1;
    setStructField2(plhs[0],string_p,mxUINT64_CLASS,current_string_index + 1,E_string_p);
    setStructField2(plhs[0],string_sizes,mxINT32_CLASS,current_string_index + 1,E_string_sizes);
    
    TRUNCATE_NUMERIC_DATA
    slog->n_numbers = current_numeric_index + 1;
    //Note, it seems the class type may only be needed for viewing in Matlab
    //Internally it is just bytes (assuming sizeof is the same)
    setStructField2(plhs[0],numeric_p,mxDOUBLE_CLASS,current_numeric_index + 1,E_numeric_p);

    TOC(parsed_data_logging,time__parsed_data_logging_time);

	return;
    
}

// //https://mischasan.wordpress.com/2011/06/22/what-the-is-sse2-good-for-char-search-in-long-strings/
// char const *ssechr(char const *s, char ch)
// {
//     __m128i zero = _mm_setzero_si128();
//     __m128i cx16 = _mm_set1_epi8(ch); // (ch) replicated 16 times.
//     while (1) {
//         __m128i  x = _mm_loadu_si128((__m128i const *)s);
//         unsigned u = _mm_movemask_epi8(_mm_cmpeq_epi8(zero, x));
//         unsigned v = _mm_movemask_epi8(_mm_cmpeq_epi8(cx16, x))
//                         & ~u & (u - 1);
//         if (v) return s + ffs(v) - 1;
//         if (u) return  NULL;
//         s += 16;
//     }
// }
