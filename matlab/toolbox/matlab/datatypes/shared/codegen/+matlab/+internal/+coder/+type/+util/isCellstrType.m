function tf = isCellstrType(val, allowempty)
% Check whether input is a cellstr. Input can be an
% array or a coder type.

% Copyright 2020 The MathWorks, Inc.

if nargin < 2
    allowempty = true;
end

if isa(val, 'coder.Type')
    tf = strcmp(val.ClassName, 'cell');
    if tf
        valcells = val.Cells;
        for i = 1:numel(valcells)
            tf = tf && strcmp(valcells{i}.ClassName, 'char') && ...
                valcells{i}.SizeVector(1) == 1 && ~valcells{i}.VariableDims(1) && ...
                (allowempty || valcells{i}.SizeVector(2) > 0);
        end
    end
else
    tf = iscellstr(val) && (allowempty || ~any(cellfun('isempty', val),'all'));  %#ok<ISCLSTR>
end