#include "turtle_json.h"

//http://stackoverflow.com/questions/19813718/mex-files-how-to-return-an-already-allocated-matlab-array


//http://stackoverflow.com/questions/18847833/is-it-possible-return-cell-array-that-contains-one-instance-in-several-cells
mxArray *mxCreateReference(const mxArray *mx)
{
    struct mxArray_Tag_Partial *my = (struct mxArray_Tag_Partial *) mx;
    ++my->RefCount;
    return (mxArray *) mx;
}

//TODO: Rename this ...
void *get_field(mxArray *plhs[],const char *fieldname){
    mxArray *temp = mxGetField(plhs[0],0,fieldname);
    return mxGetData(temp);
}

uint8_t *get_u8_field_by_number(mxArray *p, int fieldnumber){
    mxArray *temp = mxGetFieldByNumber(p,0,fieldnumber);
    uint8_t *data = (uint8_t *)mxGetData(temp);
    return data;
}

uint8_t * get_u8_field(mxArray *p,const char *fieldname){
    mxArray *temp = mxGetField(p,0,fieldname);
    uint8_t *data = mxGetData(temp);
    //This is a temporary check
    if (data == 0){
    	mexErrMsgIdAndTxt("turtle_json:bad_pointer","bad pointer %s",fieldname);
    }
    return data;
}

int *get_int_field_by_number(mxArray *p, int fieldnumber){
    mxArray *temp = mxGetFieldByNumber(p,0,fieldnumber);
    int *data = (int *)mxGetData(temp);
    return data;
}

int *get_int_field(mxArray *p,const char *fieldname){
    mxArray *temp = mxGetField(p,0,fieldname);
    int *data = mxGetData(temp);
    //This is a temporary check
    //Apparently this doesn't work ...
    if (data == 0){
    	mexErrMsgIdAndTxt("turtle_json:bad_pointer","bad pointer %s",fieldname);
    }
    return data;
}

mwSize get_field_length(mxArray *plhs[],const char *fieldname){
    mxArray *temp = mxGetField(plhs[0],0,fieldname);
    return mxGetN(temp);
}    

mwSize get_field_length2(mxArray *p,const char *fieldname){
    mxArray *temp = mxGetField(p,0,fieldname);
    return mxGetN(temp);
}   

void setStructField2(mxArray *s, void *pr, mxClassID classid, mwSize N, int field_id)
{
    //This is a helper function for setting the field in the output struct.
    //It should only be used on dynamically allocated memory.
        
    mxArray *pm;
    
    pm = mxCreateNumericMatrix(1, 0, classid, mxREAL);
    mxSetData(pm, pr);
    mxSetN(pm, N);
    mxSetFieldByNumber(s,0,field_id,pm);
}
    
void setStructField(mxArray *s, void *pr, const char *fieldname, mxClassID classid, mwSize N)
{
    //This is a helper function for setting the field in the output struct.
    //It should only be used on dynamically allocated memory.
        
    mxArray *pm;
    
    pm = mxCreateNumericArray(0, 0, classid, mxREAL);
    mxSetData(pm, pr);
    mxSetM(pm, 1);
    mxSetN(pm, N);
    mxAddField(s,fieldname);
    mxSetField(s,0,fieldname,pm);
}
//-------------------------------------------------------------------------
void setIntScalar(mxArray *s, const char *fieldname, int value){

    //This function allows us to hold onto integer scalars
    //We need to make an allocation to grab a value off the stack
    
    mxArray *pm;
    
    int *temp_value = mxMalloc(sizeof(double));
    
    *temp_value = value;
    
    pm = mxCreateNumericArray(0, 0, mxINT32_CLASS, mxREAL);
    mxSetData(pm, temp_value);
    mxSetM(pm, 1);
    mxSetN(pm, 1);
    mxAddField(s,fieldname);
    mxSetField(s,0,fieldname,pm);    
    
}