function areElementsPresent = areElementsPresentUsingIsEqual(elements, array)
% Checks if each in ELEMENTS is in ARRAY, and
% returns array of logical values the same size as elements.
%
% Functionality mirrors areElementsPresent
% Functionality is robust across all datatypes, but may be a
% slower choice than ismember, strcmp, == and other types of
% comparisons
narginchk(2, 2)

% Value must be a cell with elements in (truncated)
% ItemsData
if(iscell(array))
    areElementsPresent = cellfun(@(x) matlab.ui.control.internal.model.PropertyHandling.isElementPresent(x, array), elements);
else
    areElementsPresent = arrayfun(@(x) matlab.ui.control.internal.model.PropertyHandling.isElementPresent(x, array), elements);
end

end