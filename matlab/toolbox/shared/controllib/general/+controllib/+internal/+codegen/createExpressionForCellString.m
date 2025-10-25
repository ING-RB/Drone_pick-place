function Code = createExpressionForCellString(CellStrVar)
% Utility function to add MATLAB Code for Cell string vectors. If the
% vector is column, it creates new line for each entry. If it's row, it
% creates single row.

% Copyright 2014 The MathWorks, Inc.

Code = cell(0,1);

[m,n] = size(CellStrVar);

if ~(n==1 || m==1)
    error('Cell string must be a vector');
end

if m==1
    Code = {[controllib.internal.codegen.cellToString(CellStrVar) ';']};
else
    % first line
    Code{1,1} = sprintf('{''%s''; ...', CellStrVar{1});
    % second and other except last line
    for ct = 2:m-1
        Code{ct,1} = sprintf('''%s''; ...',CellStrVar{ct,1});
    end
    % last line
    Code{m,1}= sprintf('''%s''};',CellStrVar{m,1});
end