function string_tests()
%
%   json_tests.toTokens.string_tests
%
%   See Also
%   --------
%   json_tests.json_checker_tests

%   Format
%   ------
%   1) string
%   2) empty string to pass,
%   3) notes on reason for error or thing being tested
%   4) expected answer

fprintf('Running toTokens.string_tests()\n')

fh = @(x) char(org.apache.commons.lang.StringEscapeUtils.unescapeJava(x));

fh2 = @json_tests.utils.runTest;

%Tests focused on string termination
%-----------------------------------
fh2(1,'["This is a test]',      'turtle_json:unterminated_string',  'Missing closing quotes','');
fh2(0,'["This is a test\"]',    'turtle_json:unterminated_string',  'Missing closing quote, quote character escaped','');
%TODO: Add on correct answers for these
fh2(0,'["Hello \" World"]',     '',                                 'Escaped quote character with proper closing of string','');
fh2(0,'["Hello World\\"]',      '',                                 'Escape character is escaped, so string is terminated','');
fh2(0,'["Hello World\\\"]',     'turtle_json:unterminated_string',  'unterminated string','');
fh2(0,'["Hello World\\\\"]',    '',                                 'terminated string','');


%Tests focused on the proper escapes of characters
%--------------------------------------------------
%1) Valid escape characters
%2) Characters that need to be escaped => less than 32

fh2(0,'["This \" is a test"]','', 'Escape of " character',{sprintf('This \" is a test')});

fh2(0,'["This \n is a test"]','', 'Escape of \n character',{sprintf('This \n is a test')});
fh2(0,'["15\u00f8C 3\u0111"]','', 'Escape of unicode characters',{fh('15\u00f8C 3\u0111')});

%TODO: Add on UTF-8 check 


end