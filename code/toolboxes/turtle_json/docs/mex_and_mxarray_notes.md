# Intro #

This is meant to be a place where I log peculiarities related to mx functions.

# Function List #

mxAddField - https://www.mathworks.com/help/matlab/apiref/mxaddfield.html

# Ref Incrementing #

mxArrayToString



# mxCreateStructMatrix #

mxCreateStructMatrix accepts

https://www.mathworks.com/matlabcentral/answers/315937-mxcreatestructarray-and-mxcreatestructmatrix-field-name-memory-management

https://www.mathworks.com/matlabcentral/answers/316130-get-a-subset-of-a-structure-array-in-mex


# Other Notes #

mxArrayToString - does this verify we are working with a string? Does it throw an error or does it silently fail???

# Good Links #

https://www.mathworks.com/matlabcentral/answers/251011-depth-of-mexmakearraypersistent

# Undocumented mex functions #

# Shared data copy #

http://stackoverflow.com/questions/19813718/mex-files-how-to-return-an-already-allocated-matlab-array



5) mxCreateSharedDataCopy (returns shared data copy)

6) mxGetReference (returns reference count)

7) mxCreateReference (returns input with reference count bumped up by 1)

8) mxUnshareArray (unshares array suitable for cell array manipulation)

9) mxUnreference (decrements reference count by 1)

10) mxIsSharedArray (returns sharing status)

11) mxSetReferenceCount (sets reference count)

12) mxCreateUninitDoubleMatrix (returns double matrix with uninitialized data ... fast)

13) mxCreateUninitDoubleArray (returns double array with uninitialized data ... fast)

14) mxCreateUninitNumericArray (returns numeric array with uninitialized data ... fast)

15) mxFastZeros (returns double matrix with 0's ... fast)

16) mxGetUserBits (gets highest 8 bits of variable flags)

17) mxSetUserBits (sets highest 8 bits of variable flags)

18) mxIsA (checks to see if variable is a specified class)