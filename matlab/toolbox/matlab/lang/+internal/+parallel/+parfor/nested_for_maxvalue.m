function out = nested_for_maxvalue(a,d,b)
%NESTED_FOR_MAXVALUE Maximum value of nested-FOR range

% Copyright 2023 The MathWorks, Inc.
colonDesc = matlab.internal.ColonDescriptor(a,d,b);
out = colonDesc.maxValue();
end
