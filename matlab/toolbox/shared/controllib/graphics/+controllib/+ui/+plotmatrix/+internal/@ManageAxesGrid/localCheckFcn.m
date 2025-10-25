function result = localCheckFcn(x)
% Check if input x is valid for number of rows and columns.

%   Copyright 2015-2020 The MathWorks, Inc.

result = false;
if isreal(x) && isnumeric(x) && isscalar(x) && (x>0) && mod(x,1) == 0 && ~isnan(x) && ~isinf(x)
    result = true;
else
    error(message('Controllib:general:UnexpectedError', ...
        'Number of rows and columns should be a positive scalar integer'));
end
end
