function [table] = addRowToTable(newEntry,table)
%%
% Add row of new data to table
%%

% If table is empty, need to populate fields; for subsequent records just
% add as new ro
if isempty(table)
    table = struct2table(newEntry,'AsArray',true);
else
    table = [table; struct2table(newEntry,'AsArray',true)];
end

end
