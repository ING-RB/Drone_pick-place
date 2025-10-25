function unitsContainer = editUnits(this,parent,tag,data)
% editUnits - Build container for editing units and add to tab.

% Copyright 1986-2021 The MathWorks, Inc.

unitsContainer = localBuildUI(this,data);
widget = getWidget(unitsContainer);
widget.Tag = tag;
widget.Parent = parent;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function unitsContainer = localBuildUI(~,data)
typeOfUnits = fieldnames(data);
unitsContainer = controllib.widget.internal.cstprefs.UnitsContainer(typeOfUnits{:});
unitsContainer.ValidFrequencyUnits = controllibutils.utGetValidFrequencyUnits;
unitsContainer.ValidTimeUnits = controllibutils.utGetValidTimeUnits;
for k = 1:length(typeOfUnits)
    unitsContainer.(typeOfUnits{k}) = data.(typeOfUnits{k});
end
end

