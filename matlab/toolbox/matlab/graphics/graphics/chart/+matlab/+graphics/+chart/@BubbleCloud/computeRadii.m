function computeRadii(obj)
%

%   Copyright 2020 The MathWorks, Inc.

% Compute the sorted radii of bubbles, excluding zero/non-finite bubbles.
% The sorted radii are stored in the third row of obj.XYR

sz=obj.SizeData_I;
areas=double(sz);

% radii is root area (constant pi multiplier is irrelevant)
if ~isreal(areas)
    warning(message('MATLAB:specgraph:private:specgraph:UsingOnlyRealComponentOfComplexData'));
end
radii=sqrt(real(areas));

% obj.XYR(3,:) will store the sorted, finite, radii.
% obj.RadiusIndex will be the index of SizeData that
% corresponds to obj.XYR.
[sortedradii,sortind]=sort(radii,'descend');

validind=isfinite(sortedradii) & sortedradii>0;
sortind=sortind(validind);
sortedradii=sortedradii(validind);

if obj.MaxDisplayBubbles<numel(sortind)
    sortind=sortind(1:obj.MaxDisplayBubbles);
    sortedradii=sortedradii(1:obj.MaxDisplayBubbles);
end

obj.RadiusIndex=sortind;

% Normalize radii so that the largest bubble has a radius of 1
if ~isempty(sortedradii)
    sortedradii=sortedradii/max(sortedradii);
end
obj.XYR=nan(3,numel(sortedradii));
obj.XYR(3,:)=sortedradii;
end

% LocalWords:  XYR
