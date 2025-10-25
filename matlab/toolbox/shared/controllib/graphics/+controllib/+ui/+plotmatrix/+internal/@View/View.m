classdef View < matlab.mixin.SetGet
%

%   Copyright 2015-2022 The MathWorks, Inc.

    properties(Constant,Hidden)
        plotKWDs    = {'Diagonal','Top','Bottom','Left','Right','None'};
        gvStyleKWDs = {'Color','MarkerSize','MarkerType','XAxis','YAxis','LineStyle',''};
    end
    
    properties (Dependent = true, SetObservable = true, AbortSet = true)
        Data
        ShowUpperTrianglePlots
        GroupLabels
        GroupingVariableLabels
        ShowGroupingVariable
    end
    
    properties (Dependent)
        XVariable
        YVariable
        GroupingVariable
        GroupBins
        GroupingVariableStyle
        GroupColor
        GroupMarker
        GroupMarkerSize
        GroupLineStyle
        ShowGroups
        BoxPlot
        KernelDensityPlot
        Histogram
        Parent
        Position
    end
    
    properties(SetObservable = true, AbortSet = true)
        Legend
    end
    
    properties(Hidden)
        XvsX
        NumGroupingVariable
        ChangedGroupIdx
        Axes
        Listeners
    end
    
    properties(GetAccess = public, SetAccess = public, SetObservable = true)
        BrushedIndex
    end
    
    properties (Access = private)
        HistUsingDefault
        Model
        IsInitialized = false
        LinearFitIndex
        XVariabelIndex
        YVariabelIndex
        GroupingVariableIndex
        UsingDefaultGVLabel
        ShowView = true;
        ParentBeingDeletedListener
        ChangedGroupingVariableIndex
        % Used to store the order in which the user showed/hid variables
        % from the right click menu
        ShowVariableOrder
        
        % Used to distinguish columns that the table originally had from
        % the columns that were added due to brushing. (Columns added due
        % to brushing can be modified).
        TableColumnNames
        
        Data_I
        XVariable_I
        YVariable_I
        GroupingVariable_I
        ShowGroupingVariable_I
        GroupingVariableLabels_I
        GroupBins_I
        GroupLabels_I
        GroupingVariableStyle_I
        GroupColor_I
        GroupMarker_I
        GroupMarkerSize_I
        GroupLineStyle_I
        ShowGroups_I
        BoxPlot_I
        KernelDensityPlot_I
        Histogram_I
        ShowUpperTrianglePlots_I
        Parent_I
        Position_I
        Legend_I
    end
    
    methods
        function hObj = View(tbl,opts,histUsingDefault)
            set_Data(hObj,tbl);
            hObj.TableColumnNames = tbl.Properties.VariableNames;
            hObj.HistUsingDefault = histUsingDefault;
            hObj.XVariable = opts.XVariable;
            hObj.YVariable = opts.YVariable;
            hObj.GroupingVariable = opts.GroupingVariable;
            hObj.GroupBins = opts.GroupBins;
            set_GroupingVariableLabels(hObj,opts.GroupingVariableLabels);
            hObj.GroupingVariableStyle = opts.GroupingVariableStyle;
            set_GroupLabels(hObj,opts.GroupLabels);
            hObj.BoxPlot = opts.BoxPlot;
            hObj.KernelDensityPlot = opts.KernelDensityPlot;
            hObj.Histogram = opts.Histogram;
            hObj.GroupColor = opts.GroupColor;
            hObj.GroupMarker = opts.GroupMarker;
            hObj.GroupMarkerSize = opts.GroupMarkerSize;
            hObj.GroupLineStyle = opts.GroupLineStyle;
            set_ShowGroupingVariable(hObj,opts.ShowGroupingVariable);
            hObj.ShowGroups = opts.ShowGroups;
            set_ShowUpperTrianglePlots(hObj,opts.ShowUpperTrianglePlots);
            hObj.Legend = opts.Legend;
            hObj.Parent = opts.Parent;
            % Model from LineCreator
            hObj.Model = controllib.ui.plotmatrix.internal.LineCreator(hObj);
            hObj.GroupBins = hObj.Model.GroupBins;
            hObj.IsInitialized = true;
            hObj.BrushedIndex = false(size(hObj.Data,1),1);
            hObj.ShowVariableOrder.XVariable = hObj.XVariable;
            hObj.ShowVariableOrder.YVariable = hObj.YVariable;
            
            % listeners
            l13 = addlistener(hObj,'DataChanged',@(es,ed)dataChanged(hObj));
            l12 = addlistener(hObj,'XYChanged',@xyChangedCallback);
            l1 = addlistener(hObj,'GroupLabels','PostSet',@(~,evt)evt.AffectedObject.groupLabelChanged);
            l2 = addlistener(hObj,'ShowGroupingVariable','PostSet',@(~,evt)evt.AffectedObject.showGroupingVariableChanged);
            l3 = addlistener(hObj,'GroupStyleChanged',@groupstyleChangedCallback);
            l4 = addlistener(hObj,'GroupingVariableStyleChanged',@gvstyleChangedCallback);
            l5 = addlistener(hObj,'ShowGroupsChanged',@(src,~)src.showGroups);
            l6 = addlistener(hObj,'GroupBinsChanged',@groupbinsChangedCallback);
            l7 = addlistener(hObj,'PeripheralPlotChanged',@(src,~)src.updatePlot);
            l8 = addlistener(hObj,'GroupingVariableChanged',@gvChangedCallback);
            l9 = addlistener(hObj,'GroupingVariableLabels','PostSet',@(~,evt)evt.AffectedObject.createLegend);
            l10 = addlistener(hObj,'Legend','PostSet',@(~,evt)evt.AffectedObject.createLegend);
            l11 = addlistener(hObj,'ShowUpperTrianglePlots','PostSet',@(~,evt)evt.AffectedObject.showUpperTrianglePlots);
            hObj.Listeners = {l1,l2,l3,l4,l5,l6,l7,l8,l9,l10,l11,l12,l13};
        end
        
        function DataCopy = copyData(this)
            [opts,histUsingDefault] = controllib.ui.plotmatrix.internal.View.parseInput('XVariable',this.XVariable,'YVariable',this.YVariable);
            DataCopy = controllib.ui.plotmatrix.internal.View(this.Data,opts,histUsingDefault);
            lenListeners = length(DataCopy.Listeners);
            for i = 1:lenListeners-1
                DataCopy.Listeners{i}.Enabled = false;
            end
            DataCopy.ShowView = false;
            DataCopy.IsInitialized = false;
            DataCopy.GroupingVariable = this.GroupingVariable;
            if ~isempty(this.GroupingVariable)
                DataCopy.GroupBins_I = this.GroupBins;
            end
            DataCopy.GroupingVariableLabels_I = this.GroupingVariableLabels;
            DataCopy.GroupingVariableStyle_I = this.GroupingVariableStyle;
            DataCopy.GroupLabels_I = this.GroupLabels;
            DataCopy.BoxPlot = this.BoxPlot;
            DataCopy.KernelDensityPlot = this.KernelDensityPlot;
            DataCopy.Histogram = this.Histogram;
            DataCopy.GroupColor_I = this.GroupColor;
            DataCopy.GroupMarker_I = this.GroupMarker;
            DataCopy.GroupMarkerSize_I = this.GroupMarkerSize;
            DataCopy.GroupLineStyle_I = this.GroupLineStyle;
            DataCopy.ShowGroupingVariable_I = this.ShowGroupingVariable;
            DataCopy.ShowGroups_I = this.ShowGroups;
            %set_ShowUpperTrianglePlots(DataCopy,this.ShowUpperTrianglePlots);
            DataCopy.Legend = this.Legend;
            DataCopy.Parent = this.Parent;
            DataCopy.XvsX = this.XvsX;
            DataCopy.IsInitialized = true;
            DataCopy.BrushedIndex = false(size(DataCopy.Data,1),1);
            lenListeners = length(DataCopy.Listeners);
            DataCopy.Model = controllib.ui.plotmatrix.internal.LineCreator(DataCopy);
            DataCopy.GroupBins = DataCopy.Model.GroupBins;
            
            for i = 1:lenListeners-1
                DataCopy.Listeners{i}.Enabled = true;
            end
        end
        function setData(this, NewData)
            this.ShowView = false;
            props = fieldnames(NewData);
            [b,idx] = ismember('Data',props);
            if b
                this.Data = NewData.Data;
                props(idx) = [];
            end
            
            [b,idx] = ismember('GroupingVariable',props);
            if b
                this.GroupingVariable = NewData.GroupingVariable;
                props(idx) = [];
            end
            
            [b,idx] = ismember('GroupingVariableStyle',props);
            if b
                this.GroupingVariableStyle = NewData.GroupingVariableStyle;
                props(idx) = [];
            end
            [b,idx] = ismember('GroupBins',props);
            
            if b
                this.GroupBins = NewData.GroupBins;
                props(idx) = [];
            end
            
            for k = 1:length(props)
                p = props{k};
                this.(p) = NewData.(p);
            end
            this.ShowView = true;
            RecreateProps = {'GroupingVariable', 'GroupBins', ...
                'GroupingVariableStyle','ShowGroupingVariable','ShowGroups'};
            
            UpdateProps = {'GroupLabels', 'GroupColor', 'GroupMarker',...
                'GroupMarkerSize','GroupLineStyle'};
            props = fieldnames(NewData);
            if b || any(ismember(RecreateProps, props))
                this.createPlot;
                this.updateScatterPlot;
                this.updatePlot;
            elseif any(ismember(UpdateProps, props))
                this.updateScatterPlot;
                this.updatePlot;
            end
        end
        function data = get.Data(hObj)
            data = hObj.Data_I;
        end
        function set.Data(hObj, data)
            set_Data(hObj, data)
        end
        function set_Data(hObj, data)
            if ~isa(data,'table') || all(size(data)==[0 0])
                error(message('Controllib:plotmatrix:WrongTableData'));
            end
            % vectorize each column of the table
            if ~all(varfun(@(x)ischar(x)||isvector(x),data,'OutputFormat','uniform'))
                error(message('Controllib:plotmatrix:WrongTableVariable'));
            end
            if ~any(varfun(@(x)ischar(x),data,'OutputFormat','uniform'))
                vnames = data.Properties.VariableNames;
                try
                    data = varfun(@(x)x(:),data);
                catch
                    error(message('Controllib:plotmatrix:WrongTableVariable'));
                end
                data.Properties.VariableNames = vnames;
            end
            notify = false;
            if hObj.IsInitialized
                if ~all(ismember(hObj.XVariable,hObj.Data.Properties.VariableNames)) ||...
                        ~all(ismember(hObj.YVariable,hObj.Data.Properties.VariableNames)) ||...
                        ~all(ismember(hObj.GroupingVariable,hObj.Data.Properties.VariableNames))
                    error(message('Controllib:plotmatrix:UnrecognizedTableVariableName'));
                end
                changedGVIdx = ~arrayfun(@(x)all(isequal(data{:,x},hObj.Data_I{:,x})),hObj.GroupingVariableIndex);
                if any(changedGVIdx)
                    hObj.ChangedGroupingVariableIndex = hObj.GroupingVariableIndex(changedGVIdx);
                    notify = true;
                end
            end
            hObj.Data_I = data;
            hObj.BrushedIndex = false(size(data,1),1);
            if notify
                hObj.notify('DataChanged');
            end
        end
        
        function xvar = get.XVariable(hObj)
            xvar = hObj.Data.Properties.VariableNames(hObj.XVariabelIndex);
        end
        function set.XVariable(hObj, xvar)
            try
                checkVariableNames(hObj.Data.Properties.VariableNames,xvar);
            catch e
                throw(e)
            end
            if ~isempty(xvar) && ~all(varfun(@(x)isnumeric(x)||isdatetime(x),hObj.Data(:,xvar),'OutputFormat','uniform'))
                error(message('Controllib:plotmatrix:InvalidData'));
            end
            oldValue = hObj.XVariable;
            if isnumeric(xvar)
                hObj.XVariabelIndex = xvar;
            else
                xvar = noncell2cell(xvar);
                [~,hObj.XVariabelIndex] = ...
                    ismember(xvar, hObj.Data.Properties.VariableNames);
            end
            if ~isequal(hObj.XVariable,oldValue)
                hObj.notify('XYChanged');
            end
        end
        
        function yvar = get.YVariable(hObj)
            yvar = hObj.Data.Properties.VariableNames(hObj.YVariabelIndex);
        end
        function set.YVariable(hObj, yvar)
            try
                checkVariableNames(hObj.Data.Properties.VariableNames,yvar);
            catch e
                throw(e)
            end
            if ~isempty(yvar) && ~all(varfun(@(x)isnumeric(x)||isdatetime(x),hObj.Data(:,yvar),'OutputFormat','uniform'))
                error(message('Controllib:plotmatrix:InvalidData'));
            end
            oldValue = hObj.YVariable;
            if isnumeric(yvar)
                hObj.YVariabelIndex = yvar;
            else
                yvar = noncell2cell(yvar);
                [~,hObj.YVariabelIndex] = ...
                    ismember(yvar, hObj.Data.Properties.VariableNames);
            end
            if ~isequal(hObj.YVariable,oldValue)
                hObj.notify('XYChanged');
            end
        end
        
        function gvar = get.GroupingVariable(hObj)
            gvar = hObj.Data.Properties.VariableNames(hObj.GroupingVariableIndex);
        end
        function set.GroupingVariable(hObj, gvar)
            try
                checkVariableNames(hObj.Data.Properties.VariableNames,gvar);
            catch e
                throw(e)
            end
            eventData = controllib.ui.plotmatrix.internal.GroupEventData('GroupingVariable',hObj.GroupingVariable);
            if isnumeric(gvar)
                hObj.GroupingVariableIndex = gvar;
            else
                gvar = noncell2cell(gvar);
                [~,hObj.GroupingVariableIndex] = ...
                    ismember(gvar, hObj.Data.Properties.VariableNames);
            end
            if ~isempty(gvar)
                idx_missing = any(ismissing(hObj.Data(:,gvar)),2);
                % isnat g1110641
                idx_t = varfun(@isdatetime,hObj.Data(:,gvar),'OutputFormat','uniform');
                if any(idx_t)
                    idx_nat = rowfun(@(x)any(isnat(x)), hObj.Data(:,gvar(idx_t)),'outputformat','uniform','SeparateInputs',false);
                else
                    idx_nat = 0;
                end
                idx = idx_missing|idx_nat;
                hObj.Listeners{13}.Enabled = false;
                hObj.Data(idx,:) = [];
                hObj.Listeners{13}.Enabled = true;
                if isempty(hObj.Data)
                    error(message('Controllib:plotmatrix:InvalidGroupingVariable'));
                end
            end
            hObj.NumGroupingVariable = computeSize(gvar);
            hObj.ChangedGroupIdx = ones(hObj.NumGroupingVariable,1);
            hObj.notify('GroupingVariableChanged',eventData);
        end
        
        function gbins = get.GroupBins(hObj)
            gbins = hObj.GroupBins_I;
        end
        function set.GroupBins(hObj, gbins)
            try
                hObj.checkSize(gbins,'GroupBins');
            catch e
                throw(e)
            end
            gbins = noncell2cell(gbins);
            if isempty(gbins)
                gbins = cell(1,hObj.NumGroupingVariable);
            end
            eventData = controllib.ui.plotmatrix.internal.GroupEventData('GroupBins',hObj.GroupBins);
            hObj.GroupBins_I = gbins;
            if hObj.IsInitialized
                try
                    hObj.Model.updateGroup;
                catch e
                    hObj.GroupBins_I = eventData.OldValue;
                    throw(e)
                end
            end
            hObj.notify('GroupBinsChanged',eventData);
        end
        
        function gvlabels = get.GroupingVariableLabels(hObj)
            gvlabels = hObj.GroupingVariableLabels_I;
        end
        function set.GroupingVariableLabels(hObj, gvlabels)
            set_GroupingVariableLabels(hObj, gvlabels);
        end
        function set_GroupingVariableLabels(hObj, gvlabels)
            try
                hObj.checkSize(gvlabels, 'GroupingVariableLabels');
            catch e
                throw(e)
            end
            if isempty(gvlabels)
                hObj.GroupingVariableLabels_I = hObj.GroupingVariable;
                hObj.UsingDefaultGVLabel = true;
            else
                hObj.GroupingVariableLabels_I = gvlabels;
                hObj.UsingDefaultGVLabel = false;
            end
        end
        
        function gvstyle = get.GroupingVariableStyle(hObj)
            gvstyle = hObj.GroupingVariableStyle_I;
        end
        function set.GroupingVariableStyle(hObj, gvstyle)
            if ~ischar(gvstyle)&& ~iscell(gvstyle)&& ~isempty(gvstyle)
                error(message('Controllib:plotmatrix:InvalidGroupingVariableStyle'));
            end
            if ischar(gvstyle)
                gvstyle = validatestring(gvstyle,hObj.gvStyleKWDs);
            elseif iscell(gvstyle) && ~all(cellfun(@isempty,gvstyle))
                gvstyle = cellfun(@(x)validatestring(x,hObj.gvStyleKWDs),gvstyle,'UniformOutput', false);
            elseif ~isempty(gvstyle) && ~all(cellfun(@isempty,gvstyle))
                error(message('Controllib:plotmatrix:InvalidGroupingVariableStyle'));
            end
            try
                hObj.checkSize(gvstyle,'GroupingVariableStyle');
            catch e
                throw(e)
            end
            gvstyle = noncell2cell(gvstyle);
            sz = computeSize(gvstyle);
            idx_empty = cellfun(@isempty,gvstyle); %{'Color','','Marker'}
            sz_gvstyle = size(unique(gvstyle(idx_empty==0)),2)+sum(idx_empty);
            if sz>1 && (sz_gvstyle~=sz)
                error(message('Controllib:plotmatrix:SameGroupingVariableStyle'));
            end
            if hObj.IsInitialized && any(size(gvstyle)~=size(hObj.GroupingVariableStyle))
                error(message('Controllib:plotmatrix:WrongNumElement','GroupingVariableStyle'));
            end
            gvstyle = gvstyle(:)';
            eventData = controllib.ui.plotmatrix.internal.GroupEventData('GroupingVariableStyle',hObj.GroupingVariableStyle);
            hObj.GroupingVariableStyle_I = gvstyle;
            hObj.notify('GroupingVariableStyleChanged',eventData);
        end
        
        function glabels = get.GroupLabels(hObj)
            glabels = hObj.GroupLabels_I;
        end
        function set.GroupLabels(hObj, glabels)
            set_GroupLabels(hObj, glabels);
            if hObj.IsInitialized
                hObj.createLegend;
            end
        end
        function set_GroupLabels(hObj, glabels)
            try
                hObj.checkSize(glabels,'GroupLabels');
            catch e
                throw(e)
            end
            glabels = noncell2cell(glabels);
            if isempty(glabels)
                glabels = cell(1,hObj.NumGroupingVariable);
            end
            if ~all(cellfun(@(x)iscell(x)||isempty(x)||ischar(x),glabels))
                error(message('Controllib:plotmatrix:InvalidGroupLabels'));
            end
            if all(cellfun(@iscell,glabels))
                for i = 1:hObj.NumGroupingVariable
                    if ~isempty(glabels{i}) && ~all(cellfun(@ischar,glabels{i}))
                        error(message('Controllib:plotmatrix:InvalidGroupLabels'));
                    end
                end
            end
            if hObj.IsInitialized
                %{1980}->{{1980}}, {1980,{97,96}}->{{1980},{97,96}}
                loc = ~cellfun(@iscell,glabels);
                glabels(loc) = {glabels(loc)};
                try
                    hObj.compareCell(glabels,'GroupLabels');
                catch e
                    throw(e);
                end
                
            end
            
            hObj.GroupLabels_I = glabels;
        end
        
        function gcolor = get.GroupColor(hObj)
            gcolor = hObj.GroupColor_I;
        end
        function set.GroupColor(hObj, gcolor)
            if ~isempty(gcolor)
                gcolor = statslib.internal.colorStringToRGB(gcolor);
            end
            eventData = controllib.ui.plotmatrix.internal.GroupEventData('GroupColor',hObj.GroupColor);
            if hObj.IsInitialized && any(size(gcolor)~=size(hObj.GroupColor))
                error(message('Controllib:plotmatrix:WrongNumElement','GroupColor'));
            end
            hObj.GroupColor_I = gcolor;
            hObj.notify('GroupStyleChanged',eventData);
        end
        
        function gmarker = get.GroupMarker(hObj)
            gmarker = hObj.GroupMarker_I;
        end
        function set.GroupMarker(hObj, gmarker)
            if ~isempty(gmarker)&&~(iscellstr(gmarker)||ischar(gmarker))
                error(message('Controllib:plotmatrix:InvalidGroupMarker'));
            end
            if ~isempty(gmarker)
                gmarker = statslib.internal.getParamVal(gmarker,{'+','o','*','.','x','square',...
                    'diamond','v','^','>','<','pentagram','hexagram'},'GroupMarker',true);
            end
            gmarker = noncell2cell(gmarker);
            eventData = controllib.ui.plotmatrix.internal.GroupEventData('GroupMarker',hObj.GroupMarker);
            if hObj.IsInitialized && any(size(gmarker)~=size(hObj.GroupMarker))
                error(message('Controllib:plotmatrix:WrongNumElement','GroupMarker'));
            end
            hObj.GroupMarker_I = gmarker;
            hObj.notify('GroupStyleChanged',eventData);
        end
        
        function gmarkersize = get.GroupMarkerSize(hObj)
            gmarkersize = hObj.GroupMarkerSize_I;
        end
        function set.GroupMarkerSize(hObj, gmarkersize)
            if ~isempty(gmarkersize)&& ~(isnumeric(gmarkersize)&& all(gmarkersize>0))
                error(message('Controllib:plotmatrix:InvalidGroupMarkerSize'));
            end
            eventData = controllib.ui.plotmatrix.internal.GroupEventData('GroupMarkerSize',hObj.GroupMarkerSize);
            gmarkersize = gmarkersize(:)';
            if hObj.IsInitialized && any(size(gmarkersize)~=size(hObj.GroupMarkerSize))
                error(message('Controllib:plotmatrix:WrongNumElement','GroupMarkerSize'));
            end
            hObj.GroupMarkerSize_I = gmarkersize;
            hObj.notify('GroupStyleChanged',eventData);
        end
        
        function glinestyle = get.GroupLineStyle(hObj)
            glinestyle = hObj.GroupLineStyle_I;
        end
        function set.GroupLineStyle(hObj, glinestyle)
            if ~isempty(glinestyle)&&~(iscellstr(glinestyle)||ischar(glinestyle))
                error(message('Controllib:plotmatrix:InvalidGroupLineStyle'));
            end
            glinestyle = noncell2cell(glinestyle);
            if ~isempty(glinestyle)
                glinestyle = statslib.internal.getParamVal(glinestyle,{'-','--',':','-.','none'},...
                    'LineStyle',true);
            end
            glinestyle = glinestyle(:)';
            eventData = controllib.ui.plotmatrix.internal.GroupEventData('GroupLineStyle',hObj.GroupLineStyle);
            if hObj.IsInitialized && any(size(glinestyle)~=size(hObj.GroupLineStyle))
                error(message('Controllib:plotmatrix:WrongNumElement','GroupLineStyle'));
            end
            hObj.GroupLineStyle_I = glinestyle;
            hObj.notify('GroupStyleChanged',eventData);
        end
        
        function showgv = get.ShowGroupingVariable(hObj)
            showgv = hObj.ShowGroupingVariable_I;
        end
        function set.ShowGroupingVariable(hObj, showgv)
            set_ShowGroupingVariable(hObj, showgv);
        end
        function set_ShowGroupingVariable(hObj, showgv)
            showgv = showgv(:)'; %row vector
            if ~isempty(showgv) && (~isvector(showgv) ||....
                    ~all(showgv==0|showgv==1))
                error(message('Controllib:plotmatrix:InvalidShowGroupingVariable'));
            end
            try
                hObj.checkSize(showgv,'ShowGroupingVariable');
            catch e
                throw(e)
            end
            if isempty(showgv)
                hObj.ShowGroupingVariable_I = true(1,hObj.NumGroupingVariable);
            else
                hObj.ShowGroupingVariable_I = showgv;
            end
        end
        
        function showgrps = get.ShowGroups(hObj)
            showgrps = hObj.ShowGroups_I;
        end
        function set.ShowGroups(hObj, showgrps)
            try
                hObj.checkSize(showgrps,'ShowGroups');
            catch e
                throw(e)
            end
            if ~isempty(showgrps)&&~(iscell(showgrps)||isnumeric(showgrps)) %accept vector for one grouping variable?
                error(message('Controllib:plotmatrix:InvalidShowGroups'));
            end
            showgrps = noncell2cell(showgrps);
            if isempty(showgrps)
                showgrps = cell(1,hObj.NumGroupingVariable);
            end
            if ~all(cellfun(@(x)all((x==1)|(x==0)),showgrps))
                error(message('Controllib:plotmatrix:InvalidShowGroupsElement'));
            end
            eventData = controllib.ui.plotmatrix.internal.GroupEventData('ShowGroups',hObj.ShowGroups);
            if hObj.IsInitialized
                try
                    hObj.compareCell(showgrps,'ShowGroups');
                catch e
                    throw(e);
                end
            end
            hObj.ShowGroups_I = showgrps;
            hObj.notify('ShowGroupsChanged',eventData);
        end
        
        function boxPlot = get.BoxPlot(hObj)
            boxPlot = hObj.BoxPlot_I;
        end
        function set.BoxPlot(hObj, boxPlot)
            if ~strcmpi(boxPlot,'None')
                controllib.ui.plotmatrix.internal.View.checklicense;
            end
            boxPlot = validatestring(boxPlot,hObj.plotKWDs);
            try
                hObj.checkPosition(boxPlot,'BoxPlot');
            catch e
                throw(e)
            end
            if hObj.IsInitialized
                hObj.Listeners{7}.Enabled = 0;
                if ~strcmpi(boxPlot,'None')
                    if strcmpi(boxPlot,hObj.Histogram)
                        hObj.Histogram = 'None';
                    elseif  strcmpi(boxPlot,hObj.KernelDensityPlot)
                        hObj.KernelDensityPlot = 'None';
                    end
                end
                hObj.Listeners{7}.Enabled = 1;
                hObj.resetPeripheraPlot('boxplot','BoxPlot');
            end
            hObj.BoxPlot_I = boxPlot;
            hObj.notify('PeripheralPlotChanged');
        end
        
        function hist = get.Histogram(hObj)
            hist = hObj.Histogram_I;
        end
        function set.Histogram(hObj, hist)
            hist = validatestring(hist,hObj.plotKWDs);
            try
                hObj.checkPosition(hist,'Histogram');
            catch e
                throw(e)
            end
            if hObj.IsInitialized
                if ~strcmpi(hist,'None')
                    hObj.Listeners{7}.Enabled = 0;
                    if strcmpi(hist,hObj.BoxPlot)
                        hObj.BoxPlot = 'None';
                    elseif  strcmpi(hist,hObj.KernelDensityPlot)
                        hObj.KernelDensityPlot = 'None';
                    end
                    hObj.Listeners{7}.Enabled = 1;
                end
                hObj.resetPeripheraPlot('histogram','Histogram');
            end
            hObj.Histogram_I = hist;
            hObj.notify('PeripheralPlotChanged');
        end
        
        function ksplot = get.KernelDensityPlot(hObj)
            ksplot = hObj.KernelDensityPlot_I;
        end
        function set.KernelDensityPlot(hObj, ksplot)
            if ~strcmpi(ksplot,'None')
                controllib.ui.plotmatrix.internal.View.checklicense;
            end
            ksplot = validatestring(ksplot,hObj.plotKWDs);
            try
                hObj.checkPosition(ksplot,'KernelDensityPlot');
            catch e
                throw(e)
            end
            if hObj.IsInitialized
                if ~strcmpi(ksplot,'None')
                    hObj.Listeners{7}.Enabled = 0;
                    if strcmpi(ksplot,hObj.BoxPlot)
                        hObj.BoxPlot = 'None';
                    elseif  strcmpi(ksplot,hObj.Histogram)
                        hObj.Histogram = 'None';
                    end
                    hObj.Listeners{7}.Enabled = 1;
                end
                hObj.resetPeripheraPlot('groupedksplot','KernelDensityPlot');
            end
            hObj.KernelDensityPlot_I = ksplot;
            hObj.notify('PeripheralPlotChanged');
        end
        
        function showUpper = get.ShowUpperTrianglePlots(hObj)
            showUpper = hObj.ShowUpperTrianglePlots_I;
        end
        function set.ShowUpperTrianglePlots(hObj, showUpper)
            set_ShowUpperTrianglePlots(hObj, showUpper);
        end
        function set_ShowUpperTrianglePlots(hObj, showUpper)
            if any(showUpper~=1) && any(showUpper~=0)
                error(message('Controllib:plotmatrix:InvalidShowUpperTrianglePlots'));
            end
            if (showUpper==0) && ~((hObj.IsInitialized && hObj.XvsX) ||...
                    isempty(hObj.XVariable) || isempty(hObj.YVariable))
                error(message('Controllib:plotmatrix:XvsYShowUpperTrianglePlots'));
            end
            hObj.ShowUpperTrianglePlots_I = showUpper;
        end
        
        function set.Legend(hObj, legend)
            legend = statslib.internal.parseOnOff(legend,'''Legend''');
            hObj.Legend = legend;
        end
        
        function parent = get.Parent(hObj)
            parent = hObj.Parent_I;
        end
        function set.Parent(hObj, parent)
            if ~isempty(parent)&&...
                    ~isa(parent,'matlab.ui.Figure')&&~isa(parent,'matlab.ui.container.Panel')
                error(message('Controllib:plotmatrix:Parent'));
            end
            if hObj.IsInitialized && ~isempty(hObj.Parent)
                hObj.Axes.Parent = parent;
                hObj.Parent_I = parent;
            else
                hObj.Parent_I = parent;
            end
            
            
            if ~isempty(hObj.ParentBeingDeletedListener)
                delete(hObj.ParentBeingDeletedListener);
                hObj.ParentBeingDeletedListener = [];
            end
            
            if ~isempty(parent)
                hObj.ParentBeingDeletedListener = addlistener(parent, 'ObjectBeingDestroyed', @(es,ed)delete(hObj));
            end
            
        end
        
        function position = get.Position(hObj)
            position = hObj.Position_I;
        end
        function set.Position(hObj, position)
            if ~isempty(position) && (any(size(position)~=[1 4])||~isa(position,'double'))
                error(message('Controllib:plotmatrix:PositionProperty'))
            end
            if hObj.IsInitialized && ~isempty(hObj.Position)
                hObj.Axes.Position = position;
                hObj.Position_I = position;
            else
                hObj.Position_I = position;
            end
        end
    end
    
    methods(Access = 'public', Hidden = true)
        
        function setBrushedIndex(hObj,idx)
            %
            
            %SETBRUSHEDINDEX Set BrushedIndex values
            %
            %    setBrushedIndex(obj,index)
            %
            %    Set the brushed state of data rows.
            %
            %    Inputs:
            %      index - a logical array with the same number of rows as
            %              the data, where true indicate the data row is
            %              brushed and false that the data row is not
            %              brushed
            %
            
            if hObj.Model.Trellis
                %No brushing in trellis mode
                return;
            end
            
            %Convert to logical data type and to column
            if ~islogical(idx)
                idx = logical(idx);
            end
            idx = idx(:);
            
            if isequal(hObj.BrushedIndex,idx)
                %Nothing to do
                return
            end
            
            %Use single axis to determine brushing for all axes.
            %First get all x & y data for axis.
            x = hObj.Model.X(:,hObj.Model.AxesLocation(1,2));
            y = hObj.Model.Y(:,hObj.Model.AxesLocation(1,1));
            if (size(x,1) ~= numel(idx))
                error(message('Controllib:plotmatrix:BrushedIndex'));
            end
            
            %Grouped x & y data
            xdata = hObj.Model.XData(1:hObj.Model.NumGroup);
            ydata = hObj.Model.YData(1:hObj.Model.NumGroup);
            
            nG = hObj.Model.NumGroup;
            brushdata = cell(1,nG);
            for i = 1:nG
                points = [x(idx), y(idx)]; %Selected points
                idx_i = ismember([xdata{i},ydata{i}],points,'rows');
                brushdata{i} = uint8(idx_i)'; %brush data needs to be uint8 row
            end
            
            %For each data axis set the group lines brush data property
            ax = hObj.Axes.getAxes;
            sz = size(ax);
            for ctR=1:sz(1)
                for ctC=1:sz(2)
                    if ctR~=ctC || ~hObj.XvsX
                        l = findobj(ax(ctR,ctC),'Tag','groupLine');
                        for ctL = 1:numel(l)
                            l(ctL).BrushData = brushdata{i};
                        end
                    end
                end
            end
            
            %Set the BrushedIndex property (fires event)
            hObj.BrushedIndex = idx;
        end
    end
    
    methods(Static, Access='public')
        function hObj = plotmatrix(tbl,varargin)
            [opts,histUsingDefault] = controllib.ui.plotmatrix.internal.View.parseInput(varargin{:});
            hObj = controllib.ui.plotmatrix.internal.View(tbl,opts,histUsingDefault);
            hObj.createPlot;
            if ~any(hObj.Model.WrongBinFlag)
                hObj.updateScatterPlot;
                hObj.updatePlot;
            end
        end
        
        function checklicense
            if ( isempty(ver('stats')) || license('test','Statistics_Toolbox') == false )
                error(message('Controllib:plotmatrix:LicenseCheck_stats'));
            end
        end
    end
    
    methods(Static, Access='protected')
        function [opts,histUsingDefault]  = parseInput(varargin)
            p = inputParser;
            p.addParameter('XVariable',{});
            p.addParameter('YVariable',{});
            p.addParameter('GroupingVariable',{});
            p.addParameter('GroupBins',{});
            p.addParameter('BoxPlot','None');
            p.addParameter('KernelDensityPlot','None');
            p.addParameter('Histogram','None');
            p.addParameter('GroupingVariableLabels',{});
            p.addParameter('GroupingVariableStyle',{});
            p.addParameter('GroupLabels',{});
            p.addParameter('GroupColor',[]);
            p.addParameter('GroupMarker',{});
            p.addParameter('GroupMarkerSize',[]);
            p.addParameter('GroupLineStyle',{});
            p.addParameter('ShowGroupingVariable',[]);
            p.addParameter('ShowGroups',{});
            p.addParameter('ShowUpperTrianglePlots',true);
            p.addParameter('Legend','on');
            p.addParameter('Parent','');
            p.addParameter('Position','');
            p.parse(varargin{:});
            opts = p.Results;
            histUsingDefault = any(strcmpi('Histogram',p.UsingDefaults));
        end
    end
    
    methods(Access='protected')
        function createPlot(hObj)
            if hObj.ShowView
                % Cache the interpreter and linear fit before recreating
                % the plot
                if isempty(hObj.Axes)
                    Interpreter = 'tex';
                else
                    Interpreter = hObj.Axes.Interpreter;
                end
                
