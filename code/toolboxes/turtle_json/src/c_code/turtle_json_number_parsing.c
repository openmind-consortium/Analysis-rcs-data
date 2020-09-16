#include "turtle_json.h"

//Place to put various # parsing algorithms ...
//https://github.com/miloyip/rapidjson/blob/03a73910498d784a3a9429202a90d2fb67be910b/include/rapidjson/reader.h#L1118

//===================   Number parsing errors   ===========================

// We observed only a '-'
#define NO_NUMBER_ERROR 0

//# We observed a period with no fraction ...
#define NO_FRACTION_ERROR 1

#define NO_EXPONENT_ERROR 2

        
void string_to_double_v2(double *value_p, char *p, int i, int *error_p, int *error_value) {
    
    double value = 0;
    double fraction = 0;
    double exponent_value;
    bool negate;
    
    if (*p == '-'){
        ++p;
        negate = true;
    }else{
        negate = false;
    }
    
    //Verify at least one number - technically we could put this in the '-'
    //case above, as otherwise this was triggered based on observing a #
    if (isdigit(*p)){
        value = 10*value + (double)(*p-'0');
        ++p;
    }else{
    	*error_p = i+1;
        *error_value = NO_NUMBER_ERROR;
        return;
    }
    
    while (isdigit(*p)){
        value = 10*value + (double)(*p-'0');
        ++p;
    }
    
    //Fraction
    //--------------------------------------------------------
    if (*p == '.') {
        ++p;
        if (isdigit(*p)){
            value = value + 0.1*((*p) - '0');
            fraction = 0.01;
            ++p;
        }else{
            *error_p = i+1;
            *error_value = NO_FRACTION_ERROR;
            return;
        }
        
      	while (isdigit(*p)){
            value = value + fraction * ((*p) - '0');
            fraction *= 0.1;
            ++p;
        }
    }
    
    if (negate){
        value = -1*value;
    }
    
    //Exponent
    //----------------------
    if (*p == 'E' || *p == 'e') {
        ++p;
        switch (*p){
            case '-':
                ++p;
                negate = true;
                break;
            case '+':
                ++p;
            default:
                negate = false;
        }
        
        exponent_value = 0;
        while (isdigit(*p)) {
            exponent_value = 10*exponent_value + (double)((*p) - '0');
            ++p;
        }
        if (negate){
            exponent_value = -exponent_value;
        }
        value *= pow(10.0, exponent_value);
    }
    
    //TODO: We could still have:
    //(so '.' , '-', 'e', and 'E') (numbers would just be parsed)
    //- note, with no e or E, we only need to check '.' and '-'
    

    *value_p = value;
    
}

void string_to_double_v3(double *value_p, char *p, int i, int *error_p, int *error_value) {
    
    double value = 0;
    double fraction = 0;
    double exponent_value = 0;
    bool negate = (*p == '-');
    
    if (negate){
        ++p;
    }
    
    //Integer parsing
    //-------------------------------------------------------
    if (isdigit(*p)){
        value = 10*value + (double)(*p-'0');
        ++p;
    }else{
    	*error_p = i+1;
        *error_value = NO_NUMBER_ERROR;
        return;
    }
    
    while (isdigit(*p)){
        value = 10*value + (double)(*p-'0');
        ++p;
    }
    
    //Fraction
    //--------------------------------------------------------
    if (*p == '.') {
        ++p;
        if (isdigit(*p)){
            value = value + 0.1 * ((*p) - '0');
            fraction = 0.01;
            ++p;
        }else{
            *error_p = i+1;
            *error_value = NO_FRACTION_ERROR;
            return;
        }
        
      	while (isdigit(*p)){
            value = value + fraction * ((*p) - '0');
            fraction *= 0.1;
            ++p;
        }
    }
    
    if (negate){
        value = -1*value;
    }
    
    //Exponent
    //----------------------
    if (*p == 'E' || *p == 'e') {
        ++p;
        
        if (*p == '-'){
            negate = true;
            ++p;
            if (isdigit(*p)){
                exponent_value = 10*exponent_value + (double)((*p) - '0');
                ++p;
            }else{
             	*error_p = i+1;
                *error_value = NO_EXPONENT_ERROR;
            }
        }else if (isdigit(*p)){
            negate = false;
        }else if (*p == '+'){
            negate = false;
            ++p;
            if (isdigit(*p)){
                exponent_value = 10*exponent_value + (double)((*p) - '0');
                ++p;
            }else{
                *error_p = i+1;
                *error_value = NO_EXPONENT_ERROR;
            }
        }else{
            *error_p = i+1;
            *error_value = NO_EXPONENT_ERROR;
            return;
        }
        
        while (isdigit(*p)) {
            exponent_value = 10*exponent_value + (double)((*p) - '0');
            ++p;
        }
        if (negate){
            exponent_value = -exponent_value;
        }
        value *= pow(10.0, exponent_value); 
        
        //Test ('.' , '-', 'e', and 'E') 
    }else{
        //Test '.' , '-',
    }
    *value_p = value;   
}


