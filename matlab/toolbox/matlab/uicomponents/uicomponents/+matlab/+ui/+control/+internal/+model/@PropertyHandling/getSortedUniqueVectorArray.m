function array = getSortedUniqueVectorArray(array, direction)
% GETSORTEDUNIQUEVECTORARRAY
% This utility assumes that the input valid.  It sorts the
% array in ascending order, removes duplicates and returns the
% vector in a consistent direction

if ~isempty(array)
    % Unique may change the size of the array from 0x0 to 0x1
    % Avoid unique if array is empty

    % Remove duplicates
    array = unique(array);

    % Sort in ascending order
    array = sort(array);
end
% Orient array
array = matlab.ui.control.internal.model.PropertyHandling.getOrientedVectorArray(array, direction);

end