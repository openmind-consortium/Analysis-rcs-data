# Code Layout

## C Code ##

The C code consists of two programs. One parses JSON into an intermediate data structure (tokenizes the data) and the other converts that structure into Matlab data structures.

### Tokenizer ###

The following are the relevant tokenizer files, in order of usage:

1. turtle_json_mex.c - the entry point for the parser, sets up the code
2. turtle_json_main.c - the main parser that identifies the tokens
3. turtle_json_post_process.c - adds additional information to the tokens such as
..* the numeric values of identified numbers
..* the string values of identified strings
..* whether an object array is homogenous or not

Note, the post-processor relies on other helper files.

The output from the tokenizer is a large Matlab structure. The format of this structure is discussed in the [C Data Model](c_data_model_and_outputs.md)

### Tokens to Data ###

With the output structure from the initial tokenization, we still don't have data objects which represent the JSON. This is accomplished by json_info_to_data.c. This file actually consists of multiple different programs that convert the parsed data into Matlab data structures depending on what the user wants to retrieve. These are largely exposed to the user through the Matlab code.

## Matlab Code ##

The Matlab code wraps the c code, allowing access to either the tokenizer or to a fully parsed representation of the JSON data. The tokenizer returns a root token (either object or array), which can then be used to return subsets of the data (through calls to json_info_to_data.c).

Entry functions are:
1. json.load - JSON file to Matlab data
2. json.parse - JSON string to Matlab data
3. 
