#include "mex.h"

/*
 *
 * mex setField.c
 * s = struct;
 * wtf = setField(s,'wtf batman',5);
 *
 * %Override test
 * wtf = setField(wtf,'wtf batman',1);
 *
 * %More testing
 * wtf.test = 3;
 * wtf.nope = 4;
 * wtf = setField(wtf,'nope','cheese');
 * wtf = setField(wtf,'! !','wow');
 * wtf = setField(wtf,'test',struct());
 *
 */

mxArray *mxCreateSharedDataCopy(const mxArray *mx);
#define COPY_ARRAY mxCreateSharedDataCopy

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray*prhs[])
{
    
    //  new_struct = setField(struct,name,value)
    
    //Use cases
    //---------
    //1) Valid field name, just use dynamic - inside Matlab
    //2) field name already exists, need to override
    //3) Doesn't exist,
    
    
    // Input checking
    // --------------
    if (nrhs != 3) {
        mexErrMsgIdAndTxt("mexSetField:bad_n_input","3 inputs required for mexSetField");
    }
    if (nlhs > 1) {
        mexErrMsgIdAndTxt("mexSetField:bad_n_output","1 ouput allowed for mexSetField");
    }
    
    //Check this before 1st input, because depending on type of 1st input
    //we might end early
    if (!mxIsChar(prhs[1])){
        mexErrMsgIdAndTxt("mexSetField:bad_type_input","2nd input should be a string");
    }
    
    // Type of input arguments: Struct or empty matrix
    const mxArray *S = prhs[0];
    if (!mxIsStruct(S)) {
        //In Matlab we can do:
        //s = []
        //s.a = 3; %converts s to a struct
        //This is really handy for non-initialized properties
        //that become structs on initialization
        if (mxIsDouble(S) && mxGetNumberOfElements(S) == 0) {
            plhs[0] = mxCreateStructMatrix(1,1,0,NULL);
            char *field_to_set = (char *) mxArrayToString(prhs[1]);
            mxAddField(plhs[0],field_to_set);
            mxSetField(plhs[0],0,field_to_set,COPY_ARRAY(prhs[2]));
            mxFree(field_to_set);
            return;
        }
        mexErrMsgIdAndTxt("mexSetField:bad_type_input","1st input should be a struct");
    }
    
    
    
    
    //Retrieval of inputs
    
    char *field_to_set = (char *) mxArrayToString(prhs[1]);
    mxArray *value_to_set = COPY_ARRAY(prhs[2]);
    
    mwSize n_existing_fields = mxGetNumberOfFields(S);
    //mwSize n_elements = mxGetNumberOfElements(S);
    
    //2) Does this field exist
    
    int field_number_of_input = mxGetFieldNumber(S, field_to_set);
    
    bool field_exists = field_number_of_input >= 0;
    
    int n_fields_allocate;
    
    if (field_exists){
        n_fields_allocate = n_existing_fields;
    }else{
        field_number_of_input = n_existing_fields;
        n_fields_allocate = n_existing_fields + 1;
    }
    
    
    
    // Get list of field names:
    const char **field_list = (const char **) mxMalloc(n_fields_allocate * sizeof(char *));
    if (field_list == NULL) {
        mexErrMsgIdAndTxt("mexSetField:fieldnames", "Cannot get memory for fieldnames.");
    }
    
    for (int iField = 0; iField < n_existing_fields; iField++) {
        field_list[iField] = mxGetFieldNameByNumber(S, iField);
    }
    
    if (field_exists){
        mxFree(field_to_set);
    }else{
        field_list[n_existing_fields] = field_to_set;
    }
    
    //TODO: This should be checked, we aren't supporting
    //anything greater than 1
    // Create the output struct:
    plhs[0] = mxCreateStructArray(mxGetNumberOfDimensions(S),
            mxGetDimensions(S), n_fields_allocate, field_list);
    
    // Copy fields for each element of the struct array S:
    //for (iElem = 0; iElem < n_elements; iElem++) {
    
    for (int iField = 0; iField < field_number_of_input; iField++) {
        mxSetFieldByNumber(plhs[0], 0, iField,
                COPY_ARRAY(mxGetFieldByNumber(S, 0, iField)));
    }
    
    for (int iField = field_number_of_input + 1; iField < n_fields_allocate; iField++) {
        mxSetFieldByNumber(plhs[0], 0, iField,
                COPY_ARRAY(mxGetFieldByNumber(S, 0, iField)));
    }
    
    mxSetFieldByNumber(plhs[0], 0, field_number_of_input, value_to_set);
    
    // Cleanup:
    mxFree(field_list);
    
    
}