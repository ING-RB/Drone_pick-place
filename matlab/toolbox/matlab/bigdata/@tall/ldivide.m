function Z = ldivide(X, Y)
%.\ Left array divide.

% Copyright 2016-2022 The MathWorks, Inc.

narginchk(2,2);
allowTabularMaths = true;
[X, Y] = tall.validateType(X, Y, mfilename, ...
    {'numeric', 'logical', 'duration', 'char'}, 1:2, allowTabularMaths);
% divisionOutputAdaptor throws up-front errors for invalid combinations
outAdaptor = divisionOutputAdaptor(mfilename, Y, X);
Z = elementfun(@ldivide, X, Y);
Z.Adaptor = copySizeInformation(outAdaptor, Z.Adaptor);
end
