function limitsContainer = editLimits(this,XY,parent,rowIdx,columnIdx)
% Builds container for editing axis limits
% XY is the axis ('X' or 'Y')

% Copyright 1986-2021 The MathWorks, Inc.

arguments
    this
    XY
    parent
    rowIdx = 1
    columnIdx = 1
end

switch XY
    case 'X'
        if isempty(this.XLimitsContainer)
            limitsContainer = controllib.widget.internal.cstprefs.LimitsContainer;
            limitsContainer.ContainerTitle = getString(message('Controllib:gui:strXLimits'));
            this.XLimitsContainer = limitsContainer;
        else
            limitsContainer = this.XLimitsContainer;
        end
        allLimits = this.getxlim();
        setLimits(limitsContainer,allLimits{1},1,1);
        % Listeners to update data from UI
        L = addlistener(limitsContainer,{'AutoScale','SelectedGroup','Limits'},...
            'PostSet',@(es,ed) localUpdateDataX(this,es,ed));
        registerUIListeners(limitsContainer,L,'UpdateData');
        % Listeners to update UI from data
        props = findprop(this,'XlimMode');
        L = handle.listener(this,props,'PropertyPostSet',{@localUpdateUI limitsContainer 'X' this});
        L2 = handle.listener(this,'PostLimitChanged',{@localUpdateUI limitsContainer 'X' this});
        registerDataListeners(limitsContainer,[L; L2],'UpdateUI');
    case 'Y'
        if isempty(this.YLimitsContainer)
            limitsContainer = controllib.widget.internal.cstprefs.LimitsContainer;
            limitsContainer.ContainerTitle = getString(message('Controllib:gui:strYLimits'));
            this.YLimitsContainer = limitsContainer;
        else
            limitsContainer = this.XLimitsContainer;
        end
        allLimits = this.getylim();
        setLimits(limitsContainer,allLimits{1},1,1);
        % Listeners to update data from UI
        L = addlistener(limitsContainer,{'AutoScale','SelectedGroup','Limits'},...
            'PostSet',@(es,ed) localUpdateDataY(this,es,ed));
        registerUIListeners(limitsContainer,L,'UpdateData');
        % Listeners to update UI from data
        props = findprop(this,'YlimMode');
        L = handle.listener(this,props,'PropertyPostSet',{@localUpdateUI limitsContainer 'Y' this});
        L2 = handle.listener(this,'PostLimitChanged',{@localUpdateUI limitsContainer 'Y' this});
        registerDataListeners(limitsContainer,[L; L2],'UpdateUI');
end

widget = getWidget(limitsContainer);
widget.Parent = parent;
if isa(parent,'matlab.ui.container.GridLayout')
    widget.Layout.Row = rowIdx;
    widget.Layout.Column = columnIdx;
end
widget.Tag = 'XLimits';
end

%------------------ Local Functions ------------------------

function localUpdateDataX(this,es,ed)
limitsContainer = ed.AffectedObject;
switch es.Name
    case 'AutoScale'
        value = limitsContainer.AutoScale;
        if value
            xLimMode = 'auto';
        else
            xLimMode = 'manual';
        end
        if limitsContainer.NGroups == 1
            this.XLimMode = xLimMode;
        else
            switch limitsContainer.SelectedGroupIdx
                case 1
                    this.XLimMode(:) = {xLimMode};
                otherwise
                    this.XLimMode{limitsContainer.SelectedGroupIdx-1} = xLimMode;
            end
        end
        
    case 'GroupItems'
        
    case 'SelectedGroup'
        
    case 'Limits'
        limits = limitsContainer.Limits{1};
        if ~any(isnan(limits))
            switch limitsContainer.SelectedGroupIdx
                case 1
                    this.setxlim(limits);
                otherwise
                    this.setxlim(limits,limitsContainer.SelectedGroupIdx-1);
            end
        end
end
end

function localUpdateDataY(this,es,ed)
limitsContainer = ed.AffectedObject;
switch es.Name
    case 'AutoScale'
        value = limitsContainer.AutoScale;
        if value
            yLimMode = 'auto';
        else
            yLimMode = 'manual';
        end
        if limitsContainer.NGroups == 1
            this.YLimMode = yLimMode;
        else
            switch limitsContainer.SelectedGroupIdx
                case 1
                    this.YLimMode(:) = {yLimMode};
                otherwise
                    this.YLimMode{limitsContainer.SelectedGroupIdx-1} = yLimMode;
            end
        end
        
    case 'GroupItems'
        
    case 'SelectedGroup'
        
    case 'Limits'
        limits = limitsContainer.Limits{1};
        if ~any(isnan(limits))
            switch limitsContainer.SelectedGroupIdx
                case 1
                    this.setylim(limits);
                otherwise
                    this.setylim(limits,limitsContainer.SelectedGroupIdx-1);
            end
        end
end
end

function localUpdateUI(es,ed,limitsContainer,XY,axGrid)
% Configure limit values
if strcmpi(XY,'x')
    allLimits = axGrid.getxlim();
    limMode = axGrid.XlimMode;
else
    allLimits = axGrid.getylim();
    limMode = axGrid.YlimMode;
end
nLimits = limitsContainer.NLimits;
for k = 1:nLimits
    limits = allLimits(k:nLimits:end);
    if all(cellfun(@(x) isequal(x,limits{1}),limits))
        for g = 1:limitsContainer.NGroups
            setLimits(limitsContainer,limits{1},g,k);
        end
    else
        if limitsContainer.AutoScale
            setLimits(limitsContainer,[NaN,NaN],1,k);
        end
        for g = 2:limitsContainer.NGroups
            setLimits(limitsContainer,limits{g-1},g,k);
        end
    end
end

for k = 1:length(limMode)
    setAutoScale(limitsContainer,strcmp(limMode{k},'auto'),k+1);
end
if any(strcmp(limMode,'manual'))
    setAutoScale(limitsContainer,false,1);
end
end
