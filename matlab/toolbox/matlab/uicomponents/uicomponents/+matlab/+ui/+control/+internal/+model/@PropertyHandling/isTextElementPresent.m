function isElementPresent = isTextElementPresent(element, array)
% Checks if ELEMENT is in ARRAY,
% returns true or false.
%
% Inputs:
%
%  ARRAY -  a 1xN array or cell array
%
%           All elements in the array must support isequal().
%
% Ouputs:
%
%  ISELEMENTPRESENT - true if ELEMENT was found in ARRAY,
%                     according to isequal()
narginchk(2, 2)

if(isempty(array)) || isempty(element) && iscell(element)
    isElementPresent = false;
elseif isscalar(element) || matlab.ui.control.internal.model.PropertyHandling.isString(element)
    % strcmp requires element be scalar or a char array
    isElementPresent = any(strcmp(element, array));
else
    % Returning false when element does not match expected
    % dimensions is consistent with isElementPresent
    isElementPresent = false;
end
end