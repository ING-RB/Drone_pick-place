function limitsContainer = editLimits(this,XY,parent,rowIdx,columnIdx)
% Builds widget for editing axis limits.

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
            % Initialize
            subGridSize = this.Size(4);
            shareAll = strcmp(this.XlimSharing,'all');
            nSelect = (this.Size(2)>1 & ~shareAll & ~strcmp(this.XlimSharing,'peer') & ...
                ~any(strcmp(this.AxesGrouping,{'column','all'})));
            nLimitRows = subGridSize;
            limitsContainer = controllib.widget.internal.cstprefs.LimitsContainer(...
                'NumberOfGroups',1 + nSelect*length(unique(this.ColumnLabel)),...
                'NumberOfLimits',nLimitRows);
            limitsContainer.ContainerTitle = getString(message('Controllib:gui:strXLimits'));
            if nSelect
                rcLabels = this.ColumnLabel(1:subGridSize:end);
                limitsContainer.GroupItems = [{getString(message('Controllib:gui:strAll'))};...
                    rcLabels];
                limitsContainer.SelectedGroup = limitsContainer.GroupItems{1};
            end
            this.XLimitsContainer = limitsContainer;
        else
            limitsContainer = this.XLimitsContainer;
            nLimitRows = limitsContainer.NLimits;
            subGridSize = this.Size(4);
        end
        % Configure limit values
        allLimits = this.getxlim();
        for k = 1:nLimitRows
            limits = allLimits(k:subGridSize:end);
            if all(cellfun(@(x) isequal(x,limits{1}),limits))
                for g = 1:limitsContainer.NGroups
                    setLimits(limitsContainer,limits{1},g,k);
                end
            else
                setLimits(limitsContainer,[NaN,NaN],1,k);
                for g = 2:limitsContainer.NGroups
                    setLimits(limitsContainer,limits{g-1},g,k);
                end
            end
        end
        % Build widget
        widget = getWidget(limitsContainer);
        widget.Parent = parent;
        if isa(parent,'matlab.ui.container.GridLayout')
            widget.Layout.Row = rowIdx;
            widget.Layout.Column = columnIdx;
        end
        widget.Tag = 'XLimits';
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
            subGridSize = this.Size(3);
            shareAll = strcmp(this.YlimSharing,'all');
            nSelect = (this.Size(1)>1 & ~shareAll & ~strcmp(this.YlimSharing,'peer') & ...
                ~any(strcmp(this.AxesGrouping,{'row','all'})));
            nLimitRows = subGridSize;
            limitsContainer = controllib.widget.internal.cstprefs.LimitsContainer(...
                'NumberOfGroups',1 + nSelect*length(unique(this.RowLabel)),...
                'NumberOfLimits',nLimitRows);
            limitsContainer.ContainerTitle = getString(message('Controllib:gui:strYLimits'));
            if nSelect
                rcLabels = this.RowLabel(1:subGridSize:end);
                limitsContainer.GroupItems = [{getString(message('Controllib:gui:strAll'))};...
                    rcLabels];
                limitsContainer.SelectedGroup = limitsContainer.GroupItems{2};
            end
            this.YLimitsContainer = limitsContainer;
        else
            limitsContainer = this.YLimitsContainer;
            nLimitRows = limitsContainer.NLimits;
            subGridSize = this.Size(3);
        end
        % Configure limit values
        allLimits = this.getylim();
        for k = 1:nLimitRows
            limits = allLimits(k:subGridSize:end);
            if all(cellfun(@(x) isequal(x,limits{1}),limits))
                for g = 1:limitsContainer.NGroups
                    setLimits(limitsContainer,limits{1},g,k);
                end
            else
                setLimits(limitsContainer,[NaN,NaN],1,k);
                for g = 2:limitsContainer.NGroups
                    setLimits(limitsContainer,limits{g-1},g,k);
                end
            end
        end
        % Build widget
        widget = getWidget(limitsContainer);
        widget.Parent = parent;
        if isa(parent,'matlab.ui.container.GridLayout')
            widget.Layout.Row = rowIdx;
            widget.Layout.Column = columnIdx;
        end
        widget.Tag = 'YLimits';
        % Listeners to update data from UI
        L = addlistener(limitsContainer,{'AutoScale','SelectedGroup','Limits'},...
            'PostSet',@(es,ed) localUpdateDataY(this,es,ed));
        registerUIListeners(limitsContainer,L,'UpdateData');
        % Listeners to update UI from data
        props = findprop(this,'ylimMode');
        L = handle.listener(this,props,'PropertyPostSet',{@localUpdateUI limitsContainer 'Y' this});
        L2 = handle.listener(this,'PostLimitChanged',{@localUpdateUI limitsContainer 'Y' this});
        registerDataListeners(limitsContainer,[L; L2],'UpdateUI');
