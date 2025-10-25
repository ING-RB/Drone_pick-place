function validateBackgroundColor(filename, value)
% Validate 'BackgroundColor'

% Copyright 2020 The MathWorks, Inc.

% This check is here due to how validatecolor works.  Otherwise a call like
% this: validatecolor(white) <note: no quotes> produces awkward error.
if isnumeric(value)
    validateattributes(value, {'numeric'}, {'vector'}, filename, 'BackgroundColor');
end

validatecolor(value);