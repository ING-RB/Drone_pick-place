function index = findElementInVector(element, array)
% FINDINDEXOFELEMENTINVECTOR - This function mimics find and
% returns the indicies of the array that match the element

try
    if iscell(array) && ~iscell(element)
        % Try using ismember for improved performance
        [~, index] = ismember({element}, array);
    elseif ~iscell(array) && ~isscalar(element) || isgraphics(element)
        % When array is a non-cell array, element must be
        % scalar in order for ismember to be used
        index = matlab.ui.control.internal.model.PropertyHandling.findElementInVectorUsingIsequal(element, array);
    else
        % Try using ismember for improved performance
        [~, index] = ismember(element, array);
    end
    index =  index( index ~= 0 );

catch ME %#ok<NASGU>
    % Find the index of valueData in ItemsData
    % If there are duplicates, pick the first one
    index = matlab.ui.control.internal.model.PropertyHandling.findElementInVectorUsingIsequal(element, array);
end
end