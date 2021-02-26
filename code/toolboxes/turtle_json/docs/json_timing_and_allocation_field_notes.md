# Timing & Allocations #

If tokens are requested instead of the parsed data, it is possible to get access to the log structure. For example:

```matlab
f = json.tokens.load(file_path);
s = f.getLogStruct()
data = f.getParsedData()
```

This returns the following structure for `s`:

```
s = 

  struct with fields:

                obj__n_objects_at_depth: [1×21 int32]
                 arr__n_arrays_at_depth: [1×21 int32]
                           buffer_added: 1
              alloc__n_tokens_allocated: 2239379
             alloc__n_objects_allocated: 89576
              alloc__n_arrays_allocated: 89576
                alloc__n_keys_allocated: 447876
             alloc__n_strings_allocated: 447876
             alloc__n_numbers_allocated: 2239379
              alloc__n_data_allocations: 1
            alloc__n_object_allocations: 1
             alloc__n_array_allocations: 1
               alloc__n_key_allocations: 1
            alloc__n_string_allocations: 1
           alloc__n_numeric_allocations: 1
                obj__max_keys_in_object: 21
                  obj__n_unique_objects: 2
                time__elapsed_read_time: 23.7160
                time__c_parse_init_time: 1.2430 
                     time__c_parse_time: 20.8200 
         time__parsed_data_logging_time: 0.4740
         time__total_elapsed_parse_time: 22.5380
              time__object_parsing_time: 4.0250
                 time__object_init_time: 0.0500
               time__array_parsing_time: 0.9000
              time__number_parsing_time: 1.6750
    time__string_memory_allocation_time: 140.3320
              time__string_parsing_time: 24.8490
            time__total_elapsed_pp_time: 171.8510
           time__total_elapsed_time_mex: 218.1370
                               qpc_freq: 0
                                n_nulls: 0
                               n_tokens: 363026
                               n_arrays: 11171
                              n_numbers: 39095
                              n_objects: 22340
                                 n_keys: 150795
                              n_strings: 134040

```

Keys with the `alloc__` prefix indicate either the # of items allocated or the of times an allocation call was made. For example, space to save details about  447876 strings was allocated (`alloc__n_strings_allocated`) with 1 allocation call (`alloc__n_string_allocations`), but only 134040 strings existed. Note, these are not string allocations, but rather information that I used to keep track of strings, such as their start and stop location. At one point I had created a generic information holder for all token types but I found it difficult to use so instead I started holding onto arrays of information for all token types separately. If we had exceeded 447876 strings another allocation call would have been made. Initial allocation sizes are estimated based on the length of the input string OR based on options the user passes in. 

The timing entries are in milliseconds. Notable times include:

- **time__c_parse_time**: Time to localize all tokens in the file. After this point I know where everything starts and ends.
- **time__object_parsing_time**: Time to process objects. In particular templates are created for each unique object and the identity of each object relative to these unique objects is established.
- **time__array_parsing_time**: The main challenge here is to identify types
so that we know if we have matrices or higher-order arrays or structure/object arrays.
- **time__number_parsing_time**: The time necessary to turn text into binary representations of numbers.
- **time__string_memory_allocation_time**: The amount of time it takes to actually allocate strings in memory. This is often quite long.
- **time__string_parsing_time**: Time it takes to go through and process any escape characters or unicode characters.
- **time__total_elapsed_pp_time**: Total elapsed time post-processing.
- **time__total_elapsed_time_mex**: This consists of the initial parse time and the post-processing time.
