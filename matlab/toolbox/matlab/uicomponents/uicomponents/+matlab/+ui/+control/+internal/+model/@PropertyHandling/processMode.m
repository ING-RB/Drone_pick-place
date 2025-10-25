function output = processMode(component, input)
% Validates that the given input is a valid string for a
% 'Mode' property.
%
% The original string is returned, where it is guaranteed to be
% the property lower case value 'auto' or 'manual', if the
% passed in input was not of the proper case.
%
% Inputs:
%
%  INPUT  - the input from a user to validate
%
%           An error is thrown if INPUT is not valid.
%
% Ouputs:
%
%  OUTPUT - the property value a component should store.
%
%           An example would be if the user typed 'Auto', and
%           the component wants to store the proper value
%           'auto'.
output = matlab.ui.control.internal.model.PropertyHandling.processEnumeratedString(...
    component, ...
    input, ...
    {'auto', 'manual'});
end