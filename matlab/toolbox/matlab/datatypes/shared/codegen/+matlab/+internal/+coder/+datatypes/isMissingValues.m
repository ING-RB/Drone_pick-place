function tf = isMissingValues(a)  %#codegen
%ISMISSINGVALUES Find missing entries.
%   IA = ISMISSINGVALUES(A) returns a logical array IA indicating the
%   missing values found in A. IA has the same size as A.
%
%   Code generation currently does not support ismissing. This is a
%   simplified version limited only to one input and limited only to
%   types that code generation currently supports.

%   Copyright 2018-2020 The MathWorks, Inc.
coder.internal.prefer_const(a);
coder.extrinsic('cellfun');

if isnumeric(a)
    tf = isnan(a);
elseif isa(a, 'categorical')
    tf = isundefined(a);
elseif ischar(a)  % char vector
    tf = isempty(strtrim(a));
elseif matlab.internal.coder.datatypes.isCharStrings(a)  %cellstr
    if coder.internal.isConst(a)
        tf = coder.const(cellfun('isempty', feval('strtrim', a)));
    else
        tf = false(size(a));
        for i = 1:numel(a)
            if isempty(strtrim(a{i}))
                tf(i) = true;
            end
        end
    end
else
    tf = false(size(a));
end