//=========================================================================
//=========================================================================
void parse_numbers(unsigned char *js,mxArray *plhs[]) {
    //
    //  numeric_p - this array starts as a set of pointers
    //  to locations in the json_string that contain numbers.
    //  For example, we might have numeric_p[0] point to the following
    //  location:
    //
    //      {"my_value": 1.2345}
    //                   ^   
    //
    //  Some of these pointers may be null, indicating that a "null"
    //  JSON value occurred at that index in the array.
    //
    //  I am currently assuming that a pointer is 64 bits, which means
    //  that I recycle the memory to store the array of doubles
    
    //---------------------------------------------------------------------
    //The same memory is used twice. A value currently points to the start 
    //of a number to parse. After parsing the same location holds a double.
    mxArray *temp = mxGetFieldByNumber(plhs[0],0,E_numeric_p);
    
    int n_numbers = mxGetN(temp);
    
    if (n_numbers == 0){
        return;
    }
    
    //mexPrintf("%d %d\n",n_numbers,N_NUMBERS_FOR_PARALLEL);
    
    //Casting for input handling
    unsigned char **numeric_p = (unsigned char **)mxGetData(temp);
    
    //Casting for output handling (recycling of memory)
    double *numeric_p_double = (double *)mxGetData(temp);
    //---------------------------------------------------------------------
    
    int error_locations[MAX_OPENMP_THREADS];
    int error_values[MAX_OPENMP_THREADS];

    int n_threads = 1;
    
    if (n_numbers >= N_NUMBERS_FOR_PARALLEL){
        n_threads = omp_get_max_threads();
    }
    
    if (n_threads > MAX_OPENMP_THREADS){
        mexErrMsgIdAndTxt("turtle_json:max_thread_errors","stack allocation exceeded by # of threads");   
    }
    
    const double MX_NAN = mxGetNaN();
    
    //https://stackoverflow.com/questions/39116329/enable-disable-openmp-locally-at-runtime
     #pragma omp parallel if (n_numbers >= N_NUMBERS_FOR_PARALLEL)
     {
        int tid = omp_get_thread_num();
        int error_location;
        int error_value = 0;

        #pragma omp for 
        for (int i = 0; i < n_numbers; i++){
            //NaN values occupy an index space in numeric_p but have a null
            //value to indicate that they are NaN
            if (numeric_p[i]){
                string_to_double_v3(&numeric_p_double[i],numeric_p[i],i,&error_location,&error_value);
            }else{
                numeric_p_double[i] = MX_NAN;
            }
        }  
        
        error_locations[tid] = error_location;
        error_values[tid] = error_value;
    }
    
    //Error processing
    //--------------------------------------
    for (int i = 0; i < n_threads; i++){
        if (error_values[i]){
            int error_index = error_locations[i];
            //Note that we hold onto the pointer in cases of an error
            //It is not overidden with a double
            unsigned char *first_char_of_bad_number = numeric_p[error_index];

            //TODO: This is a bit confusing since this pointer doesn't
            //move but the other one does ...
            //TODO: Ideally we would pass these error messages into
            //a handler that would handle the last bit of formatting
            //and also provide context in the string
            //We would need the string length ...
            switch (error_values[i])
            {
                case NO_NUMBER_ERROR:
                    //TODO: This needs to be clarified ...
                    mexErrMsgIdAndTxt("turtle_json:no_numeric_component", \
                            "No integer component was found for a number (#%d in the file, at position %d)", \
                            error_index+1,first_char_of_bad_number-js+1);
                    break;
                case NO_FRACTION_ERROR:
                    mexErrMsgIdAndTxt("turtle_json:no_fractional_numbers",
                            "A number had a period, followed by no numbers (#%d in the file, at position %d)",error_index+1,first_char_of_bad_number-js+1);
                case NO_EXPONENT_ERROR:
                    mexErrMsgIdAndTxt("turtle_json:no_exponent_numbers",
                            "A number had an 'e' or 'E', followed by no numbers (#%d in the file, at position %d)",error_index+1,first_char_of_bad_number-js+1);    
                default:
                    mexErrMsgIdAndTxt("turtle_json:internal_code_error",
                            "Internal code error");   
            }
        }
    } 
}
//=====================   END OF NUMBER PARSING  ==========================