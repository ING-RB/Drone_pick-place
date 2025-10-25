function editUnits(this,parent,~)
% editUnits - Builds unit container for Pole-Zero plot

%   Copyright 1986-2020 The MathWorks, Inc.

AxGrid = this.AxesGrid;
[data, noteText] = localGetData(this);
if isempty(this.UnitsContainer) || ~isvalid(this.UnitsContainer)
    unitsContainer = AxGrid.editUnits(parent,'PZUnits',data);
    widget = getWidget(unitsContainer);
    widget.RowHeight = [widget.RowHeight,{'fit'}];
    nRows = length(widget.RowHeight);
    nColumns = length(widget.ColumnWidth);
    label = uilabel(widget,'Text',noteText);
    label.Layout.Row = nRows;
    label.Layout.Column = [1 nColumns];
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
props = [findprop(this,'FrequencyUnits') ; findprop(this,'TimeUnits')];
L = handle.listener(this,props,'PropertyPostSet',{@localUpdateUI unitsContainer});
registerUIListeners(unitsContainer,L,'UpdateUI');

end


function localUpdateData(this,es,ed)
switch es.Name
    case 'FrequencyUnits'
        this.FrequencyUnits = ed.AffectedObject.FrequencyUnits;
    case 'TimeUnits'
        this.TimeUnits = ed.AffectedObject.TimeUnits;
end
end

function localUpdateUI(es,ed,unitsContainer)
switch es.Name
    case 'TimeUnits'
        unitsContainer.TimeUnits = ed.AffectedObject.TimeUnits;
    case 'FrequencyUnits'
        unitsContainer.FrequencyUnits = ed.AffectedObject.FrequencyUnits; 
end
end

%%%%%%%%%%%%%%%%
% localGetData %
%%%%%%%%%%%%%%%%
function [Data, noteText] = localGetData(this)
Data = struct('FrequencyUnits',this.FrequencyUnits,...
              'TimeUnits',this.TimeUnits);
noteText = ctrlMsgUtils.message('Controllib:gui:PZPlotFrequencyUnitDescriptionLabel');
end