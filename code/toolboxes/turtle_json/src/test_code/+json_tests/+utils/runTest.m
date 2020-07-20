function [output_test_number,root,data] = runTest(reset_test_number,cur_test_string,error_id,memo,expected_value, post_test, post_test_error_msg)
%
%   Call Forms
%   ----------
%   [output_test_number,root,data] = json_tests.utils.runTest(reset_test_number,cur_test_string,error_id,memo,expected_value)
%
%   ... = runTest(reset_test_number,cur_test_string,error_id,memo,expected_value, post_test, post_test_error_msg)
%
%   ... = runTest(reset_test_number,cur_test_string,error_id,memo,expected_value, parse_options)
%
%   Inputs
%   ------
%   reset_test_number: logical
%       If true, resets the internal test counter
%   cur_test_string: string
%       json string to parse
%   error_id: string
%       If not empty, an error is expected.
%   memo: string
%       Not used, this is just a note to self.
%   expected_value: anything
%       Value to compare the returned to.
%   post_test: function handle
%       Should take in the result, and return true if the test passed
%   post_test_error_msg: string
%       The error message that should be displayed if the post_test fails.



persistent test_number

    if exist('post_test','var')
        parse_options = post_test;
        clear post_test;
    else
        parse_options = {};
    end

    if reset_test_number
        test_number = 1;
    else
        test_number = test_number + 1;
    end

    output_test_number = test_number;
    
    should_pass = isempty(error_id);

    try
        root = json.tokens.parse(cur_test_string);
        data = root.getParsedData(parse_options{:});
        s.root = root;
        s.data = data;
        passed = true;
    catch ME
        passed = false;
        if should_pass
            disp(ME)
            error('Test #%d should have not thrown an error but did',test_number);
        elseif ~strcmp(ME.identifier,error_id)
            disp(ME)
            error('Test: %d failed, but with the incorrect error, expecting: %s',test_number,error_id);
        else
            fprintf('Test %d failed as expected\n',test_number);
        end
    end
    
    if passed && ~should_pass
        error('Test #%d should have thrown an error but didn''t',test_number);
    elseif passed
        
        if ~isempty(expected_value) && ~isequal(data,expected_value)
            error('Test #%d failed because the parsed data did not match the expected value',test_number)
        else
            if exist('post_test','var')
                if post_test(s)
                   fprintf('Test %d passed as expected\n',test_number);
                else
                   error('Test %d failed: %s',test_number, post_test_error_msg);
                end
            else
                fprintf('Test %d passed as expected\n',test_number);
            end
        end
    end

end