%                 LinearFitIdx = hObj.LinearFitIndex;
                
                if isempty(hObj.Parent)
                    if ~isempty(hObj.Axes)
                        h = ancestor(hObj.Axes,{'figure','uipanel'});
                        delete(h.Children);
                    else
                        clf;
                    end
                else
                    h = hObj.Parent;
                    delete(h.Children);
                end
                nr = hObj.Model.NumRows;
                nc = hObj.Model.NumColumns;
                if isempty(nr) || (nr==0)
                    nr = 1;
                end
                if isempty(nc) || (nc==0)
                    nc = 1;
                end
                delete(hObj.Legend_I);
                ag = controllib.ui.plotmatrix.internal.ManageAxesGrid(nr,nc,'Parent',hObj.Parent);
                hObj.Axes = ag;
                hObj.Axes.Interpreter = Interpreter;
                
                if hObj.XvsX
                    ag.DiagonalAxesSharing = 'XOnly';
                else
                    ag.DiagonalAxesSharing = 'Both';
                end
                
                if isempty(hObj.Parent)
                    hObj.Parent = ag.Parent;
                else
                    ag.Parent = hObj.Parent;
                end
                if isempty(hObj.Position)
                    hObj.Position = ag.Position;
%                 else
%                     ag.Position = hObj.Position;
                end
                [nR,nC] = size(ag);
                hObj.LinearFitIndex = false(nR,nC);
