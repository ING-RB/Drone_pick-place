function editUnits(this,parent,~)
% editUnits - Builds unit container for Bode plot

%   Copyright 1986-2020 The MathWorks, Inc.

AxGrid = this.AxesGrid;
data = localGetData(AxGrid);
if isempty(this.UnitsContainer) || ~isvalid(this.UnitsContainer)
    unitsContainer = AxGrid.editUnits(parent,'BodeUnits',data);
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
props = [findprop(AxGrid,'XUnits') ; findprop(AxGrid,'YUnits');...
         findprop(AxGrid,'XScale') ; findprop(AxGrid,'YScale')];
L = handle.listener(AxGrid,props,'PropertyPostSet',{@localUpdateUI unitsContainer});
registerUIListeners(unitsContainer,L,'UpdateUI');

end

function localUpdateData(AxGrid,es,ed)
unitsContainer = ed.AffectedObject;
switch es.Name
    case 'FrequencyUnits'
        AxGrid.XUnits = unitsContainer.FrequencyUnits;
    case 'FrequencyScale'
        AxGrid.XScale = repmat({unitsContainer.FrequencyScale},[length(AxGrid.XScale) 1]);
    case {'MagnitudeUnits','PhaseUnits'}
        AxGrid.YUnits = {unitsContainer.MagnitudeUnits ; unitsContainer.PhaseUnits};
    case 'MagnitudeScale'
        AxGrid.YScale = repmat({unitsContainer.MagnitudeScale ; AxGrid.YScale{2}},...
                                [length(AxGrid.YScale)/2 1]);
end
end

function localUpdateUI(es,ed,unitsContainer)
switch es.Name
    case 'XUnits'
        unitsContainer.FrequencyUnits = ed.AffectedObject.XUnits;
    case 'XScale'
        unitsContainer.FrequencyScale = ed.AffectedObject.XScale{1};
    case 'YUnits'
        unitsContainer.MagnitudeUnits = ed.AffectedObject.YUnits{1};
        unitsContainer.PhaseUnits = ed.AffectedObject.YUnits{2};
    case 'YScale'
        unitsContainer.MagnitudeScale = ed.AffectedObject.YScale{1};
end
end

function Data = localGetData(AxGrid)
Data = struct('FrequencyUnits',AxGrid.XUnits,...
   'MagnitudeUnits',AxGrid.YUnits{1},...
   'PhaseUnits',AxGrid.YUnits{2},...
   'FrequencyScale',AxGrid.XScale{1},...
   'MagnitudeScale',AxGrid.YScale{1});
end