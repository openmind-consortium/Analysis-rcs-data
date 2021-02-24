function object_tests()
%
%   json_tests.toTokens.object_tests

%{
    json_tests.toTokens.object_tests
%}

fprintf('Running toTokens.object_tests()\n')

n = 0;

fh2 = @json_tests.utils.runTest;
encode = @json_tests.utils.encodeJSON;
getC = @(x) json.utils.getPerformanceLog(x.mex);


%==========================================================================
%                       Correct Object Tests
%==========================================================================
%Empty object - should be ok
n = n + 1;
json_tests.utils.tokenPassTest(n,'{}')

%TODO: Test a utf-8 encoded key ...

%'empty and non-empty objects'
data = {struct,struct('a',1)};
n = n + 1;
json_tests.utils.tokenPassTest(n,encode(data))

%Tests on aspects of the parsing
%--------------------------------------------------------------------------
data = {struct('ab',1,'ac',2),struct('ab',2,'ad',3)};
root = json_tests.utils.tokenPassTest(n,encode(data));
temp = getC(root);
if temp.obj__n_unique_objects ~= 2
   error('The # of unique objects should have been 2'); 
end

data = [struct('ab',1,'ac',2),struct('ab',2,'ac',3)];
root = json_tests.utils.tokenPassTest(n,encode(data));
temp = getC(root);
if temp.obj__n_unique_objects ~= 1
   error('The # of unique objects should have been 1'); 
end

%TODO: We need to test the methods ...????
%i.e. the methods of the token object

%==========================================================================
%                       Invalid Object Tests
%==========================================================================
%'3 should be a key, not a numeric'
n = n + 1;
json_tests.utils.tokenErrorTest(n,'{"key":1,3}','turtle_json:no_key')

%'Missing key'
n = n + 1;
json_tests.utils.tokenErrorTest(n,'{:3}','turtle_json:invalid_token')










end