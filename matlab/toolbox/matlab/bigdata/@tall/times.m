function C = times(A,B)
%.* Array multiply.
%
%   See also tall/mtimes, tall.

% Copyright 2016-2022 The MathWorks, Inc.

allowTabularMaths = true;
allowedTypes = {'numeric', 'char', 'logical', 'categorical', ...
                'duration', 'calendarDuration', ...
                'cellstr', 'string'}; % 'cellstr'/'string' for combination with categorical
A = tall.validateType(A, mfilename, allowedTypes, 1, allowTabularMaths);
B = tall.validateType(B, mfilename, allowedTypes, 2, allowTabularMaths);

C = elementfun(@times, A, B);

% Calculate output type and size
unsizedAdaptor = multiplicationOutputAdaptor(mfilename, A, B);
C.Adaptor = copySizeInformation(unsizedAdaptor, C.Adaptor);
end
