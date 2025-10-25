function addBrushingMenu(this)
%ADDMENU  Creates generic editor context menus.

%   Copyright 2015-2020 The MathWorks, Inc.

Anchor = getBrushingMenuAnchor(this.Axes);

%% Assign to group
if ~isempty(this.GroupingVariable)
    hAssign = uimenu(Anchor,'Label', ...
        getString(message('Controllib:plotmatrix:strAssignToGroup')));
    AtleastOneVariableExists = false;
    for ct = 1:numel(this.GroupingVariable)
        if iscategorical(this.Data.(this.GroupingVariable{ct})) && ~ismember(this.GroupingVariable{ct},this.TableColumnNames)
            hGV = uimenu(hAssign,'Label',...
                this.GroupingVariableLabels{ct});
            for ct1 = 1:numel(this.GroupLabels{ct})
                hG = uimenu(hGV,'Label',...
                    this.GroupLabels{ct}{ct1});
                set(hG,'Callback', {@localAssignToGroup this this.GroupingVariableLabels{ct}});
            end
            AtleastOneVariableExists = true;
        end
    end
    if ~AtleastOneVariableExists
        delete(hAssign);
    end
end
%% Manage groups
hManage = uimenu(Anchor,'Label', ...
    getString(message('Controllib:plotmatrix:strCreateNewGroup')));
set(hManage,'Callback', {@localManageGroups this});


%% Clear all brushing
hClear = uimenu(Anchor,'Label', ...
    getString(message('Controllib:plotmatrix:strClearAllBrushing')));
set(hClear,'Callback', {@localClearBrushing this});

%% Invert all brushing
hInvert = uimenu(Anchor,'Label', ...
    getString(message('Controllib:plotmatrix:strInvertSelection')));
set(hInvert,'Callback', {@localInvertBrushing this});

%% Disable brushing
hBrush = uimenu(Anchor, ...
    'Label', getString(message('Controllib:plotmatrix:strBrushing_Disable')), ...
    'Separator', 'on', ...
    'Tag', 'Brushing');
set(hBrush, 'CallBack', {@localBrushing this});
end

function localAssignToGroup(hSrc,~,Editor,GV)
idxGV = ismember(Editor.GroupingVariableLabels,GV);
idx = ismember(Editor.GroupLabels{idxGV},hSrc.Label);
NewGrp = Editor.GroupBins{idxGV}{idx};
Editor.Data.(GV)(Editor.BrushedIndex) = categorical(cellstr(repmat(NewGrp,size(Editor.Data.(GV)(Editor.BrushedIndex,:),1),1)));
Editor.updateScatterPlot;
Editor.updatePlot;
end

function localClearBrushing(hSrc,~,Editor)

%Clear the brushing for one axis and use brushcallback to update all the
%other axes.
ax = Editor.Axes.getAxes;
if Editor.XvsX
    ax = ax(1,2);
else
    ax = ax(1);
end
hl = findobj(ax,'Tag','groupLine');
for ct = 1:numel(hl)
    hl(ct).BrushData = [];
end
src = ancestor(hSrc,'figure');
evt.Axes = ax;

brushcallback(Editor,src,evt)
Editor.BrushedIndex = zeros(size(Editor.Data,1),1);
end

function localInvertBrushing(hSrc,~,Editor)

%Invert the brushing for one axis and use brushcallback to update all the
%other axes
ax = Editor.Axes.getAxes;
if Editor.XvsX
    ax = ax(1,2);
else
    ax = ax(1);
end
hl = findobj(ax,'Tag','groupLine');
for ct = 1:numel(hl)
    hl(ct).BrushData = double(~hl(ct).BrushData);
end
src = ancestor(hSrc,'figure');
evt.Axes = hl.Parent;

brushcallback(Editor,src,evt)
Editor.BrushedIndex = double(~Editor.BrushedIndex);
end

function localBrushing(~,~,this)

h = brush(ancestor(this,'figure'));
h.Enable = 'off';
end

function localManageGroups(hSrc,~,Editor)
categories = categorical({'BrushedData','UnbrushedData'});
CustomGroup = repmat(categories(2),size(Editor.Data,1),1);
CustomGroup(Editor.BrushedIndex) = repmat(categories(1),numel(find(Editor.BrushedIndex)),1);
ExistingCustomGroups = ~cellfun(@isempty, regexp(Editor.Data.Properties.VariableNames, 'CustomGroup'));
ExistingIndices = str2double(regexprep(Editor.Data.Properties.VariableNames(ExistingCustomGroups),'CustomGroup',''));
ExistingIndices(isnan(ExistingIndices)) = 0;
NewCustomGroupName = strcat('CustomGroup',num2str(max(ExistingIndices)+1));
Data = Editor.Data;
Data.(NewCustomGroupName) = CustomGroup;
Editor.Data = Data;
if isfield(Editor.Parent.UserData,'GroupEditor') && isvalid(Editor.Parent.UserData.GroupEditor)
    pullData(Editor.Parent.UserData.GroupEditor.getPeer);
else
    TC = controllib.ui.plotmatrix.internal.PlotMatrixUITC(Editor);
    Editor.Parent.UserData.GroupEditor = createView(TC);
end
try
    Editor.Parent.UserData.GroupEditor.getPeer.createGroupingVariable(NewCustomGroupName);
    Editor.Parent.UserData.GroupEditor.getPeer.pushData;
    Editor.Parent.UserData.GroupEditor.show;
    Editor.Parent.UserData.GroupEditor.getPeer.SelectedGroupingVariable = NewCustomGroupName;
    Editor.Parent.UserData.GroupEditor.updateUI;
catch ME
    errordlg(ME.message);
    Data.(NewCustomGroupName) = [];
end

end
