This code parses JSON files/strings using C (mex) code. Writing is not supported.

# Why This Code?

I needed JSON parsing for a project. Loading JSON files using existing parsers was painfully slow. This slowness was due to 1) JSON parsing being done in Matlab or 2) parsing using C/C++ or Java, but with inefficient memory structures. This code started off by wrapping an already written C JSON tokenizer, and then post-processing in Matlab. After some nit-picking here and there, I found myself writing an entire parser in C, from scratch.

More on "why/how" can be found here: [https://jimhokanson.com/blog/2018/2018_01_Turtle_JSON_Intro/](https://jimhokanson.com/blog/2018/2018_01_Turtle_JSON_Intro/)

More on performance can be found here: [https://jimhokanson.com/blog/2018/2018_08_Turtle_JSON_speed/](https://jimhokanson.com/blog/2018/2018_08_Turtle_JSON_speed/)

# Advantages and Disadvantages

## Advantages
* C parser written specifically for Matlab, rather than wrapping an existing parser
* multi-step parsing option (tokens, then data) for complete control over output format
* Just like every other "fast" JSON parser, this one is fast as well.

## Disadvantages
* I used a non-native compiler for both Windows and Mac (GCC)
* Currently favors speed over memory usage (this can be improved)
* Currently requires newer computers due to use of SIMD (I believe I'm only using AVX so ~2011 or newer processor required). Ideally a switch would allow an option not to use SIMD.

## Limitations

* Number parsing is ok but will probably be inaccurate at the very edges (this could be improved)
* Overflow of UTF-8 past 2 bytes replaces the characters with an invalid-char (or out of range? I forget ...)
* Parser won't catch edge errors in JSON files (leading 0s in numbers, characters - like newline - that aren't escaped in strings, etc.). In general these shouldn't impact most users but this parser should not be used to validate if the file is valid JSON.
* No support for integers (in particular 64 bit integers). Everything gets returned as a double.
* The information returned during error parsing could be improved to provide more context in the file.

TODO: Provide a link to the standard JSON tests and show which ones pass and which ones don't (like I would say that '03' is ok for 3 whereas technically the leading 0 is invalid)

# Status

* Parser design is stable.
* Tests are in place although more could be added to get better coverage (help on this is always appreciated!)
* Lots of small issues, although nothing critical.

# Usage

## Requirements

1. 64bit Matlab on Windows or Mac.
2. A computer that supports AVX instructions (~2011 and newer)

## Setup

Two folders in the repository need to be added to the path. These are:

1. ./src/
2. ./src/c_code

Note that the "+json" folder is a package. Packages should not be added to the path. To call code in a package, the folder that contains the package (in this case "src") must be added to the path.

I'm currently distributing compiled mex files. More details on compiling can be found at [here](./docs/compiling.md)

## Parsing to a Complete Matlab Data Structure

Parsing can be done in one of two ways. Parsing can either be done to a set of tokens or alternatively, to a complete representation of the structure in Matlab. Parsing to tokens provides finer control over the parsing process.

The simplest approach is to parse directly to a Matlab data structure. 

```matlab
data = json.load(file_path);
%OR
data = json.parse(json_string);
```

Note there are options that can control the mapping from JSON to Matlab structures.
```
%TODO: Document this option
data = json.load(file_path,{},{'column_major',false});

%Other options can be found in the json.load documentation

```

## Parsing to Tokens

For those that want a bit more control over the parsing process, one can parse to tokens, and then to data. Tokens include objects, arrays, numbers, etc. in the file. 

The following is an example.

```matlab
%This returns a tokenized representation of all of the data
root = json.tokens.load(file_path);
%OR
root = json.tokens.parse(json_string);

%Let's assume we got an object root, let's get the 'x_data' property.
x_data_token = root.getToken('x_data');

%Let's assume 'x_data' is an array, then 'x_data_token' contains information
%about that array, but it does not contain the actual data.

%Assuming 'x_data' should contain a cell array of 1d arrays
%e.g. x_data = {[1,2,3],[4],[5,6,7,8,9]}
x_data = x_data_token.getArrayOf1dNumericArrays();

%If 'x_data' is a 2d array (matrix)
x_data = x_data_token.get2dNumericArray();

%If 'x_data' is a 1d array
x_data = x_data_token.get1dNumericArray();

%If 'x_data' contains a cell array of strings
x_data = x_data_token.getCellstr();
```

# Matlab and JSON peculiarities

TODO: Document some issues and reference a different file
- nd arrays not completely specified
- UTF-8 support with 16 bit char in Matlab
- null as NaN double
- scalars
- field names

# Documentation

More documentation can be found in the [docs folder](./docs/)

# Contributing

Feel free to send me an email if you have an idea or want to discuss contributing. Please also open issues for questions, comments, or suggestions.