%                 if isempty(LinearFitIdx)
%                     [nR,nC] = size(ag);
%                     hObj.LinearFitIndex = false(nR,nC);
%                 else
%                     hObj.LinearFitIndex = LinearFitIdx;
%                 end
                hObj.addMenu;
                hObj.addBrushingMenu;
            end
        end
        
        function updateScatterPlot(hObj)
            if hObj.ShowView
                ag = hObj.Axes;
                Ax = ag.getAxes;
                % axes = ag.getPeripheralAxes
                hh = findobj(Ax,'Tag','groupLine');
                hh.delete; %boxplot
                
                style = hObj.Model.Style;
                clr = style{1};
                marker = style{2};
                markersize = style{3};
                linestyle = style{4};
                location = hObj.Model.AxesLocation;
                xdata = hObj.Model.XData;
                ydata = hObj.Model.YData;
                set(Ax,'NextPlot','add');
                for i = 1:size(location,1)
                    l1 = location(i,1);
                    l2 = location(i,2);
                    g = hObj.Model.GroupData(i);
                    if ~isempty(xdata{i}) || ~isempty(ydata{i})
                        ax = Ax(l1,l2);
                        hh = plot(xdata{i},ydata{i},'Color',clr(g,:),...
                            'Marker',marker{g},'MarkerSize',markersize(g),...
                            'LineStyle',linestyle{g},'Tag','groupLine','Parent',ax);
                        hh.Annotation.LegendInformation.IconDisplayStyle = 'off';
                        hh.UIContextMenu = get(ax,'UIContextMenu');
                    end
                end
                
                updateLinearFit(hObj);
                
                set(Ax,'NextPlot','replace');
                
                %Add callback to manage brush events
                h = brush(ancestor(hObj,'figure'));
                set(h,'ActionPostCallback',@(src,evt) brushcallback(hObj,src,evt) );

                %Hide floating palette, need to do this after adding brush
                %events as brush events turns the toolbar back on.
                toggleToolbar(ag,'off')
                
            end
        end
        
        function updatePlot(hObj)
            if hObj.ShowView
                % peripheral plots
                if hObj.Model.NumRows~=0 && hObj.Model.NumColumns~=0
                    hObj.createPeripheralPlot;
                end
                
                axes = findobj(hObj.Parent,'Type','Axes');
                set(axes,'ButtonDownFcn',@(src,evt)popoutcallback(src,evt,hObj));
                
                % show groups
                hObj.showGroups;
                
                % update limits
                ag = hObj.Axes;
                axes = ag.getAxes;
                idx = arrayfun(@(x)any(strcmpi(get(x.Children,'Tag'),'groupLine')),axes);
                idx = idx(:);
                ag.customUpdateLimits(idx);
                
                %             % change datetime ticklabels
                %             xdatetimeID = hObj.Model.XDatetimeIndex;
                %             ydatetimeID = hObj.Model.YDatetimeIndex;
                %             if ~isempty(xdatetimeID)
                %                 for i = 1:numel(xdatetimeID)
                %                     ax = axes(end,xdatetimeID(i));
                %                     ax.XTick = datestr(ax.XTick);
                %                 end
                %             end
                %             if~isempty(ydatetimeID)
                %                 for i = 1:numel(xdatetimeID)
                %                     ax = axes(ydatetimeID(i),1);
                %                     ax.YTick = datestr(ax.YTick);
                %                 end
                %             end
                
                % update XLabel/YLabel
                xname = hObj.XVariable;
                yname = hObj.YVariable;
                if ischar(xname)
                    xname = {xname};
                end
                if ischar(yname)
                    yname = {yname};
                end
                if hObj.Model.Trellis
                    gl = hObj.GroupLabels;
                    idx_showgv = hObj.Model.ShowGroupingVariableIndex;
                    gl = gl(idx_showgv);
                    xaxisIdx = hObj.Model.XAxisIndex;
                    yaxisIdx = hObj.Model.YAxisIndex;
                    if xaxisIdx~=0
                        xname2 = gl{xaxisIdx}(:);
                        xname = repmat(xname,numel(xname2),1);
                        xname2 = repmat(xname2(:),1,size(xname,2));
                        xname2 = cellfun(@num2str, xname2(:,:),'UniformOutput',false);
                        xname = strcat(xname,',',xname2);
                        xname = xname(:);
                    end
                    if yaxisIdx~=0
                        yname2 = gl{yaxisIdx};
                        yname = repmat(yname,numel(yname2),1);
                        yname2 = repmat(yname2(:),1,size(yname,2));
                        yname2 = cellfun(@num2str, yname2(:,:),'UniformOutput',false);
                        yname = strcat(yname,',',yname2);
                        yname = yname(:);
                    end
                end
                nr = hObj.Model.NumRows;
                nc = hObj.Model.NumColumns;
                ag.XLabel(end,1:nc) = xname;
                ag.YLabel(1:nr,1) = yname;
                
                % ShowUpperTrianglePlots
                if hObj.XvsX
                    hObj.showUpperTrianglePlots;
                end
                
                % Legend
                hObj.createLegend;
                
                if isempty(hObj.GroupingVariable)
                    hObj.Legend = false;
                end
                %legendtoggle
            end
        end
        
        function updateLinearFit(hObj)
            if hObj.ShowView
                ag = hObj.Axes;
                axes = ag.getAxes;
                [nR,nC] = size(ag);
                for iRow = 1:nR
                    for iCol = 1:nC
                        if hObj.LinearFitIndex(iRow,iCol)
                            X = hObj.Data.(hObj.XVariable{iCol});
                            Y = hObj.Data.(hObj.YVariable{iRow});
                            ok = ~(isnan(X) | isnan(Y));
                            beta = polyfit(X(ok),Y(ok),1);
                            ax = axes(iRow,iCol);
                            datacolor = [.75 .75 .75]; % Light Gray
                            Tag = 'LinearFitLine';
                            xdat = ax.XLim;
                            ydat = beta(1).*xdat+beta(2);
                            line(xdat,ydat,'Parent',ax,...
                                'LineStyle', '-',...
                                'Color',datacolor, ...
                                'Tag', Tag);
                        else
                            hl = findobj(axes(iRow,iCol),'Tag','LinearFitLine');
                            if ~isempty(hl)
                                delete(hl);
                            end
                        end
                    end
                end
            end
        end
        
        function checkSize(hObj, arg, varname)
            % Check group related variable size
            gv = hObj.GroupingVariable;
            if ~isempty(gv) && ~isempty(arg)
                sz_arg = computeSize(arg);
                sz_gv = hObj.NumGroupingVariable;
                err = 0;
                if strcmpi(varname,'GroupBins')
                    if ~(sz_arg==sz_gv || sz_gv==1&&...
                            (isnumeric(arg)||ischar(arg)||...
                            (iscell(arg)&&~any(cellfun(@iscell,arg)))))
                        err = 1;
                    end
                elseif strcmpi(varname,'GroupLabels')
                    if ~(sz_arg==sz_gv || sz_gv==1&&...
                            iscell(arg)&&~any(cellfun(@iscell,arg)))
                        err = 1;
                    end
                elseif strcmpi(varname,'ShowGroups')
                    if ~(sz_arg==sz_gv || sz_gv==1&&isnumeric(arg)) %[1 0] vs {[1 0]}
                        err = 1;
                    end
                else % gvlabel,gvstyle,showgv
                    if sz_arg~=sz_gv
                        err = 1;
                    end
                end
                if err
                    error(message('Controllib:plotmatrix:WrongNumElement',varname));
                end
            elseif ~isempty(arg)
                error(message('Controllib:plotmatrix:InvalidGroupInfo'));
            end
        end
        
        function popOutAxes(hObj,AxesToPopOut)
            ag = hObj.Axes;
            ax = ag.getAxes;
            idx = arrayfun(@(x)isequal(x,AxesToPopOut),ax);
            [i,j] = find(idx);
            if isempty(i)
                %peripheral-plot
            end
            fnew = figure;
            
            copyobj(AxesToPopOut,fnew);
            a = get(fnew,'Children');
            set(a,'Position',[.13 .11 .77 .815],'ButtonDownFcn',[]);
            set(a,'XTickLabel',get(gca,'XTick'));
            set(a,'YTickLabel',get(gca,'YTick'));
            % need labels and limits on the histogram(diagonal) axes
            if ~isempty(i)
                set(a,'XLabel',copy(ax(end,j).XLabel));
                set(a,'YLabel',copy(ax(i,1).YLabel));
            end
        end
        
        function brushcallback(hObj,src,evt)
            %Manage brushing events
            
            if hObj.Model.Trellis
                return;
            end
            hl = findobj(evt.Axes,'Tag','groupLine');
            if isempty(hl)
                return;
            else
                %Find brushed data for lines on selected axes
                sz = length(hl);
                brushdata = cell(sz,1);
                for i = 1:sz
                    brushdata{i} = hl(i).BrushData;
                end
                
                %Set brushed data on lines in other axes
                ax = findobj(src,'Type','Axes');
                brushAxesId = arrayfun(@(x)~isempty(findobj(x,'Tag','groupLine')),ax);
                evtId = arrayfun(@(x)isequal(x,evt.Axes),ax);
                brushAxesId(evtId) = 0;
                ax = ax(brushAxesId);
                for i = 1:length(ax)
                    groupline = findobj(ax(i),'Tag','groupLine');
                    for j = 1:sz
                        groupline(j).BrushData = brushdata{j};
                    end
                end
            end
            
            % get index of the brushed data points from brushed line data
            x = hObj.Model.X(:,hObj.Model.AxesLocation(1,2));
            y = hObj.Model.Y(:,hObj.Model.AxesLocation(1,1));
            xdata = hObj.Model.XData(1:hObj.Model.NumGroup);
            ydata = hObj.Model.YData(1:hObj.Model.NumGroup);
            brushdata = flipud(brushdata);
            brushedIndex = zeros(size(x,1),1);
            for i = 1:hObj.Model.NumGroup
                if any(brushdata{i})
                    idx = (brushdata{i}==1);
                    idx_i = ismember([x,y],[xdata{i}(idx),ydata{i}(idx)],'rows');
                    brushedIndex = brushedIndex|idx_i;
                end
            end
            hObj.BrushedIndex = brushedIndex;
        end
    end
    
    % QE methods
    methods(Access = 'public', Hidden = true)
        function LinearFitIndex = qeGetLinearFitIndex(this)
            LinearFitIndex = this.LinearFitIndex;
        end
    end
    % Events
    events
        DataChanged
        XYChanged %XVariable/YVariable
        GroupingVariableChanged
        GroupBinsChanged
        GroupingVariableStyleChanged
        GroupStyleChanged %GroupColor/Marker/MarkerSize/LineStyle
        ShowGroupsChanged
        PeripheralPlotChanged %Boxplot/Histogram/KSplot
    end
    
