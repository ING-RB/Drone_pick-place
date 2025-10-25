function addMenu(this)
%ADDMENU  Creates generic editor context menus.

%   Copyright 2015-2020 The MathWorks, Inc.

Anchor = getMenuAnchor(this.Axes);
%% Variables
VarIdx = ~ismember(this.Data.Properties.VariableNames,...
        this.GroupingVariable) & varfun(@(x)isnumeric(x)||isdatetime(x),this.Data(:,:),'OutputFormat','uniform');
Variables = this.Data.Properties.VariableNames(VarIdx);
if this.XvsX
    hVar = uimenu(Anchor,'Label', ...
        getString(message('Controllib:plotmatrix:strVariables')),...
        'Tag','Variables');
    for ct = 1:numel(Variables)
        bool = ismember(Variables{ct},this.XVariable)||ismember(Variables{ct},this.YVariable);
        if bool
            chkd = 'on';
        else
            chkd = 'off';
        end
        hVarName = uimenu(hVar,'Label',...
            Variables{ct},...
            'Checked',chkd,...
            'Tag',['Variable',mat2str(ct)]);
        set(hVarName,'Callback',{@LocalShowVariable this 'XVariable'});
    end
else
    hVarX = uimenu(Anchor,'Label', ...
        getString(message('Controllib:plotmatrix:strXVariables')),...
        'Tag','XVariables');
    for ct = 1:numel(Variables)
        bool = ismember(Variables{ct},this.XVariable);
        if bool
            chkd = 'on';
        else
            chkd = 'off';
        end
        hVarName = uimenu(hVarX,'Label',...
            Variables{ct},...
            'Checked',chkd,...
            'Tag',['XVariable',mat2str(ct)]);
        set(hVarName,'Callback',{@LocalShowVariable this 'XVariable'});
    end
    hVarY = uimenu(Anchor,'Label', ...
        getString(message('Controllib:plotmatrix:strYVariables')),...
        'Tag','YVariables');
    for ct = 1:numel(Variables)
        bool = ismember(Variables{ct},this.YVariable);
        if bool
            chkd = 'on';
        else
            chkd = 'off';
        end
        hVarName = uimenu(hVarY,'Label',...
            Variables{ct},...
            'Checked',chkd,...
            'Tag',['YVariable',mat2str(ct)]);
        set(hVarName,'Callback',{@LocalShowVariable this 'YVariable'});
    end
end
%% Groups
hGrps = uimenu(Anchor, ...
    'Label', getString(message('Controllib:plotmatrix:strGroups')),...
    'Separator','on',...
    'Tag','Groups');

if ~isempty(this.GroupingVariable)
    for ct = 1:numel(this.GroupingVariable)
        if this.ShowGroupingVariable(ct)
            chkd = 'on';
        else
            chkd = 'off';
        end
        hGV = uimenu(hGrps,'Label',...
            this.GroupingVariableLabels{ct}, ...
            'Checked', chkd,...
            'Tag',['GroupingVariable',mat2str(ct)]);
        for ct1 = 1:numel(this.GroupLabels{ct})
            if this.ShowGroups{ct}(ct1)
                chkd = 'on';
            else
                chkd = 'off';
            end
            hG = uimenu(hGV,'Label',...
                this.GroupLabels{ct}{ct1}, ...
                'Checked', chkd,...
                  'Tag',['Variable',mat2str(ct),'Group',mat2str(ct1)]);
            set(hG,'Callback', {@localShowGroups this this.GroupingVariableLabels{ct}});
        end
    end
    hShowAll = uimenu(hGrps,'Label', ...
        getString(message('Controllib:plotmatrix:strShowAll')),...
        'Separator','on',...
        'Tag','ShowAll');
    set(hShowAll,'Callback', {@localShowAllGroups this});
end

hNewGV = uimenu(hGrps,'Label', ...
    getString(message('Controllib:plotmatrix:strNewGroupingVariable')),...
    'Separator','on',...
      'Tag','NewGroupingVariable');

for ct = 1:width(this.Data)
    % Add it to sub-menu if its not already a grouping variable
    if ~ismember(this.Data.Properties.VariableNames(ct),this.GroupingVariable)
        
        hPossibleGV = uimenu(hNewGV,'Label',...
            this.Data.Properties.VariableNames{ct},...
            'Tag',['NewGroupingVariable', mat2str(ct)]);
        set(hPossibleGV, 'Callback', {@localNewGroupingVariable this});
    end
