function [isValid, extraElement] = validateSubset(subset, fullset)
% Returns whether the subset is a valid subset of the full set
%
% Example: if a string appears e.g. 3 times in the full set,
% but appears more than 3 times in the subset, then the subset
% is not valid
%
% The full set is an array or cell array


if ~strcmp(class(fullset), class(subset))
    error('subset must be of same class than fullset');
end

% As we walk the subset, remove the elements from the
% fullset. If at some point, an element cannot be found, it
% means that the subset is not valid
remainingElements = fullset;

for k = 1:length(subset)
    % look for each element in subsetCell in remaining cell
    if(iscell(remainingElements))
        thisValue = subset{k};
    else
        thisValue = subset(k);
    end
    ind = matlab.ui.control.internal.model.PropertyHandling.findElementInVector(thisValue, remainingElements);

    if(isempty(ind))
        % this element appeared more time in subset than in the
        % full cell
        isValid = false;
        extraElement = thisValue;
        return;
    else
        % remove it from remainingElements
        remainingElements(ind) = [];
    end
end

isValid = true;
extraElement = [];
end