end

% ------------ callback functions ------------
function xyChangedCallback(src,~)
src.Model.updateData;
src.createPlot;
src.updateScatterPlot;
src.updatePlot;
end

function gvChangedCallback(src,evt)
if ~isequal(src.GroupingVariable,evt.OldValue)
    src.Listeners{1}.Enabled = 0;
    src.Listeners{2}.Enabled = 0;
    src.Listeners{3}.Enabled = 0;
    src.Listeners{4}.Enabled = 0;
    src.Listeners{5}.Enabled = 0;
    src.Listeners{6}.Enabled = 0;
    src.IsInitialized = false;
    src.NumGroupingVariable = computeSize(src.GroupingVariable);
    sz = src.NumGroupingVariable;
    [tf, loc] = ismember(src.GroupingVariable,evt.OldValue);
    if any(tf)
        loc = loc(loc~=0); % old idx
        gvstyle = src.GroupingVariableStyle(loc);
        gbins = src.GroupBins(loc);
        glabels = src.GroupLabels(loc);
        showgv = src.ShowGroupingVariable(loc);
        showgrp = src.ShowGroups(loc);
        gvlabels = src.GroupingVariableLabels(loc);
    end
    c = cell(1,sz); c(:) = {''};
    src.GroupingVariableStyle = c;
    src.GroupBins = cell(1,sz);
    src.GroupLabels = cell(1,sz);
    src.ShowGroupingVariable = ones(1,sz);
    src.ShowGroups = cell(1,sz);
    src.GroupingVariableLabels = cell(1,sz);
    if any(tf)
        loc_t = (tf==1); % new idx
        src.GroupingVariableStyle(loc_t) = gvstyle;
        src.GroupBins(loc_t) = gbins;
        src.GroupLabels(loc_t) = glabels;
        src.ShowGroupingVariable(loc_t) = showgv;
        src.ShowGroups(loc_t) = showgrp;
        src.GroupingVariableLabels(loc_t) = gvlabels;
    end
    loc_f = (tf==0);
    src.GroupingVariableLabels(loc_f) = src.GroupingVariable(loc_f);
    loc = 1:sz;
    src.resetGroupStyle(loc);
    src.Model = controllib.ui.plotmatrix.internal.LineCreator(src);
    src.GroupBins = src.Model.GroupBins;
    src.IsInitialized = true;
    src.createPlot;
    src.updateScatterPlot;
    src.updatePlot;