end

hManageGrps = uimenu(hGrps,'Label', ...
    getString(message('Controllib:plotmatrix:strManageGroups')),...
      'Tag','ManageGroups');
set(hManageGrps,'Callback', {@localManageGroups this});

%% Upper triangular plots
if this.XvsX
    if this.ShowUpperTrianglePlots
        chkd = 'on';
    else
        chkd = 'off';
    end
    hXvsX = uimenu(Anchor,'Label', ...
        getString(message('Controllib:plotmatrix:strUpperTriangularPlots')), ...
        'Checked', chkd,...
        'Tag','ShowUpperTrianglePlots');
    set(hXvsX,'Callback',{@localUpperTriangle this});
end

%% Marginal box plots
try
    controllib.ui.plotmatrix.internal.View.checklicense;
    chkd = {'off','off','off','off'};
    switch this.BoxPlot
        case 'Top'
            chkd{1} = 'on';
        case 'Bottom'
            chkd{2} = 'on';
        case 'Left'
            chkd{3} = 'on';
        case 'Right'
            chkd{4} = 'on';
    end
    hMBP = uimenu(Anchor,'Label', ...
        getString(message('Controllib:plotmatrix:strMarginalBoxPlots')),...
        'Tag','BoxPlot');
    
    uimenu(hMBP,'Label',...
        getString(message('Controllib:plotmatrix:strTop')), ...
        'Callback', {@localPeripheralPlot this 'BoxPlot', 'Top'},...
        'Tag','BoxPlotTop');
    uimenu(hMBP,'Label',...
        getString(message('Controllib:plotmatrix:strBottom')), ...
        'Callback', {@localPeripheralPlot this 'BoxPlot', 'Bottom'},...
        'Tag','BoxPlotBottom');
    uimenu(hMBP,'Label',...
        getString(message('Controllib:plotmatrix:strLeft')), ...
        'Callback', {@localPeripheralPlot this 'BoxPlot', 'Left'},...
        'Tag','BoxPlotLeft');
    uimenu(hMBP,'Label',...
        getString(message('Controllib:plotmatrix:strRight')), ...
        'Callback', {@localPeripheralPlot this 'BoxPlot', 'Right'},...
        'Tag','BoxPlotRight');
    if this.XvsX
        uimenu(hMBP,'Label',...
            getString(message('Controllib:plotmatrix:strDiagonal')), ...
            'Callback', {@localPeripheralPlot this 'BoxPlot', 'Diagonal'},...
            'Tag','BoxPlotDiagonal');
    end
    uimenu(hMBP,'Label',...
        getString(message('Controllib:plotmatrix:strNone')), ...
        'Callback', {@localPeripheralPlot this 'BoxPlot', 'None'},...
        'Tag','BoxPlotNone');
catch
end

%% Histograms
chkd = {'off','off','off','off'};
switch this.Histogram
    case 'Top'
        chkd{1} = 'on';
    case 'Bottom'
        chkd{2} = 'on';
    case 'Left'
        chkd{3} = 'on';
    case 'Right'
        chkd{4} = 'on';
end
hHist = uimenu(Anchor,'Label', ...
    getString(message('Controllib:plotmatrix:strHistograms')),...
    'Tag','Histogram');

uimenu(hHist,'Label',...
    getString(message('Controllib:plotmatrix:strTop')), ...
    'Callback', {@localPeripheralPlot this 'Histogram', 'Top'},...
    'Tag','HistogramTop');
uimenu(hHist,'Label',...
    getString(message('Controllib:plotmatrix:strBottom')), ...
    'Callback', {@localPeripheralPlot this 'Histogram', 'Bottom'},...
    'Tag','HistogramBottom');
uimenu(hHist,'Label',...
    getString(message('Controllib:plotmatrix:strLeft')), ...
    'Callback', {@localPeripheralPlot this 'Histogram', 'Left'},...
    'Tag','HistogramLeft');
uimenu(hHist,'Label',...
    getString(message('Controllib:plotmatrix:strRight')), ...
    'Callback', {@localPeripheralPlot this 'Histogram', 'Right'},...
    'Tag','HistogramRight');

