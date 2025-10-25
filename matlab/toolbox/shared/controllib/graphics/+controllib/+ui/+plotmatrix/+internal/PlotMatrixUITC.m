classdef PlotMatrixUITC < ctrluis.component.AbstractTC
    %PLOTMATRIXDIALOGTC is the data class that provides necessary hooks to
    %modify table data that is the basis for plotmatrix.
    
    %   Copyright 2015-2016 The MathWorks, Inc.
    
    properties (Access = private)
        % View is the truth - the data class on which changes will be
        % applied on hitting OK/ Apply
        
        % Database is a cache of all incremental temporary changes. Any
        % queries from the View will be answered by the database. The
        % database will have all the independent variables from the view.
        % The only purpose of the database is to answer the view with the
        % set of all the changes made during the life time of the data.
        
        % Changeset only consists of the variables that were actually
        % modified. Any change in the changeset is immediately propagated
        % to the database.
        
        View            % PlotMatrix view class - the truth
        Database        % The set of all incremental changes
        ChangeSet       % The latest change
        % Struct to manage temporary changes during dialog lifetime
        GroupingVariableStruct
        Listeners       % Listens to the plotmatrix object's data changes
    end
    
    properties
        SelectedGroupingVariable
    end
    
    methods
        %% Constructor
        function this = PlotMatrixUITC(View)
            narginchk(1,1);
            if isa(View, 'controllib.ui.plotmatrix.internal.View')
                this.View = View;
                pullData(this);
                this.Listeners = [this.Listeners; addlistener(this.View, 'XYChanged', @(es,ed)pullData(this))];
                this.Listeners = [this.Listeners; addlistener(this.View, 'GroupingVariableChanged', @(es,ed)pullData(this))];
                this.Listeners = [this.Listeners; addlistener(this.View, 'ShowGroupsChanged', @(es,ed)syncShowGroups(this))];
                this.Listeners = [this.Listeners; addlistener(this.View, 'ObjectBeingDestroyed', @(es,ed)delete(this))];
            else
                error(message('Controllib:general:UnexpectedError', ...
                    'The input should be of type controllib.ui.plotmatrix.internal.View'));
            end
        end
        
        function pullData(this)
            this.Database = copyData(this.View);
            this.ChangeSet = struct;
            
            this.GroupingVariableStruct = createGroupingVariableMapping(this);
            if ~isempty(this.Database.GroupingVariable)
                this.SelectedGroupingVariable = this.Database.GroupingVariable{1};
            end
        end
        
        function syncShowGroups(this)
            if isequal(cellfun(@numel,this.Database.ShowGroups), cellfun(@numel, this.View.ShowGroups)) && ~any(cellfun(@isempty, this.View.ShowGroups))
                this.Database.ShowGroups = this.View.ShowGroups;
                if isfield(this.ChangeSet, 'ShowGroups')
                    this.ChangeSet = rmfield(this.ChangeSet, 'ShowGroups');
                end
            end
        end
        
        function Parent = getParent(this)
            Parent = this.View.Parent;
        end
        
        function gc = createView(this)
            gc = controllib.ui.plotmatrix.internal.ManageGroupsGC(this);
        end
        
        function set.SelectedGroupingVariable(this, NewGV)
            this.SelectedGroupingVariable = NewGV;
            notify(this,'GroupingVariableSelectionChanged');
        end
        
        function GV = getSelectedGroupingVariable(this)
            GV = this.SelectedGroupingVariable;
        end
        
        function delete(this)
            delete(this.Database);
            this.ChangeSet = [];
            delete(this.Listeners);
        end
        %% Services needed by dialogs - Provided by TC
        
        % Grouping variable uitable
        % GVData = getGroupingVariableData(this)
        % TableData = nx5 cell
        % Grouping Variable - h.GroupingVariable
        % Label - h.GroupingVariableLabel
        % Type - class(h.Data(h.GroupingVariable))
        % Style - h.GroupingVariableStyle
        % Active - h.ShowGroups
        function GVData = getGroupingVariableData(this)
            gvnames = this.Database.GroupingVariable;
            gvlabels = this.Database.GroupingVariableLabels;
            type = cell(1,this.Database.NumGroupingVariable);
            active = cell(1,this.Database.NumGroupingVariable);
            for i = 1:this.Database.NumGroupingVariable
                if  isa(this.Database.Data{:,this.Database.GroupingVariable(i)},'categorical')
                    type{i} = getString(message('Controllib:plotmatrix:strCategorical'));
                else
                    type{i} = getString(message('Controllib:plotmatrix:strContinuous'));
                end
                active{i} = boolean(this.Database.ShowGroupingVariable(i));
            end
            style = this.Database.GroupingVariableStyle;
            GVData = [gvnames',gvlabels',type',style',active'];
        end
        
        function StyleList = getAllStyles(~)
           StyleList = {'Color', 'MarkerSize', 'MarkerType'};
        end
        
        % GVList = getGroupingVariableList(this)
        % List of all columns in data, that are not already grouping variables
        function GVList = getGroupingVariableList(this)
            vnames = this.Database.Data.Properties.VariableNames;
            gnames = this.Database.GroupingVariable;
            idx = ~ismember(vnames,gnames);
            GVList = vnames(idx);
        end
        
        % Get properties for GC
        function Prop = getProperty(this,Property)
            Prop = this.Database.(Property);
        end
        
        % createGroupingVariable(this,Variable)
        % Append to list of h.GroupingVariable - we do not know anything about
        % style as of now. trap errors and throw - there could me more grouping
        % variables than there are styles
        % updateGroups() - throws GroupDataChanged
        function createGroupingVariable(this,Variable)
            style = getAllStyles(this);
            if sum(ismember(style,this.Database.GroupingVariableStyle))==3
                error(getString(message('Controllib:plotmatrix:errTooManyGV')));
            else
                setChangeSetProperty(this, 'GroupingVariable', [this.Database.GroupingVariable Variable]);
                this.GroupingVariableStruct = createGroupingVariableMapping(this);
            end
        end
        
        % deleteGroupingVariable(this, Variable)
        % Remove from the list of grouping variables. Do not do anything to the
        % styles
        % updateGroups() - throws GroupDataChanged
        function deleteGroupingVariable(this, Variable)
            Idx = getIdx(this,Variable);
            GV = this.Database.GroupingVariable;
            GV(Idx) = [];
            setChangeSetProperty(this, 'GroupingVariable', GV);
            this.GroupingVariableStruct = createGroupingVariableMapping(this);
        end
        
        % setGroupingVariableStyle(this, Variable, Style)
        % Sets the grouping variable style
        % updateGroups() - throws GroupDataChanged
        function setGroupingVariableStyle(this, Variable, Style, DoUpdate)
            if nargin == 3
                DoUpdate = true;
            end
            IdxVariable = getIdx(this,Variable);
            AllStyles = this.Database.GroupingVariableStyle;
            OldStyle = AllStyles{IdxVariable};
            
            [b,IdxExisting] = ismember(Style,AllStyles);
            % If maximum number of styles have reached and style is being
            % repeated, swap the styles
            b = b & numel(AllStyles) == 3;
            if b
                AllStyles{IdxExisting} = AllStyles{IdxVariable};
            end
            
            AllStyles{IdxVariable} = Style;
            setChangeSetProperty(this, 'GroupingVariableStyle', AllStyles);
            PropName = getStyleName(this, OldStyle);
            setChangeSetProperty(this, PropName, this.Database.(PropName));
            if DoUpdate
                update(this);
            end
        end
        
        % setGroupingVariableLabel(this,Variable,Label)
        function setGroupingVariableLabel(this,Variable,Label)
            Idx = getIdx(this,Variable);
            AllLabels = this.Database.GroupingVariableLabels;
            AllLabels{Idx} = Label;
            setChangeSetProperty(this, 'GroupingVariableLabels', AllLabels);
        end
        
        % setShowGroupingVariable(this,Variable,ShowGV)
        function setShowGroupingVariable(this,Variable,ShowGV)
            Idx = getIdx(this,Variable);
            AllShow = this.Database.ShowGroupingVariable;
            AllShow(Idx) = ShowGV;
            setChangeSetProperty(this, 'ShowGroupingVariable', AllShow);
        end
        
        %% GROUPS
        % [Title,NumGroups] = getGroupTitle(this,GVIdx) Returns the grouping
        % variable label and number of groups corresponding to GVIdx.
        function [Title,NumGroups] = getGroupTitle(this,Variable)
            Idx = getIdx(this,Variable);
            Title = this.Database.GroupingVariableLabels(Idx);
            NumGroups = length(this.Database.GroupBins{Idx});
        end
        
        % [StyleName, GroupData] = getGroupData(this, GV)
        % GroupData = mx4 cell
        % Group Label || Bin/Value || <Style> || Show
        % Group Label - h.GroupLabel
        % Bin/Value - h.GroupBins
        % <Style> - h.GroupStyle
        % Show - h.ShowGroups
        % Bin/Value display - color     - color picker - Number
        %                     size      - numbers      - Number
        %                     type      - type         - Char
        %                     LineStyle - style        - Char
        % GC - Need a createColor(RGB) for the color picker to work
        function [StyleName, GroupData] = getGroupData(this, Variable)
            Idx = getIdx(this,Variable);
            glabel = this.Database.GroupLabels{Idx};
            if iscell(this.Database.GroupBins{Idx})
                gbins = this.Database.GroupBins{Idx};
            else
                gbins = this.Database.GroupBins{Idx};
                gbins = num2cell(gbins(:,2),2)';
            end
            StyleName = this.Database.GroupingVariableStyle(Idx);
            style = this.Database.(getStyleName(this,StyleName));
            if ~iscell(style)
                if strcmpi(StyleName,'Color')
                    style = num2cell(style,2);
                else
                    style = num2cell(style,1);
                end
            end
            showgrps = num2cell(this.Database.ShowGroups{Idx});
            idx = strcmpi(glabel,'undefined');
            if any(idx)
               glabel(idx) = [];
               style(idx) = [];
               showgrps(idx) = [];
            end
            if ~strcmpi(StyleName,'Color')
                style = style';
            end
            GroupData = [glabel',gbins',style,showgrps'];
        end
        
        % setGroupStyle(this,GV, Style)
        % Get the appropriate style for GV, set the corresponding property
        function setGroupStyle(this,Variable,loc,NewStyle)
            Idx = getIdx(this,Variable);
            gvstyle = this.Database.GroupingVariableStyle(Idx);
            if strcmpi(gvstyle,'Color')
                styleType = 'GroupColor';
            elseif strcmpi(gvstyle,'MarkerType')
                styleType = 'GroupMarker';
                NewStyle = {NewStyle};
            elseif strcmpi(gvstyle,'MarkerSize')
                styleType = 'GroupMarkerSize';
            elseif strcmpi(gvstyle,'LineStyle')
                styleType = 'GroupLineStyle';
                NewStyle = {NewStyle};
            end
            gstyle = this.Database.(styleType);
            if strcmpi(gvstyle,'Color')
                gstyle(loc,:) = NewStyle;
            else
                gstyle(loc) = NewStyle;
            end
            setChangeSetProperty(this, styleType, gstyle);
        end
        
        % setGroupLabel(this, GV, Bin, Label)
        function setGroupLabel(this, Variable, loc, NewLabel)
            Idx = getIdx(this,Variable);
            glabels = this.Database.GroupLabels;
            glabels{Idx}(loc)= {NewLabel};
            setChangeSetProperty(this, 'GroupLabels', glabels);
        end
        
        % setShowGroups(this, GV, ShowGroups)
        function setShowGroups(this,Variable,loc,ShowGroups)
            Idx = getIdx(this,Variable);
            AllShow = this.Database.ShowGroups;
            AllShow{Idx}(loc) = ShowGroups;
            setChangeSetProperty(this, 'ShowGroups', AllShow);
        end
        
        % Categorical/ Custom
        % mergeCategoricalGroup(this, GV, GroupLabels)
        % 1. create a new column with the merged bins - add this to data
        % 2. createGroupingVariable(this,NewVariable)
        % 3. Propagate - GroupingVariableLabel, GroupStyle, showGroupingVariable from GV
        % 4. Propagate - unaffected GroupLabels, unaffected Bins,
        %unaffected Show, unaffected Style
        % 5. deleteGroupingVariable(GV)
        % 6. Update group title
        function mergeCategoricalGroup(this,GV,GrpIdx)
            % Current properties
            gvidx = getIdx(this,GV);            
            CurrentStyle = this.Database.GroupingVariableStyle{gvidx};
            CurrentLabel = this.Database.GroupingVariableLabels{gvidx};
            PropName = getStyleName(this,CurrentStyle);
            CurrentGroupStyle = this.Database.(PropName);
            CurrentBins = this.Database.GroupBins{gvidx};
            % New data column
            Groups = CurrentBins(GrpIdx);
            grpidx = ismember(this.Database.Data.(GV),Groups);
            
            if iscategorical(this.Database.Data.(GV))
                newGV = removecats(categorical(cellstr(this.Database.Data.(GV))),Groups);
                newGV(grpidx) = 'mergedBin';
            else % char/datetime
                newGV = this.Database.Data.(GV);
                newGV = cellstr(newGV);
                newGV(grpidx) = {'mergedBin'};
                newGV = char(newGV);
            end

            localData = this.Database.Data;
            localData(:,end+1) = table(newGV);
            
            tf_mergedBinExist = ismember(strcat('merged_',GV),localData.Properties.VariableNames);
            if tf_mergedBinExist
                localData.strcat('merged_',GV) = [];
            end
            localData.Properties.VariableNames{end} = strcat('merged_', GV);
            this.Database.Data = localData;
            setChangeSetProperty(this, 'Data', this.Database.Data);
            
            NewGV = this.Database.Data.Properties.VariableNames{end};
            % Create new grouping variable and remove existing variable
            deleteGroupingVariable(this,GV);
            createGroupingVariable(this,NewGV);
            
            % Propagate relevant properties
            DoUpdate = false;
            setGroupingVariableStyle(this,NewGV,CurrentStyle,DoUpdate);
            setGroupingVariableLabel(this,NewGV,CurrentLabel);
            
            GroupStyle = this.Database.(PropName);
            if ismember(PropName, {'GroupMarkerSize','GroupMarker','GroupLineStyle'})
                CurrentGroupStyle = CurrentGroupStyle';
                GroupStyle = GroupStyle';
            end
            
            NewBins = this.Database.GroupBins{end};
            oldIdx = ismember(NewBins,CurrentBins);
            oldStyleIdx = ismember(CurrentBins,NewBins);
            GroupStyle(oldIdx,:) = CurrentGroupStyle(oldStyleIdx,:);
            % different group styles for different groups
            newStyleChoices = CurrentGroupStyle(~oldStyleIdx,:);
            GroupStyle(~oldIdx,:) = newStyleChoices(1);
            
            setChangeSetProperty(this, PropName, GroupStyle);
            this.GroupingVariableStruct = createGroupingVariableMapping(this);
            
            if strcmpi(this.SelectedGroupingVariable,GV) && ~strcmpi(GV,'mergedBin')
                this.SelectedGroupingVariable = NewGV;
            end
        end
        
        % Continuous
        % setContinuousGroup(this,GroupBins) - accessed by Add Group,
        % Number of groups, picker
        % This needs to make sure that there are no undefined intervals. Get the
        % current bin values, diff against new bin values, find out what changed.
        % Then change neighboring bins to make it valid.
        function setContinuousGroup(this, GroupingVariable, GroupBins)
            gvidx = getIdx(this,GroupingVariable);
            gbins = this.Database.GroupBins;
            gbins{gvidx} = GroupBins;
            setChangeSetProperty(this, 'GroupBins', gbins);
        end
        
        function editBin(this, GroupingVariable, BinIdx, BinValue)
            gvidx = getIdx(this,GroupingVariable);
            gbins = this.Database.GroupBins;
            gbins{gvidx}(BinIdx,2) =  BinValue;
            gbins{gvidx}(BinIdx+1,1) =  BinValue;
            gbins{gvidx} = sort(gbins{gvidx});
            setChangeSetProperty(this, 'GroupBins', gbins);
        end
        
        % addContinuousGroup(this)
        % b = h.GroupBins{1};
        % b(end+1,:) = [0 0];
        % h.GroupBins{1} = b;
        % setContinuousGroup(this,GroupBins)
        function addContinuousGroup(this,Variable,binValue)
            Idx = getIdx(this,Variable);
            gbins = this.Database.GroupBins;
            binEdge = gbins{Idx}(:,2); 
            if any(binValue == binEdge)
                error('Bin value already exists.');
            end
            idx = find(binValue<binEdge);
            if isempty(idx)
                gbins{Idx}(end+1,:) = [binEdge(end) binValue];
            else
                idx = idx(1);
                gbins{Idx}(end+1,:) = [0 0];
                gbins{Idx}(idx+2:end,:)= gbins{Idx}(idx+1:end-1,:);
                if idx == 1
                    gbins{Idx}(1,:) = [-Inf binValue];
                else
                    gbins{Idx}(idx,:) = [binEdge(idx-1) binValue];
                end
                gbins{Idx}(idx+1,:) = [binValue binEdge(idx)];
                gbins{Idx}(end-1,2) = gbins{Idx}(end,1);
            end
            setChangeSetProperty(this, 'GroupBins', gbins);
        end
        
        % removeContinuousGroup(this,GroupLabel) - Used by 'Number of groups' and
        % by 'X' button
        % Find GroupLabel in the list of group bins
        % b = h.GroupBins{1};
        % b(idx,:) = [];
        % h.GroupBins{1} = b;
        % setContinuousGroup(this,GroupBins);
        function removeContinuousGroup(this,Variable,BinIdx)
            Idx = getIdx(this,Variable);
            gbins = this.Database.GroupBins;
            if BinIdx ~= size(gbins{Idx},1) && gbins{Idx}(BinIdx,1)~=-Inf
                gbins{Idx}(BinIdx+1,1) = gbins{Idx}(BinIdx,1);
            end
            gbins{Idx}(BinIdx,:) = [];
            setChangeSetProperty(this, 'GroupBins', gbins);
        end
        
        function bool = isCategorical(this,Variable)
            bool = iscategorical(this.Database.Data.(Variable));
        end
        % For each grouping variable,
        % group labels, bin/value, style, show
        %
        % struct('GroupingVariable', GV, ...
        %        'GroupBins', GroupBins, ...
        %        'GroupColor', GroupColor, ...
        %        'ShowGroups', ShowGroups);
        
        % Parsing functions used by View:
        % checkPosition - KernelDensityPlot, BoxPlot, Histogram
        % set_Data??
        % checkSize - GroupBins, GroupingVariableLabels, GroupingVariableStyle,
        % GroupLabels, ShowGroupingVariable,
        % checkVariableNames - GroupingVariable
        % validatestring - GroupingVariableStyle
        function pushData(this)
            for ct=1:numel(this.Listeners)
                this.Listeners(ct).Enabled = false;
            end
            
            NewData = struct;
            props = fieldnames(this.ChangeSet);
            for k = 1:length(props)
                p = props{k};
                NewData.(p) = this.Database.(p);
            end
            
            setData(this.View, NewData);
            for ct=1:numel(this.Listeners)
                this.Listeners(ct).Enabled = true;
            end
        end
    end
    
    methods (Access = protected)
        function IV = getIndependentVariables(~)
            IV = {...
                'Data', ...
                'GroupingVariable',...
                'GroupingVariableLabels',...
                'GroupBins',...
                'GroupingVariableStyle',...
                'ShowGroupingVariable',...
                'GroupLabels',...
                'GroupColor',...
                'GroupMarker',...
                'GroupMarkerSize',...
                'GroupLineStyle',...
                'ShowGroups'};
        end
        
        function setChangeSetProperty(this, varname, varvalue)
            ctrlMsgUtils.SuspendWarnings('Controllib:plotmatrix:DataWithNoGroup','Controllib:plotmatrix:EmptyGroupBins');
            
            props = this.getIndependentVariables;
            if isempty(props) || ~any( strcmp(varname, props) )
                ctrlMsgUtils.error('Controllib:toolpack:NotAnIndependentProperty', varname)
            end
            try
                CurrentValue = this.Database.(varname);
                this.Database.(varname) = varvalue;
            catch ME
                this.Database.(varname) = CurrentValue;
                rethrow(ME);
            end
            this.ChangeSet.(varname) = this.Database.(varname);
            
            if strcmpi(varname, 'GroupingVariable')
                % If the list of grouping variables changed, all dependent
                % properties also have to update
                fnames = fieldnames(this.ChangeSet);
                fnames(ismember(fnames,'GroupingVariable')) = [];
                for ct=1:numel(fnames)
                    this.ChangeSet.(fnames{ct}) = this.Database.(fnames{ct});
                end
            elseif strcmpi(varname, 'GroupBins')
                % If the list of group bins changed, all dependent
                % properties also have to update
                fnames = fieldnames(this.ChangeSet);
                fnames(ismember(fnames,'GroupBins')) = [];
                for ct=1:numel(fnames)
                    this.ChangeSet.(fnames{ct}) = this.Database.(fnames{ct});
                end
            end
        end
        
        % createGroupingVariableMapping(this)
        % struct(<GVName>,<GVIdx>);
        function GroupingVariableStruct = createGroupingVariableMapping(this)
           GroupingVariableStruct = cell2struct(num2cell(1:numel(this.Database.GroupingVariable)),this.Database.GroupingVariable,2);
        end
        
        % Idx = getIdx(this,VariableName);
        function Idx = getIdx(this,Variable)
            Idx = this.GroupingVariableStruct.(Variable);
        end
        
        function style = getStyleName(~, Property)
            if strcmpi(Property,'Color')
                style = 'GroupColor';
            elseif strcmpi(Property,'MarkerType')
                style = 'GroupMarker';
            elseif strcmpi(Property,'MarkerSize')
                style = 'GroupMarkerSize';
            elseif strcmpi(Property,'LineStyle')
                style = 'GroupLineStyle';
            end
        end
    end
    
    methods (Access = public, Hidden = true)
        %% QE methods
        function Props = qeGetProps(this)
            Props.Database = this.Database;
            Props.ChangeSet = this.ChangeSet;
            Props.IndependentVariables = getIndependentVariables(this);
        end
    end
    
    events
        GroupingVariableSelectionChanged
    end
    
end
