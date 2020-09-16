function logical_array_tests()

%   json_tests.toData.logical_array_tests

fh2 = @json_tests.utils.runTest;
encode = @json_tests.utils.encodeJSON;

fprintf('json_tests.toData.logical_array_tests\n');

%--------------------------
data = 1:10 > 3;
fh2(1,encode(data),'','1d logical array testing',data');
%----------------------------
data = reshape(data,5,2);
%Note, the transpose is due to differences in default array ordering
%behavior between the writer and the reader
fh2(1,encode(data),'','1d logical array testing',data');




end