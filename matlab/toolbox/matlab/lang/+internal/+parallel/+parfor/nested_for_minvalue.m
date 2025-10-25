function out = nested_for_minvalue(a,d,b)
%NESTED_FOR_MINVALUE Minimum value of nested-FOR range

% Copyright 2023 The MathWorks, Inc.
colonDesc = matlab.internal.ColonDescriptor(a,d,b);
out = colonDesc.minValue();
end
