#include "turtle_json.h"
#include "simd_guard.h"

//
//  This file contains the entry function as well as handling of the inputs.

#define N_PADDING 17

//                                   1 2  3  4 5 6 7 8 9 0 1 2 3 4 5 6 7
//                                     \  "
uint8_t BUFFER_STRING2[N_PADDING] = {0,92,34,0,0,0,0,0,0,0,0,0,0,0,0,0,0};

static struct cpu_x86 s;
int initialized = 0;
mxArray *perm_out; 

const char *fieldnames_out[] = {
    "json_string",
     "types",
     "d1",
     "obj__child_count_object",
     "obj__next_sibling_index_object",
     "obj__object_depths",
     "obj__unique_object_first_md_indices",
     "obj__object_ids",
     "obj__objects",
     "arr__child_count_array",
     "arr__next_sibling_index_array",
     "arr__array_depths",
     "arr__array_types",
     "key__key_p",
     "key__key_sizes",
     "key__next_sibling_index_key",
     "string_p",
     "string_sizes",
     "numeric_p",
     "strings",
     "slog"};

//=========================================================================



void initialize_structs(){
    //We initialize a persistent array so that on subsequent calls
    //we duplicate the array, rather than trying to parse the fieldnames
    //
    //TODO: Link to jim's mex testing speed code ...
    
    mxArray *mx_temp;
    
    perm_out = mxCreateStructMatrix(1,1,ARRAY_SIZE(fieldnames_out),fieldnames_out);   
    mexMakeArrayPersistent(perm_out);
    
    //Currently we've defined the structure and the fieldnames, but
    //the fields themselves are empty and need to be created and populated
    //with data.
    //
    //TODO: It may be advantageous to populate each field with a properly
    //defined mxArray with no data pointer (i.e. header only - because the 
    //data are changed in the code, so no point in allocating that now)
    
}

static void clear_persistent_data(void)
{
    //When the mex clears we call this function which clears our 
    //peristent data.
    
    //mexPrintf("Clearing peristent memory.\n");
    mxDestroyArray(perm_out);
}

//=========================================================================
bool padding_is_necessary(unsigned char *input_bytes, size_t input_string_length){
    //
    //  Return whether or not the parse buffer is present/necessary. If
    //  already present, it is not necessary.
    //
    //  This is for a string array or byte array input, where we don't 
    //  know if it has been appropriately padded to prevent parsing
    //  past the end of the string.
    
    if (input_string_length >= N_PADDING){ 
        return memcmp(&input_bytes[input_string_length-N_PADDING],BUFFER_STRING2,N_PADDING);
    }else{
        return true;
    }
}

void add_parse_buffer(unsigned char *buffer, size_t array_length){
    //
    //  Buffer is currently 17 characters of the form:
    //  0\"000000...  <= 0 means null character, not zero
    //
    //  The " character
    //  stops a potentially non-terminated string. The \ character
    //  is a natural check anyways in our algorithm where we first find
    //  a " character, and then backtrack. If we happen to find this 
    //  last " character, and we backtrack and find the \ character, then
    //  we need a special check, for the initial null character, to
    //  differentiate this stop from a normally escaped " character.
    //
    //  i.e. differentiate:
    //      ...test string\" is a good idea",           <= escaped "
    //      vs
    //      ...test string is not terminated0\"0000000  <= bad json string
    //
    //
    //      TODO: An even better test would be to verify location after
    //      confirming the 0 character
    //
    //  The length of the buffer is to prevent search problems with SIMD
    //  that process multiple characters at a time (i.e. we don't want to
    //  parse past the end of the string)
    
    memcpy(&buffer[array_length],BUFFER_STRING2,N_PADDING);
}

