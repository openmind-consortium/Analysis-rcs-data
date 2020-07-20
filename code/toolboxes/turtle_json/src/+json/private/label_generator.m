%This is some code I wrote to generate code

%http://llvm.org/builds/


temp = cell(1,256);
temp(:) = {'&&S_ERROR_TOKEN_AFTER_COMMA_IN_ARRAY'};
temp([46 49:58]) = {'&&S_PARSE_NUMBER_IN_ARRAY'};
temp{'n'+1} = '&&S_PARSE_NULL_IN_ARRAY';
temp{'t'+1} = '&&S_PARSE_TRUE_IN_ARRAY';
temp{'f'+1} = '&&S_PARSE_FALSE_IN_ARRAY';
temp{'"'+1} = '&&S_PARSE_STRING_IN_ARRAY';
temp{'{'+1} = '&&S_OPEN_OBJECT_IN_ARRAY';
temp{'['+1} = '&&S_OPEN_ARRAY_IN_ARRAY';

clipboard('copy',['const void *array_jump[256] = {' sl.cellstr.join(temp,'d',',') '};'])

%TODO: Fix this, it is incorrect - fix negative

temp = cell(1,256);
temp(:)={'false'};
temp([45 49:58]) = {'true'};
clipboard('copy',['const bool is_start_of_number[256] = {' sl.cellstr.join(temp,'d',',') '};'])
 
temp = cell(1,256);
temp(:)={'false'};
temp(49:58) = {'true'};
clipboard('copy',['const bool is_number_array[256] = {' sl.cellstr.join(temp,'d',',') '};'])
 

 %NOTE: the ascii table is actually 1 based as well so we add 1
 %i.e. in Matlab, space is 32
 %in c, space is also 32
 %This arises since the 1st character in the ascii table starts counting at 0
 temp = cell(1,256);
 temp(:)={'false'};
 ws_chars = [' ',sprintf('\n'),sprintf('\r'),sprintf('\t')];
 temp(double(ws_chars)+1) = {'true'};
 clipboard('copy',['const bool is_whitespace[256] = {' sl.cellstr.join(temp,'d',',') '};'])
 
 
 %POSITIVE_VALUES
 values = 1:9;
 n_entries = 16;
 str = cell(1,n_entries);
 for i = 1:n_entries
 temp = cell(1,58);
 temp(:) = {'0'};
 temp(50:58) = arrayfun(@(x) sprintf('%d',x),values*1*10^(i-1),'un',0);
 str{i} = ['const double p1e' int2str(i-1) '[58] = {' sl.cellstr.join(temp,'d',',') '};'];
 end
 clipboard('copy',sl.cellstr.join(str,'d',char(10)))

 
 
 values = 1:9;
 %   1.json had 20 :/
 n_entries = 30;
 str = cell(1,n_entries);
 for i = 1:n_entries
 temp = cell(1,58);
 temp(:) = {'0'};
 format = ['%0.' int2str(i) 'f'];
 temp(50:58) = arrayfun(@(x) sprintf(format,x),values.*10^(-i),'un',0);
 str{i} = ['const double p1e_' int2str(i) '[58] = {' sl.cellstr.join(temp,'d',',') '};'];
 end
 clipboard('copy',sl.cellstr.join(str,'d',char(10)))
