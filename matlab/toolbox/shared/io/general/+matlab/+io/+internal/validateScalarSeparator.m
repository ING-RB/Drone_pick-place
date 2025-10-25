function tf = validateScalarSeparator(rhs)
% Checks the validity of separator characters, e.g. cannot be numbers 

% Copyright 2017 The MathWorks, Inc.
tf = ischar(rhs) && isscalar(rhs) && ~any(ismember(rhs,['0':'9' char(65535)]));
end

