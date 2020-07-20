# Design Choices

## Numbers

* **Numbers are stored as doubles.** This could eventually change, but that's how it is for now. In particular this means parsing of large integers will fail.


## Ambiguous JSON Design Decisions

* '[]' translates into an empty numeric array rather than an empty cell array (NYI)


### Numeric arrays
 redundant



* '[[1,2],[3,4],[5,6]]' - translates into a numeric array of size [2,3] (in other words, the default behavior is to keep values ordered in memory, rather than needing to shuffle them