end
src.Listeners{1}.Enabled = 1;
src.Listeners{2}.Enabled = 1;
src.Listeners{3}.Enabled = 1;
src.Listeners{4}.Enabled = 1;
src.Listeners{5}.Enabled = 1;
src.Listeners{6}.Enabled = 1;
end

function groupbinsChangedCallback(src,evt)
src.Listeners{1}.Enabled = 0;
src.Listeners{3}.Enabled = 0;
src.Listeners{4}.Enabled = 0;
src.Listeners{5}.Enabled = 0;
src.IsInitialized = false;
src.GroupBins = src.Model.GroupBins;

oldLabels = src.GroupLabels;
oldShowgrp = src.ShowGroups;
oldGroupingVariableStyle= src.GroupingVariableStyle;
oldGroupColor = src.GroupColor;
oldGroupMarker = src.GroupMarker;
oldGroupMarkerSize = src.GroupMarkerSize;
oldGroupLineStyle = src.GroupLineStyle;

% unchanged grouping variable
loc = cellfun(@(x1,x2)isequal(x1,x2),src.GroupBins,evt.OldValue);
if any(loc)
    glabels = src.GroupLabels(loc);
    showgrp = src.ShowGroups(loc);
    src.ChangedGroupIdx = ~loc;
end
sz = src.NumGroupingVariable;
src.GroupLabels = cell(1,sz);
src.ShowGroups = cell(1,sz);
if any(loc)
    src.GroupLabels(loc) = glabels;
    src.ShowGroups(loc) = showgrp;
