function tokenErrorTest(test_number,cur_test_string,error_id)
%
%   json_tests.utils.tokenErrorTest(test_number,cur_test_string,error_id)

    try
        root = json.tokens.parse(cur_test_string);
        error('Test #%d should have thrown an error but didn''t',test_number);
    catch ME
        
        if ~strcmp(ME.identifier,error_id)
            %A hack for getting ME.identifier
            if strcmp('asdf',error_id)
                fprintf('%s\n',ME.identifier);
                return
            end
            disp(ME)
            error('Test: %d failed, but with the incorrect error, expecting: %s',test_number,error_id);
        else
            fprintf('Test %d failed as expected\n',test_number);
        end
    end

end