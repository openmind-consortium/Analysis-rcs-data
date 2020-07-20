function varargout = tokenPassTest(test_number,cur_test_string)
%
%   root = json_tests.utils.tokenPassTest(test_number,cur_test_string)

    try
        root = json.tokens.parse(cur_test_string); 
        if nargout
            varargout{1} = root;
        end
    catch ME
        disp(ME)
        error('Test #%d should have thrown an error but didn''t',test_number);
    end

end