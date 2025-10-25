function validateAxesVisibility(filename, value)
% Validate 'AxesVisibility'

% Copyright 2022 The MathWorks, Inc.
if isstring(value) || ischar(value)
    validatestring(value, {'on','off'}, filename, 'AxesVisibility');
elseif isa(value, 'matlab.lang.OnOffSwitchState')
    % always valid
else
    validateattributes(value, {'numeric','logical'}, ...
        {'scalar','binary'}, filename, 'AxesVisibility');
end