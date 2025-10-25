function Z = rdivide(X, Y)
%./ Right array divide.

% Copyright 2016-2022 The MathWorks, Inc.

narginchk(2,2);
allowTabularMaths = true;
[X, Y] = tall.validateType(X, Y, mfilename, ...
                           {'numeric', 'logical', 'duration', 'char'}, 1:2, allowTabularMaths);

% divisionOutputAdaptor throws up-front errors for invalid combinations
outAdaptor = divisionOutputAdaptor(mfilename, X, Y);
Z = elementfun(@rdivide, X, Y);
Z.Adaptor = copySizeInformation(outAdaptor, Z.Adaptor);
end