if this.XvsX
    uimenu(hHist,'Label',...
        getString(message('Controllib:plotmatrix:strDiagonal')), ...
        'Callback', {@localPeripheralPlot this 'Histogram', 'Diagonal'},...
        'Tag','HistogramDiagonal');
end
uimenu(hHist,'Label',...
    getString(message('Controllib:plotmatrix:strNone')), ...
    'Callback', {@localPeripheralPlot this 'Histogram', 'None'},...
    'Tag','HistogramNone');
%% Kernel density plots
try
    controllib.ui.plotmatrix.internal.View.checklicense;
    chkd = {'off','off','off','off'};
    switch this.KernelDensityPlot
        case 'Top'
            chkd{1} = 'on';
        case 'Bottom'
            chkd{2} = 'on';
        case 'Left'
            chkd{3} = 'on';
        case 'Right'
            chkd{4} = 'on';
    end
    hKBP = uimenu(Anchor,'Label', ...
        getString(message('Controllib:plotmatrix:strKernelDensityPlots')),...
        'Tag','KernelDensityPlot');
    
    uimenu(hKBP,'Label',...
        getString(message('Controllib:plotmatrix:strTop')), ...
        'Callback', {@localPeripheralPlot this 'KernelDensityPlot', 'Top'},...
        'Tag','KernelDensityPlotTop');
    uimenu(hKBP,'Label',...
        getString(message('Controllib:plotmatrix:strBottom')), ...
        'Callback', {@localPeripheralPlot this 'KernelDensityPlot', 'Bottom'},...
        'Tag','KernelDensityPlotBottom');
    uimenu(hKBP,'Label',...
        getString(message('Controllib:plotmatrix:strLeft')), ...
        'Callback', {@localPeripheralPlot this 'KernelDensityPlot', 'Left'},...
        'Tag','KernelDensityPlotLeft');
    uimenu(hKBP,'Label',...
        getString(message('Controllib:plotmatrix:strRight')), ...
        'Callback', {@localPeripheralPlot this 'KernelDensityPlot', 'Right'},...
        'Tag','KernelDensityPlotRight');
    if this.XvsX
        uimenu(hKBP,'Label',...
            getString(message('Controllib:plotmatrix:strDiagonal')), ...
            'Callback', {@localPeripheralPlot this 'KernelDensityPlot', 'Diagonal'},...
            'Tag','KernelDensityPlotDiagonal');
    end
    uimenu(hKBP,'Label',...
        getString(message('Controllib:plotmatrix:strNone')), ...
        'Callback', {@localPeripheralPlot this 'KernelDensityPlot', 'None'},...
        'Tag','KernelDensityPlotNone');
catch
end
%% Linear fit
hLF = uimenu(Anchor,'Label', ...
    getString(message('Controllib:plotmatrix:strOverlayLinearFit')), ...
    'Checked', 'off',...
    'Callback', {@localLinearFit this 'All'},...
    'Separator','on',...
    'Tag','LineatFit');

%% Brush menu
hBrush = uimenu(Anchor, ...
    'Label', getString(message('Controllib:plotmatrix:strBrushing_Enable')), ...
    'Separator', 'on', ...
    'Tag', 'Brushing');
set(hBrush, 'CallBack', {@localBrushing this});

%% Pop-out plot
hPopOut = uimenu(Anchor,'Label', ...
    getString(message('Controllib:plotmatrix:strPopOutPlot')), ...
    'Separator','on',...
     'Tag','PopOutPlot');
set(hPopOut, 'CallBack', {@localPopOutCallback this});

end

%----------------------------- Listener callbacks ----------------------------
function LocalShowVariable(hSrc,~,Editor,PropName)
[b,idx] = ismember(hSrc.Label,Editor.(PropName));
if b
    NewVariable = [Editor.(PropName)(1:idx-1),Editor.(PropName)(idx+1:end)];
    if isempty(NewVariable)
        % Do nothing if its the last variable
        return;
    else
        set(hSrc,'Checked','off');
        Editor.(PropName) = NewVariable;
    end
