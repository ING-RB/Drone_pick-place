function editUnits(this,parent,~)
% editUnits - Builds unit container for Sigma plot

%   Copyright 1986-2020 The MathWorks, Inc.

[data,tag] = LocalGetUnits(this);
AxGrid = this.AxesGrid;

if isempty(this.UnitsContainer) || ~isvalid(this.UnitsContainer)
    unitsContainer = AxGrid.editUnits(parent,tag,data);
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
props = [findprop(this.AxesGrid,'XUnits'); findprop(this.AxesGrid,'YUnits');...
         findprop(this.AxesGrid,'XScale'); findprop(this.AxesGrid,'YScale')];
L = handle.listener(this.AxesGrid,props,'PropertyPostSet',{@localUpdateUI unitsContainer});
registerUIListeners(unitsContainer,L,'UpdateUI');




end

function localUpdateData(AxGrid,es,ed)
switch es.Name
    case 'FrequencyUnits'
        AxGrid.XUnits = ed.AffectedObject.FrequencyUnits;
    case 'FrequencyScale'
        AxGrid.XScale{1} = ed.AffectedObject.FrequencyScale;
    case 'MagnitudeUnits'
        AxGrid.YUnits = ed.AffectedObject.MagnitudeUnits;
    case 'MagnitudeScale'
        AxGrid.YScale{1} = ed.AffectedObject.MagnitudeScale;
end
end

function localUpdateUI(es,ed,unitsContainer)
switch es.Name
    case 'XUnits'
        unitsContainer.FrequencyUnits = ed.AffectedObject.XUnits;
    case 'XScale'
        unitsContainer.FrequencyScale = ed.AffectedObject.XScale{1}; 
    case 'YUnits'
        unitsContainer.MagnitudeUnits = ed.AffectedObject.YUnits;
    case 'YScale'
        unitsContainer.MagnitudeScale = ed.AffectedObject.YScale{1};
end
end


function [Data,Label] = LocalGetUnits(this)
% Get the Units Data for @editbox

Data = struct('FrequencyUnits',this.AxesGrid.XUnits,...
   'MagnitudeUnits',this.AxesGrid.YUnits,...
   'FrequencyScale',this.AxesGrid.XScale{1},...
   'MagnitudeScale',this.AxesGrid.YScale{1});
Label = 'SigmaUnits';
end