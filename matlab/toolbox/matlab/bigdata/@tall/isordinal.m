function tf = isordinal(a)
%ISORDINAL True if the categories in a categorical array have a mathematical ordering.
%   TF = ISORDINAL(A)
%
%   See also CATEGORICAL/ISORDINAL, TALL.

%   Copyright 2017-2021 The MathWorks, Inc.

if a.Adaptor.Class == "categorical"
    tf = a.Adaptor.IsOrdinal;
else
    tf = false;
end