void process_input_string(const mxArray *prhs[], unsigned char **json_string, size_t *json_string_length, int *buffer_added){
    //
    //  The input string is raw JSON, which may or may not
    //  have the parsing buffer added.
    //
    //
    
    
    size_t input_string_length;
    size_t output_string_length;
    unsigned char *input_string;
    unsigned char *output_string;
    
    bool has_buffer;
    
    //TODO: Rewrite:
    //1) Support buffer check of string, not on bytes
    //2) Support string to bytes using better approach than whatever
    //   Matlab is currently doing - need to verify no high bytes set.
    
    
    input_string_length = mxGetNumberOfElements(prhs[0]);
    
    //Step 1 - check for buffer ...
    //--------------------------------
    has_buffer = false;
    
    //JAH: At this point ...
    /*
    output_string_length = input_string_length + N_PADDING;
    output_string = mxMalloc(output_string_length);

     */
    
    //For now we'll assume no high bytes ... (but check for it)
    
    //  TODO: It is not clear that these methods will respect UTF-8 encoding
    //      => mxArrayToString_UTF8 - when was this deprecated?
    //      => mxArrayToUTF8String  - 2015a
    //      - see next TODO, we are likely better off rolling our own ...
    //      - although for now, correct would be better than fast
    //
    //
    //  TODO: If the buffer is not present here, we are doing a memory reallocation
    //  anyway, so we might as well both transform the string and add the buffer
    //  at the same time, rather than do two memory reallocations
    input_string = (unsigned char *) mxArrayToString(prhs[0]);
    
    
    if (padding_is_necessary(input_string,input_string_length)){
        *buffer_added = 1;
        output_string_length = input_string_length + N_PADDING;
        output_string = mxMalloc(output_string_length);
        memcpy(output_string,input_string,input_string_length);
        mxFree(input_string);
        add_parse_buffer(output_string, input_string_length);
    }else{
        *buffer_added = 0;
        output_string = input_string;
        output_string_length = input_string_length;
    }
    
    *json_string = output_string;
    *json_string_length = output_string_length - N_PADDING;
    
}

void process_input_bytes(const mxArray *prhs[], unsigned char **json_string, size_t *json_string_length, int *buffer_added, int *is_input){
    //
    //  The first input (prhs[0] is a byte (uint8 or int8) array, which
    //  may or may not have the parsing buffer added.
    //
    
    size_t input_string_length;
    size_t output_string_length;
    unsigned char *input_string;
    unsigned char *output_string;
    
    input_string = (unsigned char *)mxGetData(prhs[0]);
    input_string_length = mxGetNumberOfElements(prhs[0]);
    
    if (padding_is_necessary(input_string,input_string_length)){
        *buffer_added = 1;
        output_string_length = input_string_length + N_PADDING;
        output_string = mxMalloc(output_string_length);
        memcpy(output_string,input_string,input_string_length);
        add_parse_buffer(output_string, input_string_length);
    }else{
        *buffer_added = 0;
        *is_input = 1;
        output_string = input_string;
        output_string_length = input_string_length ;
    }
    
    *json_string = output_string;
    *json_string_length = output_string_length - N_PADDING;

}
//=========================================================================
//=========================================================================

void throw_missing_file_error(const char *file_path, size_t file_path_string_length){
    //
    //  helper function for read_file_to_string()
    char file_path_short[100];
    
    char buffer[256];
    
    if (file_path_string_length > 99){
        memcpy(file_path_short,file_path,96);
        file_path_short[96] = '.';
        file_path_short[97] = '.';
        file_path_short[98] = '.';
        file_path_short[99] = '\0';
    }else{
        memcpy(file_path_short,file_path,file_path_string_length);
    }
    
    sprintf(buffer,
            "Unable to read file: \"%s\"\nIf input is really a string use "
            "json.tokens.parse or json.parse instead",file_path_short);
    mexErrMsgIdAndTxt("turtle_json:file_open",buffer);    
}

