expanded_database = [];

for rowidx = 1:size(sorted_database, 1)
    tmp_row = sorted_database(rowidx,:);  %tmp_row is the row with multiple entries
    if size(tmp_row.time{1}, 1) > 1  % duplicating entire row if there are multiple entries per session
        for new_row = 1:size(tmp_row.time{1}, 1)
            expanded_database = [expanded_database; tmp_row];
            for col_name = ["time", "duration", "TDfs"]
                expanded_database{end, col_name}{1} = expanded_database{end, col_name}{1}(new_row);
            end

%            see if anyoverlapping times 
%         matchstr = strcmp([expanded_database.time{end}],[expanded_database.time{:}]')

        if  ~(numel(unique([expanded_database.time{:}]')) == size(expanded_database,1))
            disp(['Duplicate detected!  - ' num2str(size(expanded_database,1))])
        end


            %make the first subsession an integer (like 2), and  all subsessions
            %decimals like  2.01, 2.02, etc.
            if new_row ==1
                expanded_database.rec(end) = tmp_row.rec;
            else
                expanded_database.rec(end) = tmp_row.rec + ((new_row-1)/100);
            end

        end
    else  % print the single value  if only one entry per session

        expanded_database = [expanded_database; tmp_row];
        for col_name = ["time", "duration", "TDfs"]
            expanded_database{end, col_name}(1) = expanded_database{end, col_name}(1);
        end
    end
end