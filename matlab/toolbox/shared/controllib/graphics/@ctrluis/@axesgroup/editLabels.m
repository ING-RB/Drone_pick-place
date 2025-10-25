function labelsContainer = editLabels(this,parent,rowIdx,columnIdx)
% Builds widget for editing axes labels.

% Copyright 1986-2023 The MathWorks, Inc.

arguments
    this
    parent
    rowIdx = 1
    columnIdx = 1
end

if isempty(this.LabelsContainer)
    labelsContainer = controllib.widget.internal.cstprefs.LabelsContainer;
    labelsContainer.Title = cellstr(this.Title);
    labelsContainer.XLabel = cellstr(this.XLabel);
    labelsContainer.YLabel = cellstr(this.YLabel);
    this.LabelsContainer = labelsContainer;
else
    labelsContainer = this.LabelsContainer;
end
widget = getWidget(labelsContainer);
widget.Parent = parent;
if isa(parent,'matlab.ui.container.GridLayout')
    widget.Layout.Row = rowIdx;
    widget.Layout.Column = columnIdx;
end
widget.Tag = 'Labels';

% Listeners to update data
L = addlistener(labelsContainer,{'Title','XLabel','YLabel'},'PostSet',...
    @(es,ed) localUpdateData(this,ed));
registerDataListeners(labelsContainer,L,'UpdateData');

% Update UI
props = [findprop(this,'Title'); findprop(this,'XLabel'); findprop(this,'YLabel')];
L = handle.listener(this,props,'PropertyPostSet',{@localUpdateUI labelsContainer});
registerUIListeners(labelsContainer,L,'UpdateUI');
end

%------------------ Local Functions ------------------------
function localUpdateData(this,ed)
disableUIListeners(ed.AffectedObject);
dataValue = this.(ed.Source.Name);
uiValue = ed.AffectedObject.(ed.Source.Name){1};
linebreaks = find(uiValue==newline);
newDataValue = cell(1,length(linebreaks)+1);
lastind = 1;
for ii = 1:length(linebreaks)
    newDataValue{ii} = uiValue(lastind:linebreaks(ii)-1);
    lastind = linebreaks(ii)+1;
end
newDataValue{end} = uiValue(lastind:end);
if iscell(dataValue)
    if length(dataValue) > length(newDataValue)
        extraEntries = cell(1,length(dataValue)-length(newDataValue));
        for ii = 1:length(extraEntries)
            extraEntries{ii} = '';
        end
        newDataValue = [newDataValue extraEntries]; %append missing lines
    else
        newDataValue = newDataValue(1:length(dataValue)); %Ignore extra lines
    end
else
    newDataValueCell = newDataValue;
    newDataValue = [];
    for ii = 1:length(newDataValueCell)
        newDataValue = [newDataValue newDataValueCell{ii} newline]; %#ok<AGROW>
    end
    newDataValue = newDataValue(1:end-1);
end
this.(ed.Source.Name) = newDataValue;
% If Title is changed, set TitleMode to manual. This prevents the trigger
% of auto title text in "margin" plot.
if strcmp(ed.Source.Name,'Title')
    this.TitleMode = 'manual';
end
enableUIListeners(ed.AffectedObject);
end

function localUpdateUI(es,ed,labelsContainer)
disableDataListeners(labelsContainer);
labelsContainer.(es.Name) = cellstr(ed.AffectedObject.(es.Name));
enableDataListeners(labelsContainer);
end