end

end


%------------------ Local Functions ------------------------
function localUpdateDataX(this,es,ed)
limitsContainer = ed.AffectedObject;
switch es.Name
    case 'AutoScale'
        if limitsContainer.AutoScale
            xLimMode = 'auto';
        else
            xLimMode = 'manual';
        end
        switch limitsContainer.SelectedGroupIdx
            case 1
                this.XLimMode(:) = {xLimMode};
            otherwise
                % Set xLimMode for specific group
                this.XLimMode{limitsContainer.SelectedGroupIdx-1} = xLimMode;
        end
    case 'Limits'
        limits = limitsContainer.Limits{1};
        % NaN limits indicate the different group limits are not equal and
        % common group is selected
        if ~any(isnan(limits))
            switch limitsContainer.SelectedGroupIdx
                case 1
                    % Common group selected and all limits are equal
                    this.setxlim(limits);
                otherwise
                    % Set for individual group
                    this.setxlim(limits,limitsContainer.SelectedGroupIdx-1);
            end
        end
    case 'SelectedGroup'
        limits = limitsContainer.Limits{1};
        if limitsContainer.SelectedGroupIdx == 1
            if ~any(isnan(limits))
                if limitsContainer.AutoScale
                    this.XLimMode = 'auto';
                else
                    this.XLimMode = 'manual';
                    this.setxlim(limits);
                end
            end
        end
end
end

function localUpdateDataY(this,es,ed)
limitsContainer = ed.AffectedObject;

nLimits = limitsContainer.NLimits;
nGroups = limitsContainer.NGroups;
groupIdx = limitsContainer.SelectedGroupIdx;
switch es.Name
    case 'AutoScale'
        value = limitsContainer.AutoScale;
        if value
            yLimMode = 'auto';
        else
            yLimMode = 'manual';
        end
        switch limitsContainer.SelectedGroupIdx
            case 1
                % If common group is selected, set yLimMode for all
                % groups
                this.YLimMode(:) = {yLimMode};
            otherwise
                % Set xLimMode for specific group
                this.YLimMode(nLimits*(groupIdx-2)+1:nLimits*(groupIdx-1)) = {yLimMode};
        end
    case 'Limits'
        limits = limitsContainer.Limits;
        switch groupIdx
            case 1
                % Common group selected
                for k = 1:nLimits
                    % NaN limits indicate the different group limits are not equal and
                    % common group is selected
                    if ~any(isnan(limits{k}))
                        for idx = k:nLimits:max([nLimits,(nGroups-1)*nLimits])
                            this.setylim(limits{k},idx);
                        end
                    end
                end
            otherwise
                % Set on individual groups
                for k = 1:nLimits
                    if ~any(isnan(limits{k}))
                        idx = (groupIdx-2)*nLimits + k;
                        this.setylim(limits{k},idx);
                    end
                end
        end
    case 'SelectedGroup'
        limits = limitsContainer.Limits;
        if groupIdx == 1
            isauto = true;
            for k = 1:nLimits
                if ~any(isnan(limits{k}))
                    isauto = false;
                    for idx = k:nLimits:max([nLimits,(nGroups-1)*nLimits])
                        this.setylim(limits{k},idx);
                    end
                end
            end
            if isauto
                this.YLimMode = 'auto';
            else
                this.YLimMode = 'manual';
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
        % If all limits are equal, set it in common group as well as
        % individual groups.
        for g = 1:limitsContainer.NGroups
            setLimits(limitsContainer,limits{1},g,k);
        end
    else
        % If all limits are not equal, then set common group limits to NaNs
        % and individual groups separately.
        if limitsContainer.AutoScale
            setLimits(limitsContainer,[NaN,NaN],1,k);
        end
        for g = 2:limitsContainer.NGroups
            setLimits(limitsContainer,limits{g-1},g,k);
        end
    end
end

for k = 1:max([1, limitsContainer.NGroups-1])
    % Check all limMode values for each individual group. Set AutoScale to
    % false if any value is manual.
    autoscaleValue = ~any(contains(limMode(nLimits*(k-1)+1:nLimits*k),'manual'));
    setAutoScale(limitsContainer,autoscaleValue,k+1);
end
if any(strcmp(limMode,'manual'))
    % Set autoscale for the common group to false if any of the limMode
    % values is manual
    setAutoScale(limitsContainer,false,1);
end
end