void read_file_to_string(const mxArray *prhs[], unsigned char **p_buffer, size_t *string_byte_length){
    //
    //  This function reads the file to string and also adds the parsing buffer at the end.
    //
    
	FILE *file;
    char *file_path;
	size_t file_length;
    size_t file_path_string_length;
        
    unsigned char *buffer;

    file_path = mxArrayToString(prhs[0]);
    
    //http://stackoverflow.com/questions/2575116/fopen-fopen-s-and-writing-to-files
#ifdef WIN32
    errno_t err;
	if( (err  = fopen_s( &file, file_path, "rb" )) !=0 ) {
#else
	if ((file = fopen(file_path, "rb")) == NULL) {
#endif
        //error in reading occurred ...
        file_path_string_length = mxGetNumberOfElements(prhs[0]);
        throw_missing_file_error(file_path,file_path_string_length);
    }
	
	//Get file length
	fseek(file, 0, SEEK_END);
	file_length = ftell(file);
	fseek(file, 0, SEEK_SET);

	//Allocate memory
	buffer = mxMalloc(file_length+N_PADDING);

	//Read file contents into buffer
    //---------------------------------------------------
	fread(buffer, file_length, 1, file);
    fclose(file);
    
    add_parse_buffer(buffer, file_length);
    
    *string_byte_length = file_length; 
    
    *p_buffer = buffer;
    
    mxFree(file_path);
}
        
void get_json_string(mxArray *plhs[], int nrhs, const mxArray *prhs[], 
        unsigned char **json_string, size_t *string_byte_length, 
        Options *options, struct sdata *slog){
    //
    //  The input JSON can be:
    //  1) raw character string - Matlab char (UTF-16)
    //  2) raw byte string (uint8 or int8 array)
    //  3) Path to a file
    
    mxArray *mxArrayTemp;
    unsigned char *raw_string;
    unsigned char *json_string2;
    int buffer_added = 1;
    
    //TODO: I think this should be renamed ...
    int is_input = 0; //Indicates that input bytes already had buffer
    
    if (options->has_raw_string){
        //Technically I think options checking covers this ...
     	if (!mxIsClass(prhs[0],"char")){
            mexErrMsgIdAndTxt("turtle_json:invalid_input", "'raw_string' input needs to be a string");
        }
        process_input_string(prhs,json_string,string_byte_length,&buffer_added);
    }else if (options->has_raw_bytes){
        //Note here 'is_input' depends on whether or not the buffer was added
        process_input_bytes(prhs,json_string,string_byte_length,&buffer_added,&is_input);
    }else{
        if (!mxIsClass(prhs[0],"char")){
            mexErrMsgIdAndTxt("turtle_json:invalid_input","'file_path' input needs to be a string"); 
        }
        read_file_to_string(prhs,json_string,string_byte_length);
    }
    
    slog->buffer_added = buffer_added;
    //setIntScalar(plhs[0],"buffer_added",buffer_added);
    
	//Let's hold onto the string for the user. Technically it isn't needed
    //once we exit this function, since all information is contained in
    //the other variables.
    
    //http://stackoverflow.com/questions/19813718/mex-files-how-to-return-an-already-allocated-matlab-array
    if (is_input){
        mxArrayTemp = mxCreateSharedDataCopy(prhs[0]);
        //mxSetN(mxArrayTemp,*string_byte_length);
        //mxAddField(plhs[0],"json_string");
        //mxSetField(plhs[0],0,"json_string",mxArrayTemp);
    }else{
        mxArrayTemp = mxCreateNumericMatrix(1, 0, mxUINT8_CLASS, 0);
        mxSetData(mxArrayTemp, *json_string);
        mxSetN(mxArrayTemp,*string_byte_length);
        //setStructField(plhs[0],*json_string,"json_string",mxUINT8_CLASS,*string_byte_length);
    }
    mxSetFieldByNumber(plhs[0], 0, E_json_string, mxArrayTemp);
    
}

void init_options(int nrhs, const mxArray* prhs[], Options *options){
    //x Populate options structure based on optional inputs
    //
    //  The parsing function is called with the following format:
    //      turtle_json_mex(file_path__or__string,varargin)
    //
    //  varargin represents property/value pairs
    //
    //  For example we might have:
    //      turtle_json_mex(file_path,'n_tokens',10)
    //
    //  This function populates the options structure based on these
    //  optional inputs.
    //
    //  Inputs
    //  ------
    //  raw_string
    //  n_tokens
    //  n_keys
    //  n_strings
    //  n_numbers
    //
    //  See Also
    //  --------
    //  json.tokens 
    
    mxArray *mxArrayTemp;
    
    if (mxIsClass(prhs[0],"uint8") || mxIsClass(prhs[0],"int8")){
        options->has_raw_bytes = true;
    }
    
    if (nrhs < 2){
        return;
    }
    
    //All optional inputs must come in pairs (property,value)
    if (nrhs % 2 == 0){
        //We have an error if even, since the # of inputs is 
        //equal to the # of optional inputs + 1 (json string or bytes), 
        //thus if nrhs is even then the # of optional inputs is odd
        mexErrMsgIdAndTxt("turtle_json:invalid_input",
                "Number of optional inputs must be even");
    }
    
    int64_t* prop_string;
    mxArray *mx_prop;
    mxArray *mx_value;
    for (int i = 1; i < nrhs; i+=2){
        mx_prop = prhs[i];
        mx_value = prhs[i+1];
        
        if (!mxIsClass(mx_prop,"char")){
            mexErrMsgIdAndTxt("turtle_json:invalid_input",
                    "Odd optional input was not a string as expected");
        }else if(mxGetN(mx_prop) < 4){
        	mexErrMsgIdAndTxt("turtle_json:invalid_input",
                "String length too short");
        }
            
            
        
        prop_string = (int64_t *)mxGetData(mx_prop);
        
        //TODO: Could replace with call 
        //prop_string = mxArrayToString(mx_prop);
        
        //  typecast(uint16('raw_'),'int64')
        if (*prop_string == 26740633894977650){
            //mexPrintf("raw_string\n");
            if (mxIsClass(mx_value,"logical")){
                //If logical and false, exit early
                if (!(*(uint8_t *)mxGetData(mx_value))){
                    continue;
                }
            }else if (mxIsClass(mx_value,"double")){
                //If double and 0, exit early
                if (!(mxGetScalar(mx_value))){
                    continue;
                }                
            }else{
                mexErrMsgIdAndTxt("turtle_json:invalid_input",
                        "Optional input 'raw_string' must be double or logical");
            }
            
        	if (mxIsClass(prhs[0],"char")){
                options->has_raw_string = true;
            }else if (mxIsClass(prhs[0],"uint8") || mxIsClass(prhs[0],"int8")){
                //Duplicate ... - this isn't really needed anymore since
                //bytes as an input signals a raw_string
                //Note, we'll allow bytes for a "raw_string"
                options->has_raw_bytes = true;
            }else{
                mexErrMsgIdAndTxt("turtle_json:invalid_input",
                        "raw_string is true but the first data input was not of type 'char', 'int8', or 'uint8'");
            }
        }
        
// // //         else if (strcmp(prop_string,"n_tokens") == 0){
// // //             if (mxIsClass(mx_value,"double")){
// // //                 options->n_tokens = (int)mxGetScalar(mx_value);
// // //             }else{
// // //                 mexErrMsgIdAndTxt("turtle_json:invalid_input",
// // //                         "n_tokens option needs to be a double");
// // //             }    
// // //         }else if (strcmp(prop_string,"n_keys") == 0){
// // //             if (mxIsClass(mx_value,"double")){
// // //                 options->n_keys = (int)mxGetScalar(mx_value);
// // //             }else{
// // //                 mexErrMsgIdAndTxt("turtle_json:invalid_input",
// // //                         "n_keys option needs to be a double");
// // //             } 
// // //     	}else if (strcmp(prop_string,"n_strings") == 0){
// // //             if (mxIsClass(mx_value,"double")){
// // //                 options->n_strings = (int)mxGetScalar(mx_value);
// // //             }else{
// // //                 mexErrMsgIdAndTxt("turtle_json:invalid_input",
// // //                         "n_strings option needs to be a double");
// // //             }
// // //         }else if (strcmp(prop_string,"n_numbers") == 0){
// // //          	if (mxIsClass(mx_value,"double")){
// // //                 options->n_numbers = (int)mxGetScalar(mx_value);
// // //             }else{
// // //                 mexErrMsgIdAndTxt("turtle_json:invalid_input",
// // //                         "n_numbers option needs to be a double");
// // //             }
// // //         }else{
// // //             mexErrMsgIdAndTxt("turtle_json:invalid_input",
// // //                     "Unrecognized optional input: %s",prop_string);
// // //         }
    }  
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray*prhs[])
{
    //  This function is meant to be called by the json.tokens constructor
    //
    //  It is also called via json.load or json.parse
    //
    //  Usage:
    //  ------
    //  token_info = turtle_json_mex(file_path,varargin)
    //
    //  token_info = turtle_json_mex(raw_string,varargin)
    //
    //  token_info = turtle_json_mex(raw_bytes,varargin)
    //
    //  Inputs
    //  ------
    //  file_path
    //  raw_string
    //
    //  Optional Inputs
    //  ---------------
    //  Documented in the Matlab code @ json.tokens.load
    //
    //  Outputs:
    //  --------
    //  token_info
    //      - see wrapping Matlab function
    
    TIC(start_mex);
    
    //# of inputs and outputs check ---------------------------------------
    if (nrhs < 1){
        mexErrMsgIdAndTxt("turtle_json:n_inputs",
                "Invalid # of inputs, at least 1 input expected");
    }else if (!(nlhs == 1)){
      	mexErrMsgIdAndTxt("turtle_json:n_outputs",
                "Invalid # of outputs, 1 expected");
    }
    
    //Initialization
    //---------------------------------------------------------------------
    if (!initialized){
        cpu_x86__detect_host(&s);
        //TODO: This also needs to respect any compiling options
        //HW_AVX && OS_AVX 
        //s.HW_AVX && s.OS_AVX
        if (!s.HW_SSE42){
            mexErrMsgIdAndTxt("turtle_json:simd_error",
                "Processor doesn't support SIMD code used");
        }
        //This is meant to speed up subsequent calls
        initialized = 1;
        initialize_structs();        
        mexAtExit(clear_persistent_data);
    }
    
    //We hold onto this in memory as slog in the output structure
    //Note zeroing is important as we don't always set all fields
    //  and a default of 0 in those cases is appropriate.
    struct sdata *slog = (struct sdata*)mxCalloc(1,sizeof(struct sdata));
    
    //For windows we get higher timing resolution with QPC. This however
    //requires a conversion factor which we grab here.
    #ifdef _WIN32
        LARGE_INTEGER Frequency;
        QueryPerformanceFrequency(&Frequency); 
        slog->qpc_freq = (double)Frequency.QuadPart;
    #endif
    
    //We duplicate to try and minimize the time it takes to initialize
    //the output structure. Fields are already defined but currently
    //data types and sizes are not.
    plhs[0] = mxDuplicateArray(perm_out);
    
    //TODO: Detect the supported features of the processor
    //http://stackoverflow.com/questions/6121792/how-to-check-if-a-cpu-supports-the-sse3-instruction-set
    //https://github.com/JimHokanson/turtle_json/issues/13
    //TODO: We do this in plotBig
    
    size_t string_byte_length;
    unsigned char *json_string = NULL;

    Options options = {};
    
    //Processing of inputs
    //-------------------------------------
    //mexPrintf("init options\n");
    init_options(nrhs, prhs, &options);
    
    //mexPrintf("input parsing\n");
    
    TIC(start_read);
    get_json_string(plhs, nrhs, prhs, &json_string, &string_byte_length, 
            &options, slog);
    TOC(start_read,time__elapsed_read_time);
    
    
    
    //Token parsing
    //-------------
    //mexPrintf("token parsing\n");
    TIC(start_parse);
    parse_json(json_string, string_byte_length, plhs, &options, slog);
    TOC(start_parse, time__total_elapsed_parse_time);
   
    
    
    //Post token parsing
    //------------------
    //mexPrintf("post token parsing\n");
    post_process(json_string, plhs, slog);
    
    TOC(start_mex,time__total_elapsed_time_mex);
    
    //Move c_struct log to field of output
    //---------------------------------------
    //mexPrintf("setting up output\n");
    
    mxArray *mx_slog = mxCreateNumericMatrix(0, 1, mxUINT8_CLASS, 0);
    mxSetData(mx_slog,slog);
    mxSetM(mx_slog,sizeof(struct sdata));
    mxSetFieldByNumber(plhs[0],0,E_slog,mx_slog);
    
    TOC(start_mex,time__total_elapsed_time_mex);
}