# Data Model

Following is a description of the internal data model used during parsing. This document is useful if:

1. You want to understand what I'm doing in the C code
2. You want to write your own code that works on the initial tokenized data.

Tokens include:

    * Object  {
    * Array   [
    * Key     :
    * String  "
    * Number  1
    * Null    null  - I represent null as NaN
    * True    true
    * False   false


## Things that exist for every token ##

There are two arrays that have elements for each token. The order of the entries is in the order in which they are encountered. Thus the first value corresponds to the first token. This order is often used to navigate between elements, particularly for arrays.

* types: [uint8]
  * types include object, array, key, string, etc. 
  * Values are defined in turtle\_json.h => e.g. 4 is the string type
* d1: [int32]
  * Indices (0 based) into type based indices. For example, a value of 2 means we've encountered our 3rd string at this location, and this entry corresponds with any other arrays that describe string data (where length equals # of strings or more generically, # of elements of type)
  * Unique index counts are for objects, arrays, keys, strings. Numbers and nulls form one group and true and false another (logicals).
  * In code, I've tried to refer to this as the **md\_index (main data index)**
  * Since the values (indices) are incremental (by type), this can serve as an indicator of the # of values between two different locations, e.g. if d1[100] == 30 and d1[105] == 35, and types[100] == types[105], then types[101:104] == types[100] and d1[101] == 31, and d1[102] == 32, etc. Put another way, if for example some entry is the 10th number, and two elements later is the 12th number, then the element in between must be the 11th number.

## Data Type Specific Information ##

### Objects ###

After parsing we a have a set of unique objects (**objects**) as well as an id (**object_ids**) that specifies for each object which unique object it matches. Following is the other object information that is generated during parsing. The following information is visible in **mex.object_info**.

**The following information is parsed in the initial pass through.**

* **child\_count\_object** - int32[] (length = # of objects)
    *  \# of keys in the object
* **next\_sibling\_index\_object** - int32[] (length = # of objects)
    * index into 'd1' of the token after the object closes
    * this can be used to navigate to the next token
    * out of all the 'next' pointers is probably the least used
* **object\_depths** - uint8[]
    * depth at which the object occurs. The top most level is 1 (0 based indexing) (0 is not used)
    * This is a temporary variable. We later go back and populate an array where we put all objects at the same depth together for comparison of field names (keys). Objects at the same depth tend to have the same keys.
* **n\_objects\_at\_depth** - int32[]
    * The # of objects at each depth.
    * This is a temporary variable as it allows for creating a single array in which we can place all objects of a certain depth together in a subset of the array.

**The following information is parsed in post-processing.**

* **max\_keys\_in\_object** - int32[]
    * The maximum # of keys present in any object
    * This is largely a temporary variable when needing to allocate key (field) names later on
* **unique\_object\_first\_md\_indices** - int32[] (length = # of unique objects)
    * The first object which has fieldnames of the given type
    * This is meant to allow post-processing of the key name (NYI)
* **object\_ids** - int32[] (length = # of objects)
    * values specify which object the current object is like
    * e.g. object_ids[5] => 2, means that the fifth object (1 based) is the 3rd unique object type (0 based)
    * values are indices (0 based) into the 'objects' property
* **n\_unique\_objects** - int32
    * The # of unique objects, where being unique means a unique set of key names (not values)
    * In the current implementation, order matters, so changing the key order would create more unique objects
* **objects** - cell array of structures (length = # of unique objects)
    * Each structure is of size [1 0] but contains the parsed (i.e. non UTF-8) fieldnames in that object. This makes it easy to initialize an object as we simply copy this base object and resize.

### Arrays ###

* **n\_arrays\_at\_depth** - int32 (length = # of allocated depths)
  * \# of array elements detected at each level of nesting
* **child_count_array** - int32 (length = # of arrays)
  * \# of direct children in the array (as opposed to including children of the children)
* **next_sibling_index_array** - int32 (length = # of arrays)
  * index into 'd1' of the token after the array closes
  * this can be used to navigate to the next token
* **array_depths** - int32 (length = # of arrays)
  * nesting depth of the array relative to the rest of the file
  * A value of 0 indicates that the array is the top-most array. There is only ever one array that can have a value of 0.

**The following information is parsed in post-processing.**

* **array_types** - int32 (length = # of arrays)
  * Indicates the array type (see below)

**Valid array types include**

* **ARRAY_OTHER_TYPE (0)** - indicates that the array is not one of the other types
* **ARRAY_NUMERIC_TYPE (1)** - indicates 1d numeric array (e.g. [1,2,3])
* **ARRAY_STRING_TYPE (2)** -
* **ARRAY_LOGICAL_TYPE (3)** -
* **ARRAY_OBJECT_SAME_TYPE (4)** -
* **ARRAY_OBJECT_DIFF_TYPE (5)** -
* **ARRAY_ND_NUMERIC (6)** -
* **ARRAY_ND_STRING (7)** -
* **ARRAY_ND_LOGICAL (8)** -
* **ARRAY_EMPTY_TYPE (9)** - An array with no elements
* **ARRAY_ND_EMPTY (10)** - A ND array that contains other empty ND arrays or empty 1D arrays (e.g. [[]] or [[],[]])

#define ARRAY_OTHER_TYPE   0 //Not one of the other types below - default
#define ARRAY_NUMERIC_TYPE 1 //1D numeric
#define ARRAY_STRING_TYPE  2 //1D string
#define ARRAY_LOGICAL_TYPE 3 //1D logical
#define ARRAY_OBJECT_SAME_TYPE  4 //All objects with same field names (order matters)
#define ARRAY_OBJECT_DIFF_TYPE 5 //All objects but with different field names (or order)
#define ARRAY_ND_NUMERIC 6
#define ARRAY_ND_STRING 7
#define ARRAY_ND_LOGICAL 8
#define ARRAY_EMPTY_TYPE 9 //Array with no elements
#define ARRAY_ND_EMPTY 10


### Keys ###

### Strings ###

### Numbers ###

### Logicals ###

### Timing Info ###

All reported timing values are in seconds.

* **elapsed\_read\_time** - how long it took to read the file from disk
* **parsed\_data\_logging\_time** - ????
* **elapsed\_parse\_time** - time to parse initial token locations
* **object\_parsing\_time** - time to determine unique objects
* **array\_parsing\_time** - time to identify array types (homogenous, non-homogenous, 1d arrays, nd arrays, etc.)
* **number\_parsing\_time** - time to convert strings into numbers
* **string\_memory\_allocation_time** - the amount of time required to allocate memory for all strings in the file
* **string\_parsing\_time** - time required to convert strings from bytes (UTF-8) into Matlab strings (UTF-16)
* **elapsed\_pp\_time** - total amount of time spent in post-processing (objects, arrays, numbers, strings)
* **total\_elapsed\_time_mex** - total amount of time spent in the mex code
