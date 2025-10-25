function data = splitSlices(data, indices)
% Split a chunk of slices into a cell array of smaller chunks using indices
% to mark which cell each slice should be sent.

% Copyright 2017-2018 The MathWorks, Inc.

[hasComplexVariables, complexVariables] = matlab.io.datastore.internal.getComplexityInfo(data);

% The splitapply function unwraps one level of table. To avoid doing this
% to data, we wrap tables up before splitapply.
if istable(data) || istimetable(data)
    data = table(data);
end

if isempty(indices)
    data = cell(0,1);
else
    data = splitapply(@iEncellify, data, indices);
end

% Splitapply on tables with complex variables will drop complexity on
% non-complex blocks.
if hasComplexVariables
    for ii = 1 : numel(data)
        data{ii} = matlab.io.datastore.internal.applyComplexityInfo(data{ii}, complexVariables);
    end
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function x = iEncellify(x)
% Place the entire group in a single cell.
x = {x};
end