else
    set(hSrc,'Checked','off');
    [b,idx] = ismember([Editor.(PropName) {hSrc.Label}],Editor.ShowVariableOrder.(PropName));
    sidx = sort(idx(b));
    if all(b)
        % all variables exist in ShowVariableOrder
        Editor.(PropName) = Editor.ShowVariableOrder.(PropName)(sidx(sidx));
    else
        Editor.ShowVariableOrder.(PropName) = [Editor.ShowVariableOrder.(PropName)(sidx(sidx~=0)) {hSrc.Label}];
        Editor.(PropName) = [Editor.ShowVariableOrder.(PropName)(sidx(sidx~=0)) {hSrc.Label}];
    end
end
end

function localShowGroups(hSrc,~,Editor,GV)
idxGV = ismember(Editor.GroupingVariableLabels,GV);
idx = ismember(Editor.GroupLabels{idxGV},hSrc.Label);
if Editor.ShowGroups{idxGV}(idx)
    set(hSrc,'Checked','off');
    Editor.ShowGroups{idxGV}(idx) = false;
else
    set(hSrc,'Checked','on');
    Editor.ShowGroups{idxGV}(idx) = true;
end
end

function localShowAllGroups(hSrc,~,Editor)
for ct = 1:numel(Editor.GroupingVariableLabels)
    Editor.ShowGroups{ct}(:) = 1;
end
GVMenu = hSrc.Parent.Children;
for ct= numel(GVMenu):-1:4
    set(GVMenu(ct).Children,'Checked','on');
end
end

function localUpperTriangle(hSrc,~,Editor)
if Editor.ShowUpperTrianglePlots
    set(hSrc,'Checked','off');
    Editor.ShowUpperTrianglePlots = false;
else
    set(hSrc,'Checked','on');
    Editor.ShowUpperTrianglePlots = true;
end
end

function localManageGroups(hSrc,~,Editor)
if isfield(Editor.Parent.UserData,'GroupEditor') && isvalid(Editor.Parent.UserData.GroupEditor)
    Editor.Parent.UserData.GroupEditor.show;
    Editor.Parent.UserData.GroupEditor.updateUI;
else
    TC = controllib.ui.plotmatrix.internal.PlotMatrixUITC(Editor);
    Editor.Parent.UserData.GroupEditor = createView(TC);
    Editor.Parent.UserData.GroupEditor.show;
    Editor.Parent.UserData.GroupEditor.updateUI;
end
end

function localNewGroupingVariable(hSrc,~,Editor)
try
    StyleList = {'Color', 'MarkerSize', 'MarkerType'};
    if sum(ismember(StyleList,Editor.GroupingVariableStyle))==3
        error(getString(message('Controllib:plotmatrix:errTooManyGV')));
    end
    Editor.GroupingVariable = [Editor.GroupingVariable, {hSrc.Label}];
catch ME
    errordlg(ME.message);
end
end

function localPeripheralPlot(~,~,Editor,PlotType,Location)
Editor.(PlotType) = Location;
end

function localLinearFit(hSrc,~,Editor,Location)
% Fit the points and plot the line.
% How do you get the axes position that was clicked on??
% allmenus = get(hSrc.Parent,'Children');
% allmenus = allmenus(allmenus~=hSrc);
% src = hittest(ancestor(hSrc,'Figure'));
ag = Editor.Axes;
ax = ag.getAxes;
[nR,nC] = size(ax);

if strcmp(get(hSrc,'Checked'),'on')
    Editor.LinearFitIndex = false(nR,nC);
    hSrc.Checked = 'off';
else
    Editor.LinearFitIndex = true(nR,nC);
    if Editor.XvsX
        for i = 1:nR
            Editor.LinearFitIndex(i,i) = false;
        end
    end
    hSrc.Checked = 'on';
end
updateLinearFit(Editor);
end

function localPopOutCallback(src,~,this)
HitObject = hittest(ancestor(src,'Figure'));
if isa(HitObject.Parent, 'matlab.graphics.axis.Axes')
    % Clicked on the line to get the menu
    popOutAxes(this,HitObject.Parent);
elseif isa(HitObject, 'matlab.graphics.axis.Axes')
    popOutAxes(this,HitObject);
end
end

function localBrushing(~,~,this)

h = brush(ancestor(this,'figure'));
h.Enable = 'on';
end
