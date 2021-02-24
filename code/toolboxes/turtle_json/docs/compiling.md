# Compiling

The c code currently uses arrays of pointers to labels. Out of the common compilers, I think GCC is the only one that supports this code. Thus GCC needs to be installed.

On a mac I installed GCC using Homebrew. On Windows I installed GCC using mingw.

I wrote mex_maker to make compiling these types of files a bit easier. The provided code requires the mex_maker repo.

https://github.com/JimHokanson/mex_maker

Compile via:
mex_turtle_json