function numVars = countTableVarInputs(args)
% Counting number of inputs, any in-memory string or char row vector is considered
% the beginning of p-v pair

% Copyright 2018-2023 The MathWorks, Inc.

numVars = 0;
for i = 1:length(args)
    numVars = i;
    if iIsInMemoryScalarText(args{i})
        numVars = numVars - 1;
        return
    end
end
end

function tf = iIsInMemoryScalarText(arg)
% Unlike isstring or ischar, isa(_, "char) and isa(_, "string")
% return false for tall and (co)distributed arrays. This ensures
% it's an in-memory argument.
tf = matlab.internal.datatypes.isScalarText(arg) ...
     && (isa(arg, "char") || isa(arg, "string"));
end