end
src.resetGroupStyle(loc);
% src.Model = controllib.ui.plotmatrix.internal.LineCreator(src);
src.Model.updateGroupLabelsAndShowGroups;
src.Model.updateShowGroupingVariable;
src.Model.updateData;
src.Model.updateStyle;
src.IsInitialized = true;

changedBinIdx = find(~loc);
for i = 1:length(changedBinIdx)
    binIdxI = changedBinIdx(i);
    if iscell(src.GroupBins{binIdxI}) % categorical grouping variable
        unchangedGroupIndex = ismember(src.GroupBins{binIdxI},evt.OldValue{binIdxI});
        changedLength = sum(~unchangedGroupIndex);
        oldIndex = ismember(evt.OldValue{binIdxI},src.GroupBins{binIdxI});
    else % continuous grouping variable
        unchangedGroupIndex = ismember(src.GroupBins{binIdxI},evt.OldValue{binIdxI},'rows');
        changedLength = sum(~unchangedGroupIndex);
        oldIndex = ismember(evt.OldValue{binIdxI},src.GroupBins{binIdxI},'rows');
    end
    src.GroupLabels{binIdxI}(unchangedGroupIndex) = oldLabels{binIdxI}(oldIndex);
    src.ShowGroups{binIdxI}(unchangedGroupIndex) = oldShowgrp{binIdxI}(oldIndex);
    style = oldGroupingVariableStyle{changedBinIdx(i)};
    if strcmpi(style,'Color')
        changedColor = setdiff(src.GroupColor,oldGroupColor(oldIndex,:),'rows');
        src.GroupColor(unchangedGroupIndex,:) = oldGroupColor(oldIndex,:);
        src.GroupColor(~unchangedGroupIndex,:) = changedColor(1:changedLength,:);
    elseif strcmpi(style,'MarkerType')
        changedMaker = setdiff(src.GroupMarker,oldGroupMarker(oldIndex));
        src.GroupMarker(unchangedGroupIndex) = oldGroupMarker(oldIndex); 
        src.GroupMarker(~unchangedGroupIndex) = changedMaker(1:changedLength);
    elseif strcmpi(style,'MarkerSize')
        changedSize = setdiff(src.GroupMarkerSize,oldGroupMarkerSize(oldIndex));
        src.GroupMarkerSize(unchangedGroupIndex) = oldGroupMarkerSize(oldIndex);
        src.GroupMarkerSize(~unchangedGroupIndex) = changedSize(1:changedLength);
    elseif strcmpi(style,'LineStyle')
        changedLineStyle = setdiff(src.GroupLineStyle,oldGroupLineStyle(oldIndex));   
        src.GroupLineStyle(unchangedGroupIndex) = oldGroupLineStyle(oldIndex);
        src.GroupLineStyle(~unchangedGroupIndex) = changedLineStyle(1:changedLength);
    end
