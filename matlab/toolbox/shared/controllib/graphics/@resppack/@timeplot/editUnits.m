function editUnits(this,parent,~)
% editUnits - Builds unit container for Bode plot

%   Copyright 1986-2020 The MathWorks, Inc.

AxGrid = this.AxesGrid;
data = localGetData(AxGrid);
if isempty(this.UnitsContainer) || ~isvalid(this.UnitsContainer)
    unitsContainer = AxGrid.editUnits(parent,'TimeUnits',data);
    this.UnitsContainer = unitsContainer;
else
    unitsContainer = this.UnitsContainer;
    widget = getWidget(unitsContainer);
    widget.Parent = parent;
end

% Listeners to update data
L = addlistener(unitsContainer,fieldnames(data),'PostSet',...
                    @(es,ed) localUpdateData(AxGrid,es,ed));
registerDataListeners(unitsContainer,L,'UpdateData');

% Listener to update UI
props = findprop(AxGrid,'XUnits');
L = handle.listener(AxGrid,props,'PropertyPostSet',{@localUpdateUI unitsContainer});
registerUIListeners(unitsContainer,L,'UpdateUI');

end

function localUpdateData(AxGrid,es,ed)
switch es.Name
    case 'TimeUnits'
        AxGrid.XUnits = ed.AffectedObject.TimeUnits;
end
end

function localUpdateUI(es,ed,unitsContainer)
switch es.Name
    case 'XUnits'
        unitsContainer.TimeUnits = ed.AffectedObject.XUnits;
end
end

function Data = localGetData(AxGrid)
Data = struct('TimeUnits',AxGrid.XUnits);
end
