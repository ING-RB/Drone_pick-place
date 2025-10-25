function isElementAcceptable = validateStatesElement(element)
% Validates that the given element is a valid element for a
% State array.
%
% Inputs:
%
%  ELEMENT - the value to validate.  Acceptable values are:
%            -- numeric scalar
%            -- logical scalar
%            -- 1xN char or ''
%
% Outputs:
%
%  ISELEMENTACCEPTABLE - true if the element was acceptable,
%                        false otherwise

% Numeric or Logical is acceptable if it is a scalar
if(isnumeric(element) || islogical(element))
    isElementAcceptable = isscalar(element);
    return;
end

% String
try
    % Verify that it is a string (1xN char or '')
    element = matlab.ui.control.internal.model.PropertyHandling.validateText(element);

    isElementAcceptable = true;
catch ME %#ok<NASGU>
    isElementAcceptable = false;
end

end