end

src.createPlot;
src.updateScatterPlot;
src.updatePlot;
src.Listeners{1}.Enabled = 1;
src.Listeners{3}.Enabled = 1;
src.Listeners{4}.Enabled = 1;
src.Listeners{5}.Enabled = 1;
src.ChangedGroupIdx = ones(src.NumGroupingVariable,1);
end

function gvstyleChangedCallback(src,evt)
src.Listeners{3}.Enabled = 0;
src.IsInitialized = false;
loc = cellfun(@(x1,x2)isequal(x1,x2),src.GroupingVariableStyle,evt.OldValue);
if any(ismember(src.GroupingVariableStyle,{'XAxis','YAxis'})|...
        ismember(evt.OldValue,{'XAxis','YAxis'}))
    src.Model.updateData;
end
src.resetGroupStyle(loc);
src.Model.updateStyle;
src.Listeners{3}.Enabled = 1;
src.IsInitialized = true;
src.createPlot;
src.updateScatterPlot;
src.updatePlot;
end

function groupstyleChangedCallback(src,evt)
src.Listeners{3}.Enabled = 0;
src.Listeners{4}.Enabled = 0;
if strcmpi(evt.Name,'GroupColor')
    styleType = 'Color';
    idx = 1;
elseif strcmpi(evt.Name,'GroupMarker')
    styleType = 'MarkerType';
    idx = 2;
