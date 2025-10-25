function areElementsPresent = areElementsPresent(elements, array)
% Checks if each in ELEMENTS is in ARRAY, and
% returns array of logical values the same size as elements.
%
% Inputs:
%
%  ELEMENTS - a 1xN array or cell array that represents mathc
%  query
%  ARRAY -  a 1xN array or cell array
%
%           All elements in the array must support isequal().
%
% The inputs have limited validation to improve performance.
% Combinations that will use the optimized algorithm:
%             * element *          * array *
%             cellstr              cellstr
%             vector char array    cellstr
%             scalar array         array    (of same datatype)
% Ouputs:
%
%  ISELEMENTPRESENT - true if ELEMENT was found in ARRAY,
%                     according to isequal()
narginchk(2, 2)

% Value must be a cell with elements in (truncated)
% ItemsData
try
    if iscell(array) && ~iscell(elements)
        % Try using ismember for improved performance
        areElementsPresent = ismember({elements}, array);
    else
        % Try using ismember for improved performance
        areElementsPresent = ismember(elements, array);
    end
catch me

    areElementsPresent = matlab.ui.control.internal.model.PropertyHandling.areElementsPresentUsingIsEqual(elements, array);
end
end