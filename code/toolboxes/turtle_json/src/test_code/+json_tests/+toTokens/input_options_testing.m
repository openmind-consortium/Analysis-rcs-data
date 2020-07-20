function input_options_testing()
%
%   json_tests.toTokens.input_options_testing
%
%   Options are detailed in json.load


%{
    json_tests.toTokens.input_options_testing
%}

fprintf('Running toTokens.input_options_testing()\n');

leadin = 'json_tests.toTokens.input_options_testing: ';
fh2 = @json_tests.utils.runTest;
encode = @json_tests.utils.encodeJSON;
getC = @(x) json.utils.getMexC(x.mex);

%TODO: Missing passing a string into the file parser

%==========================================================================
%                           Correct behavior
%==========================================================================
%1) Adding a buffer manually 
%----------------------------------------
js = '["this is a test"]';      js(end+1:end+17) = [0 '\"' zeros(1,14)];
root = json.tokens.parse(uint8(js));
temp = getC(root);  
if temp.buffer_added
    error([leadin 'byte buffer should not have been added ...']);
end

%   n_tokens : double (default )
%       # of tokens expected in the file. Default is ...
%   n_keys : double (default )
%       # of keys expected in the file. 
%   n_strings : double
%       # of strings expected in the file.
%   n_numbers : double
%       # of numbers expected in the file.

root = json.tokens.parse(uint8(js),'n_tokens',15,'n_keys',15,'n_strings',15,'n_numbers',15);
temp = getC(root);  
if temp.alloc__n_tokens_allocated ~= 15 || ...
   temp.alloc__n_keys_allocated ~= 15 || ...
   temp.alloc__n_strings_allocated ~= 15 || ...
   temp.alloc__n_numbers_allocated ~= 15

end

%TODO: Do a reallocation check on all types ..., perhaps at border values
%or in a loop with values ... i.e. 5 to 50 elements with intial at 15


%==========================================================================
%                           Incorrect behavior
%==========================================================================


%- bad option name
%- missing name
%- incorrect variable range ...




%TODO: Fix this ...
%This doesn't work, something is not working with mxArrayToString
if false
fh2(0,js,'','testing the buffer adding','',...
    @(x) x.root.mex.buffer_added == 0,'The buffer should not have been added');
end











% % % t = json.tokens.parse(uint8(js));
% % % 
% % % fh2(1,'{"key":1,3}','turtle_json:no_key','3 should be a key, not a numeric','');
% % % fh2(0,'{:3}','turtle_json:invalid_token','Missing key');
% % % fh2(0,'{}','','empty object',struct); %empty object should be ok



% % % js = '["this is a test"]';
% % % 
% % % %This is an incorrect usage, throw 'turtle_json:file_open'
% % % t = json.fileToTokens(js);
% % % 
% % % js = '["this is a long test"';
% % % js(end+1:205) = 'a';
% % % js(end) = ']';
% % % %This is an incorrect usage, throw 'turtle_json:file_open'
% % % t = json.fileToTokens(js);


% % % % % t = json.tokens.parse(js);
% % % % % 
% % % % % 
% % % % % %assert('t.
% % % % % %t.mex.buffer_added should be 0
% % % % % 
% % % % % 
% % % % % %This doesn't work, perhaps the conversion function is poor
% % % % % js = '["this is a test"]';
% % % % % js(end+1:end+17) = [0 '\"' zeros(1,14)];
% % % % % 
% % % % % %We're introducing a mismatch here ...
% % % % % js(end-5) = 'a'; 
% % % % % tic; t = json.stringToTokens(js); toc;
% % % % % %t.mex.buffer_added should be 1
% % % % % tic; t = json.stringToTokens(uint8(js)); toc;
% % % % % 
% % % % % t = json.stringToTokens(js);

end