elseif strcmpi(evt.Name,'GroupMarkerSize')
    styleType = 'MarkerSize';
    idx = 3;
elseif strcmpi(evt.Name,'GroupLineStyle')
    styleType = 'LineStyle';
    idx = 4;
end
tf = ismember(src.GroupingVariableStyle,styleType);
if ~any(tf)
    src.Model.Style{idx} = repmat(src.(evt.Name),src.Model.NumGroup,1);
else
    src.ChangedGroupIdx = zeros(src.NumGroupingVariable,1);
    src.Model.updateStyle;
end
src.updateScatterPlot;
src.updatePlot;
src.ChangedGroupIdx = ones(src.NumGroupingVariable,1);
src.Listeners{3}.Enabled = 1;
src.Listeners{4}.Enabled = 1;
end

function popoutcallback(src,~,hObj)
if strcmpi('open',get(src.Parent,'SelectionType'))
    popOutAxes(hObj,src);
end
end

% ------------ local functions ------------
function checkVariableNames(tblnames,var)
% Check XVariable/YVariable/GroupingVariable
if ~ischar(var) && ~(iscell(var) && all(cellfun(@ischar,var)))...
        && ~isempty(var) && ~isnumeric(var)
    error(message('Controllib:plotmatrix:InvalidVariableName'));
end
if ~isempty(var)
    if (ischar(var)||iscell(var)) && ~all(ismember(var,tblnames))
        error(message('Controllib:plotmatrix:UnrecognizedVariableName'));
    elseif isnumeric(var) && any(var>numel(tblnames) | var<1)
        error(message('Controllib:plotmatrix:InvalidColumnNumber'));
    end
end
end

function sz = computeSize(arg)
arg = arg(:);
if iscell(arg) || isnumeric(arg) || islogical(arg)
    sz = size(arg,1);
elseif ischar(arg)
    sz = 1;
end
end

function var = noncell2cell(var)
if ~iscell(var)
    var = {var};
end
var = var(:)';
end

% LocalWords:  XAxis YAxis XVariable YVariable isnat sz gvstyle glabels noncell gcolor statslib
% LocalWords:  gmarker gmarkersize glinestyle showgv showgrps checklicense ksplot Periphera
% LocalWords:  groupedksplot XvsX XvsYShowUpperTrianglePlots SETBRUSHEDINDEX xdata ydata brushdata
% LocalWords:  tbl nr nc ag XOnly hh clr markersize linestyle evt brushcallback popoutcallback
% LocalWords:  ticklabels xdatetime ydatetime YTick XLabel xname yname gl xaxis yaxis legendtoggle
% LocalWords:  datacolor xdat ydat hl varname gv gvlabel fnew groupline gbins showgrp gvlabels
% LocalWords:  groupbinsChangedCallback groupstyleChangedCallback tblnames
