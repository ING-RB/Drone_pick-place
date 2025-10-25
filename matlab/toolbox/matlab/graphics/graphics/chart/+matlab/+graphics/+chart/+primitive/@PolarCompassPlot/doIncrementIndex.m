function [index,interp] = doIncrementIndex(obj, index, direction, ~)
%

%  Copyright 2024 The MathWorks, Inc.

interp = 0;

% Transform R and Theta data to reflect on-screen locations.
rmag = obj.RDataCache - obj.BaseValue_I;
isNeg = rmag < 0;
r = abs(rmag) + obj.BaseValue_I;
theta = obj.ThetaDataCache;
theta(isNeg) = theta(isNeg) + pi;
theta = mod(theta,2*pi);

% Sort data to allow navigation from vertex to vertex in on-screen order,
% around the polar axes.
data = [ theta(:) r(:) ];
[~, sortInds] = sortrows(data,1);
currIdx = find(sortInds==index);
if isempty(currIdx)
    currIdx = 1;
end

% Keyboard navigation will simply increment or decrement the index,
% essentially navigating from vertex to vertex in one or the other
% direction around the polar axes. 
switch(direction)
    case {'up', 'left'} 
        currIdx = currIdx + 1;
    case {'down', 'right'}
        currIdx = currIdx - 1;
end
currIdx = mod(currIdx,height(data));
currIdx(currIdx == 0) = height(data); % when the modulus is zero, treat it as the final index
index = sortInds(currIdx);
end
