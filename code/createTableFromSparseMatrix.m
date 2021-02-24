function [outputTable] = createTableFromSparseMatrix(sparseMatrix, columnNames)
%%
% Function to re-create a table from a sparse matrix
%
%%
outputTable = full(sparseMatrix);
outputTable(outputTable == 0) = NaN;
outputTable = array2table(outputTable,'VariableNames',columnNames);

end