function editUnits(this,parent,~)
% editUnits - Builds unit container for Nyquist plot

%   Copyright 1986-2020 The MathWorks, Inc.

AxGrid = this.AxesGrid;
data = localGetData(this);
if isempty(this.UnitsContainer) || ~isvalid(this.UnitsContainer)
    unitsContainer = AxGrid.editUnits(parent,'NyquistUnits',data);
    this.UnitsContainer = unitsContainer;
else
    unitsContainer = this.UnitsContainer;
    widget = getWidget(unitsContainer);
    widget.Parent = parent;
end

% Listeners to update data
L = addlistener(unitsContainer,fieldnames(data),'PostSet',...
                    @(es,ed) localUpdateData(this,es,ed));
registerDataListeners(unitsContainer,L,'UpdateData');

% Listener to update UI
props = findprop(this,'FrequencyUnits');
L = handle.listener(this,props,'PropertyPostSet',{@localUpdateUI unitsContainer});
registerUIListeners(unitsContainer,L,'UpdateUI');

end

function localUpdateData(this,es,ed)
switch es.Name
    case 'FrequencyUnits'
        this.FrequencyUnits = ed.AffectedObject.FrequencyUnits;

end
end

function localUpdateUI(es,ed,unitsContainer)
switch es.Name
    case 'FrequencyUnits'
        unitsContainer.FrequencyUnits = ed.AffectedObject.FrequencyUnits; 
end
end

%%%%%%%%%%%%%%%%
% localGetData %
%%%%%%%%%%%%%%%%
function Data = localGetData(this)
Data = struct('FrequencyUnits',this.FrequencyUnits);
end