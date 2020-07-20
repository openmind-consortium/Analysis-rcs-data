function array_tests()
%
%   json_tests.toTokens.array_tests

%{
    json_tests.toTokens.array_tests
%}

fprintf('Running json_tests.toTokens.array_tests \n')
fh2 = @json_tests.utils.runTest;
encode = @json_tests.utils.encodeJSON;

%Generic tests
%--------------------------------------------------------------------------
fh2(1,'[1,2,3]','','numeric array test',(1:3)');
fh2(0,'[1,2,]','turtle_json:invalid_token','trailing comma');
fh2(0,'[1,,2,3]','turtle_json:invalid_token','comma with no value');
fh2(0,'[,]','turtle_json:invalid_token','comma with no value');
fh2(0,[repmat('[',1,300) '1' repmat(']',1,300)],'turtle_json:depth_exceeded','array that is too deep for the parser');

%Numeric Arrays
%--------------------------------------------------------------------------
%This is essentially:
%reshape(1:6,[2,3])
%I just haven't written the proper encoder
fh2(0,'[[1,2],[3,4],[5,6]]','','numeric array test',[[1;2],[3;4],[5;6]]);



% % fh2(1,'{"key":1,3}','turtle_json:no_key','3 should be a key, not a numeric','');
% % fh2(0,'{:3}','turtle_json:invalid_token','Missing key');
% % fh2(0,'{}','','empty object',struct); %empty object should be ok
% % 
% % data = {struct,struct('a',1)};
% % fh2(0,encode(data),'','empty and non-empty objects',data);
% % 
% % %Tests on aspects of the parsing
% % %--------------------------------------------------------------------------
% % data = {struct('ab',1,'ac',2),struct('ab',2,'ad',3)};
% % fh2(0,encode(data),'','2 different structs',data,...
% %     @(x) x.root.mex.object_info.n_unique_objects == 2,'The # of unique objects should have been 2');
% % data = [struct('ab',1,'ac',2),struct('ab',2,'ac',3)];
% % fh2(0,encode(data),'','2 different structs',data,...
% %     @(x) x.root.mex.object_info.n_unique_objects == 1,'The # of unique objects should have been 1');



end