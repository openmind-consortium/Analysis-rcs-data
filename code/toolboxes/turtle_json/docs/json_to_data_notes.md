# JSON to Data notes #

These are largely notes to self on functions that are available in "json_info_to_data.c"

json_info_to_data converts the tokenized JSON information into a Matlab data structure. Additionally it can be used return other information about the parsing.

The general form is:

```
data = json_info_to_data(function_option_number, mex_struct, <other_inputs>)
```

`function_option_number` is a selector for which function to run, from 0,1,2,...,n

`mex_struct` is the structure output from turtle_json_mex

`other_inputs` varies based on the function option number. These are described below.

# 0 - Full Parse #

Function 0 runs a full parse starting at a particular location.

```data = json_info_to_data(0, mex_struct, md_index_1b)```

```md_index_1b``` Is the index of the data to parse. The root value starts at 1. Other values need to be navigated using functions in the tokens class.

This option uses default rules for parsing. TODO: Document this more fully (it is sort of evident from the other functions)

```

```



# 1 - Get Key Index #

```index_1b = json_info_to_data(1, mex_struct, obj_md_index, key_name)```

Given an object and a key name, get the index of the key in the object. An additional check is made to verify that the key is in the object.

```obj_md_index``` - index of an object 
```key_name``` - name of the key/field to retrieve

# 2 - Get Key Value Type and Index #

```[key_value_type,md_index_1b] = json_info_to_data(2,mex_struct,obj_md_index,key_index_1b)```

Returns the numeric type of the value of the key (string, number, etc) as well as the index of the value. This index can be used to retrieve the actual value.

```obj_md_index``` - index of an object 
```key_index_1b``` - index of the key

# 3 - Get Homogenous Array #

```cellstr = json_info_to_data(3,mex_struct,array_md_index)```

```data = json_info_to_data(3, mex_struct, array_md_index, expected_type, min_dimension, max_dimension, *options)```

TODO: Describe this ...

# 4 - Not implemented #

# 5 - Not implemented #

# 6 - Partial Object Parsing #

```[struct,key_location] = json_info_to_data(6, mex_struct, object_index, keys_no_parse, keep_all_keys)```

Parse only certain fields of an object.

```
s = struct;
s.a = 'test';
s.b = 1:10;
s.c = [false true];
s.d = 'don''t parse me now because I''m too long';

json_str = jsonencode(s);

temp = json.tokens.parse(json_str);

%Let's keep d in case we want it later ...
s2 = temp.parseExcept({'d'},true);

s2 = 

  struct with fields:

    a: 'test'
    b: [10×1 double]
    c: [2×1 logical]
    d: []
    
%We don't need 'd'
s2 = temp.parseExcept({'d'},false);

s2 = 

  struct with fields:

    a: 'test'
    b: [10×1 double]
    c: [2×1 logical]


```

# 7 - Full options parse #

```data = json_info_to_data(7,mex_struct,start_index,options)```

TODO: Describe this ...



