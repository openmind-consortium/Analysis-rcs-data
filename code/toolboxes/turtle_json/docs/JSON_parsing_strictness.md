Although JSON appears to be relatively simple, it has a lot of edge cases that many parsers parse differently. This is described pretty well here: http://seriot.ch/parsing_json.php

This parser is not a strict JSON parser and parses some files that other parsers might consider to be invalid. Of particular note is a set of tests from json.org (see test suite at http://www.json.org/JSON_checker/). 

The following are json.org tests that "should" fail but that we allow to pass.

```
Test 18: '[[[[[[[[[[[[[[[[[[[["Too deep"]]]]]]]]]]]]]]]]]]]]'

Test 25: '["	tab	character	in	string	"]'

Test 27: '["line
break"]'
```

Allowing these tests to pass is done for two reasons. First, there is no specified depth limit for JSON parsing (although this parser has one, just larger than the test). Second, this parser doesn't invalidate strings with control characters in them such as tabs or newlines that aren't escaped.

 