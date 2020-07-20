function prepStructs()

filename = 'tj_fields.txt';
rootpath = '/Users/jim/Documents/repos/matlab_git/turtle_json/src/c_code/private';
filepath = fullfile(rootpath,filename);

wtf = textscan(fileread(filepath),'%s%s%s','Delimiter','\t','CollectOutput',true);
wtf = wtf{1};

%remove first row
wtf(1,:) = [];

is_array = strcmp(wtf(:,3),'array');

%Enumerations

names = wtf(is_array,1);

enum_strings2 = cellfun(@(x) ['E_' x],names,'un',0);

new_str = join(enum_strings2,sprintf(',\n'));

%*****
final_enum_str = new_str{1};


%*****
field_strings = cellfun(@(x) ['"' x '"'],names,'un',0);

new_str = join(field_strings,sprintf(',\n'));
final_fields_str = new_str{1};




end