classdef (Sealed) BinningPopoutIcon < matlab.ui.componentcontainer.ComponentContainer
    % BinningPopoutIcon: A set controls for selecting the binning for a
    % given grouping variable hidden behind an icon
    %
    % For use in PivotTableTask and ComputeByGroupTask
    %
    % FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    % Its behavior may change, or it may be removed in a future release.

    %   Copyright 2023-2024 The MathWorks, Inc.

    properties (Access=public,Dependent)
        % Variable: set only, used to determine what values are valid for a
        % given grouping variable, data is not saved
        Variable
        % State: get&set, used for serialization
        State struct
        % VariableIsBinnable: get only
        VariableIsBinnable logical
        % Workspace: get&set, for the BinEdgesWSDD
        Workspace
        % Value: get only, to be used for script generation
        Value
    end 

    properties (Access=public)
        % VariableName: for use in tooltips
        VariableName char = '';
        % VariableClass: set when Variable is set
        VariableClass = '';
        % HasMissing: set when Variable is set
        HasMissing = false;
    end

    properties (Hidden,Transient)
        % Main controls in this component
        Icon                 matlab.ui.control.Image
        Popout               matlab.ui.container.internal.Popout
        % Controls inside the popout
        PopoutGrid           matlab.ui.container.GridLayout
        PopoutHeaderIcon     matlab.ui.control.Image
        BinningDropdown      matlab.ui.control.DropDown
        NumBinsSpinner       matlab.ui.control.Spinner
        BinEdgesWSDD         matlab.ui.control.internal.model.WorkspaceDropDown
        BinEdgesEditField    matlab.ui.control.EditField
        BinEdgesUnitsDD      matlab.ui.control.DropDown
        TimeBinDD            matlab.ui.control.DropDown
        BinWidthSpinner      matlab.ui.control.Spinner
        BinWidthUnitsDD      matlab.ui.control.DropDown
        % Helpers - set when Variable is set
        NumUnique = 0;
        DefaultTimeBin = 'year';
    end

    properties (Access=private,Constant)
        % Data with more unique values than this limit may be binned by default
        NumUniqueLimit = 30;
        TextRowHeight = 22;
        PopoutWidth = 220;
        IconWidth = 16;
        % Initial version of this custom control: R2023b
        Version = 1;
    end

    events (HasCallbackProperty, NotifyAccess = protected)
        % ValueChangedFcn callback property will be generated
        ValueChanged
    end

    methods (Access=protected)
        function setup(obj)
            % Method needed by the ComponentContainer constructor
            % Lay out the contents of the control

            % Set the initial position of the BinningPopoutIcon
            obj.Position = [0 0 obj.TextRowHeight obj.TextRowHeight];

            % Create Icon as the target and its corresponding popout
            % Popout target must be in a gridlayout
            g = uigridlayout(obj,...
                RowHeight=obj.TextRowHeight,...
                ColumnWidth=obj.TextRowHeight,...
                Padding=0);
            obj.Icon = uiimage(g,ScaleMethod="none",ImageClickedFcn=@donothing);
            matlab.ui.control.internal.specifyIconID(obj.Icon,...
                'meatballMenuUI',obj.IconWidth,obj.IconWidth);
            obj.Popout = matlab.ui.container.internal.Popout(...
                Position=[0 0 obj.PopoutWidth+10 (3*obj.TextRowHeight + 20)],...
                Trigger="click");

            % Layout popout controls
            obj.PopoutGrid = uigridlayout(Parent=[],...
                RowHeight=[obj.TextRowHeight obj.TextRowHeight obj.TextRowHeight],...
                ColumnWidth=[16 80 obj.PopoutWidth-106],...
                Padding=5,ColumnSpacing=5,RowSpacing=5);

            obj.PopoutHeaderIcon = uiimage(obj.PopoutGrid);
            matlab.ui.control.internal.specifyIconID(obj.PopoutHeaderIcon,...
                'infoUI',16,16);
            headerLabel = uilabel(obj.PopoutGrid,...
                Text=string(message("MATLAB:tableui:groupingBinningMethod")),...
                FontWeight="bold");
            headerLabel.Layout.Column = [2 3];

            obj.BinningDropdown = uidropdown(obj.PopoutGrid,...
                ValueChangedFcn=@obj.updateAndThrowValueChanged,...
                Items=string(message("MATLAB:dataui:None")),...
                ItemsData={'none'});
            obj.BinningDropdown.Layout.Row = 2;
            obj.BinningDropdown.Layout.Column = [1 3];

            obj.NumBinsSpinner = uispinner(obj.PopoutGrid,...
                ValueChangedFcn=@obj.updateAndThrowValueChanged,...
                RoundFractionalValues=true,Limits=[1 inf],UpperLimitInclusive=false);
            obj.NumBinsSpinner.Layout.Row = 3;
            obj.NumBinsSpinner.Layout.Column = [1 3];

            obj.BinEdgesWSDD = matlab.ui.control.internal.model.WorkspaceDropDown(...
                Parent=obj.PopoutGrid,ValueChangedFcn=@obj.updateAndThrowValueChanged,...
                ShowNonExistentVariable=true);
            obj.BinEdgesWSDD.FilterVariablesFcn = @obj.filterBinEdges;
            obj.BinEdgesWSDD.Layout.Row = 3;
            obj.BinEdgesWSDD.Layout.Column = [1 3];

            obj.BinEdgesEditField = uieditfield(obj.PopoutGrid,...
                ValueChangedFcn=@obj.validateRowVector,...
                Placeholder='[0 5 10 inf]',...
                Tooltip=string(message("MATLAB:tableui:groupingBinEdgesInPlaceTooltip")));
            obj.BinEdgesEditField.Layout.Row = 3;
            obj.BinEdgesEditField.Layout.Column = [1 2];

            binEdgesUnitsItemsData = {'milliseconds','seconds','minutes','hours','days','years'};
            obj.BinEdgesUnitsDD = uidropdown(obj.PopoutGrid,...
                ValueChangedFcn=@obj.updateAndThrowValueChanged,...
                ItemsData=binEdgesUnitsItemsData,...
                Items=getUnitsMessages(binEdgesUnitsItemsData));
            obj.BinEdgesUnitsDD.Layout.Row = 3;
            obj.BinEdgesUnitsDD.Layout.Column = 3;

            obj.TimeBinDD = uidropdown(obj.PopoutGrid,...
                ValueChangedFcn=@obj.handleEditable);
            obj.TimeBinDD.Layout.Row = 3;
            obj.TimeBinDD.Layout.Column = [1 3];

            obj.BinWidthSpinner = uispinner(obj.PopoutGrid,...
                ValueChangedFcn=@obj.updateAndThrowValueChanged,...
                Limits=[0 inf],LowerLimitInclusive=false,UpperLimitInclusive=false);
            obj.BinWidthSpinner.Layout.Row = 3;
            obj.BinWidthSpinner.Layout.Column = [1 2];

            obj.BinWidthUnitsDD = uidropdown(obj.PopoutGrid,...
                ValueChangedFcn=@obj.updateAndThrowValueChanged);
            obj.BinWidthUnitsDD.Layout.Row = 3;
            obj.BinWidthUnitsDD.Layout.Column = 3;

            obj.PopoutGrid.Parent = obj.Popout;
        end

        function update(obj)
            % Method required by ComponentContainer
            % Called when properties of the component are updated

            % Prevent the popout from being parented to the uifigure when
            % uninitialized (live task constructor complains!)
            if isempty(obj.VariableClass)
                obj.Popout.Target = [];
            else
                obj.Popout.Target = obj.Icon;
            end
            % Update size of popout depending on if we need 3rd row
            if isequal(obj.BinningDropdown.Value,'none')
                obj.Popout.Position = [0 0 obj.PopoutWidth+10 (2*obj.TextRowHeight + 10)];
            else
                obj.Popout.Position = [0 0 obj.PopoutWidth+10 (3*obj.TextRowHeight + 20)];
            end
            % Update Visibility/Parent for components
            obj.Icon.Enable = obj.VariableIsBinnable;
            obj.NumBinsSpinner.Visible = isequal(obj.BinningDropdown.Value,'numBins');
            obj.TimeBinDD.Visible = isequal(obj.BinningDropdown.Value,'timeBins');
            obj.BinEdgesWSDD.Visible = isequal(obj.BinningDropdown.Value,'binEdges');
            obj.BinEdgesEditField.Visible = isequal(obj.BinningDropdown.Value,'binEdgesInPlace');
            obj.BinEdgesUnitsDD.Visible = isequal(obj.BinningDropdown.Value,'binEdgesInPlace') && isequal(obj.VariableClass,'duration');
            if obj.BinEdgesUnitsDD.Visible
                obj.BinEdgesEditField.Layout.Column = [1 2];
            else
                obj.BinEdgesEditField.Layout.Column = [1 3];
            end
            obj.BinWidthSpinner.Visible = isequal(obj.BinningDropdown.Value,'binWidth');
            obj.BinWidthUnitsDD.Visible = isequal(obj.BinningDropdown.Value,'binWidth');
            widgets = [obj.NumBinsSpinner,obj.TimeBinDD,obj.BinEdgesWSDD, ...
                obj.BinEdgesEditField,obj.BinEdgesUnitsDD,obj.BinWidthSpinner,obj.BinWidthUnitsDD];
            matlab.internal.dataui.setParentForWidgets(widgets,obj.PopoutGrid);

            if ~isempty(obj.VariableName)
                % Set dynamic tooltip on Gridlayout
                extraMsgInputs = {};
                scheme = obj.BinningDropdown.Value;
                switch scheme
                    case 'numBins'
                        % need the number of bins
                        extraMsgInputs = {num2str(obj.NumBinsSpinner.Value)};
                    case 'binEdges'
                        % get the name of the workspace value, using '' when not
                        % yet selected
                        edges = obj.BinEdgesWSDD.Value;
                        if isequal(edges,'select variable')
                            edges = '';
                        end
                        extraMsgInputs = {edges};
                    case 'timeBins'
                        % get the lower case of the translated name from Items list
                        [~,idx] = ismember(obj.TimeBinDD.Value,obj.TimeBinDD.ItemsData);
                        extraMsgInputs = {lower(obj.TimeBinDD.Items{idx})};
                    case 'binWidth'
                        % e.g {'5','weeks'}
                        num = num2str(obj.BinWidthSpinner.Value);
                        % get the lower case of the translated name from Items list
                        [~,idx] = ismember(obj.BinWidthUnitsDD.Value,obj.BinWidthUnitsDD.ItemsData);
                        unit = lower(obj.BinWidthUnitsDD.Items{idx});
                        extraMsgInputs = {num unit};
                        % otherwise binEdgesInPlace, no extraMsgInputs
                end
                obj.PopoutGrid.Tooltip = string(message(['MATLAB:tableui:groupingBinningTooltip' scheme],obj.VariableName,extraMsgInputs{:}));

                % set dynamic tooltip on icon
                if isequal(obj.Value,'"none"')
                    obj.Icon.Tooltip = string(message('MATLAB:tableui:groupingBinningIconTooltipNone',obj.VariableName));
                else
                    obj.Icon.Tooltip = string(message('MATLAB:tableui:groupingBinningIconTooltipBinned',obj.VariableName));
                end
            end
            % Hide the entire component if there is no binning to be done
            % (for example, Variable is categorical or string)
            obj.Visible = obj.VariableIsBinnable;
        end
    end

    methods (Access=private)
        function updateAndThrowValueChanged(obj,~,~)
            % callback for components within the popout
            update(obj);
            notify(obj,'ValueChanged');
        end

        function handleEditable(obj,src,ev)
            % Callback for timebindd, which has lots of options for
            % datetimes
            if ev.Edited
                % The dropdown's Editable property is on, and the user has
                % typed something that is not in the dropdown Items list.
                % Revert to previous valid value
                src.Value = ev.PreviousValue;
                return
            end
            updateAndThrowValueChanged(obj);
        end

        function issupported = filterBinEdges(obj,e)
            % Filter function for the BinEdges workspace dropdown
            issupported = false;
            if isvector(e) && numel(e) >= 2
                if ismember(obj.VariableClass,{'datetime','duration'})
                    issupported = isequal(class(e),obj.VariableClass) && issorted(e,'strictascend');
                else % VariableClass is numeric
                    issupported = isnumeric(e) && isreal(e) && issorted(e,'strictascend');
                end
            end
        end

        function validateRowVector(obj,src,ev)
            % Callback for BinEdges Editfield.
            % We are expecting a row vector like: '[1 2 3]'
            % str2num does most of the parsing
            val = str2num(src.Value,Evaluation="restricted"); %#ok<ST2NM>
            if isempty(val)
                % try again in case user has missed only one of the brackets
                % if missed both brackets, str2num can handle it
                val = strip(src.Value);
                if ~isempty(val)
                    if ~isequal(val(1),'[')
                        val = ['[' val];
                    elseif ~isequal(val(end),']')
                        val = [val ']'];
                    end
                end
                val = str2num(val,Evaluation="restricted"); %#ok<ST2NM>
                if isempty(val)
                    % still not a good value
                    % revert to previous good value
                    src.Value = ev.PreviousValue;
                    return
                end
            end
            % reshape to row vector
            val = reshape(val,1,[]);
            % sort and dedupe
            val = unique(val);
            if numel(val) < 2 || anynan(val)
                % need at least 2 values in the vector
                % revert to previous good value
                src.Value = ev.PreviousValue;
                return
            end
            % reset with desired syntax
            src.Value = mat2str(val);
            updateAndThrowValueChanged(obj);
        end
    end

    methods (Access = public)
        function resetDefaults(obj)
            % Restore default values of the binning icon with respect to
            % the most recent Variable set
            obj.BinningDropdown.Value = 'none';
            if obj.NumUnique > obj.NumUniqueLimit
                if ismember('timeBins',obj.BinningDropdown.ItemsData)
                    % time-based data
                    obj.BinningDropdown.Value = 'timeBins';
                elseif ismember('numBins',obj.BinningDropdown.ItemsData)
                    % numeric-ish data
                    obj.BinningDropdown.Value = 'numBins';
                end
            end
            obj.NumBinsSpinner.Value = 10;
            obj.TimeBinDD.Value = obj.DefaultTimeBin;
            obj.BinEdgesWSDD.Value = 'select variable';
            obj.BinWidthSpinner.Value = 10;
            if ismember(obj.DefaultTimeBin,{'day' 'year'}) && ...
                    ~isequal(obj.VariableClass,'duration')
                % caldays or calyears
                obj.BinWidthUnitsDD.Value = ['cal' obj.DefaultTimeBin 's'];
            else
                % minutes instead of minute
                obj.BinWidthUnitsDD.Value = [obj.DefaultTimeBin 's'];
            end
            obj.BinEdgesUnitsDD.Value = [obj.DefaultTimeBin 's'];
            obj.BinEdgesEditField.Value = '';
        end

        function open(obj)
            % Open the binning pop-out
            open(obj.Popout);
        end

        function delete(obj)
            % Delete the popout which may be unparented
            delete(obj.Popout);
        end
    end

    methods % public gets and sets
        function set.Variable(obj,var)
            % Var is a grouping variable (vector). We will not store this
            % variable, only some attributes. We will use these to
            % determine appropriate options and defaults.
            if isempty(var)
                % No var selected in task
                % To reset to no binning options, use a string var
                var = "";
                obj.VariableName = '';
                obj.VariableClass = '';
                obj.HasMissing = false;
                obj.NumUnique = 0;
                obj.DefaultTimeBin = 'year';
            else
                if ~matlab.internal.dataui.isValidGroupingVar(var)
                    % Error is not end-user-facing. Caller should limit
                    % what Variables are allowed.
                    error(message('MATLAB:findgroups:GroupTypeIncorrect',class(var)));
                end
                obj.VariableClass = class(var);
                obj.NumUnique = numel(unique(var(~ismissing(var))));
                obj.HasMissing = anymissing(var);
            end

            % full items lists
            binDDItemsData = {'none','numBins','binEdges','binEdgesInPlace','timeBins','binWidth'};
            timeBinDDItemsData = {'second' 'secondofminute' 'minute' 'minuteofhour' 'hour' 'hourofday' ...
                'day' 'dayofweek' 'dayname' 'dayofmonth' 'dayofyear' ...
                'week' 'weekofmonth' 'weekofyear' 'month' 'monthname' 'monthofyear' ...
                'quarter' 'quarterofyear' 'year' 'decade' 'century'};
            binWidthUnitsItemsData = {'milliseconds','seconds','minutes','hours',...
                'caldays','calweeks','calmonths','calquarters','calyears'};

            isDur = isduration(var);
            isDT = isdatetime(var);

            % trim by datatype
            if ~(isDur || isDT)
                % 'timeBins' and 'binwidth' are datetime/duration only
                binDDItemsData(5:6) = [];
            elseif isDur
                % remove options for datetime only these are listed in doc:
                timeBinDDItemsData = {'second' 'minute' 'hour' 'day' 'year'};
                % replace/remove caldur options
                binWidthUnitsItemsData([5 9]) = {'days' 'years'};
                binWidthUnitsItemsData(6:8) = [];
            end
            if  ~((isnumeric(var)&& isreal(var)) || islogical(var) || isDur || isDT) || isenum(var)
                % 'numbins', 'binedges', and 'binedgesInPlace' only valid
                % for real numeric, and duration
                binDDItemsData(2:4) = [];
            elseif isinteger(var) || islogical(var)
                % integer types, can't do 'numbins'
                binDDItemsData(2) = [];
            elseif isDT
                % datetime, can't do 'binedgesInPlace'
                binDDItemsData(4) = [];
            end

            if ~isequal(obj.Workspace,"base")
                % For use in data cleaner app
                % Do not allow workspace dropdown option
                binDDItemsData = binDDItemsData(~matches(binDDItemsData,'binEdges'));
                binDDItemsData = binDDItemsData(~matches(binDDItemsData,'binEdgesInPlace'));
            end

            % set dd items
            obj.BinningDropdown.Items = getItemsMessages(binDDItemsData);
            obj.BinningDropdown.ItemsData = binDDItemsData;
            obj.TimeBinDD.Items = getItemsMessages(timeBinDDItemsData);
            obj.TimeBinDD.ItemsData = timeBinDDItemsData;
            obj.BinWidthUnitsDD.Items = getUnitsMessages(binWidthUnitsItemsData);
            obj.BinWidthUnitsDD.ItemsData = binWidthUnitsItemsData;

            % set tooltip fo BinEdgesWSDD since we expect something
            % different based on datatype
            if isDT
                obj.BinEdgesWSDD.Tooltip = string(message('MATLAB:tableui:groupingBinEdgesTooltipDT'));
            elseif isDur
                obj.BinEdgesWSDD.Tooltip = string(message('MATLAB:tableui:groupingBinEdgesTooltipDur'));
            else
                obj.BinEdgesWSDD.Tooltip = string(message('MATLAB:tableui:groupingBinEdgesTooltip'));
            end
            obj.BinEdgesWSDD.populateVariables();

            % datetimes have many time bin options, so make the dropdown searchable
            obj.TimeBinDD.Editable = isDT;

            if isDT || isDur
                % Get smart default value for time bin based on input
                % based on range of time data
                durRange = max(var,[],"omitmissing") - min(var,[],"omitmissing");
                if durRange >= years(1) || ismissing(durRange)
                    obj.DefaultTimeBin = 'year';
                elseif durRange >= days(1)
                    obj.DefaultTimeBin = 'day';
                elseif durRange >= hours(1)
                    obj.DefaultTimeBin = 'hour';
                elseif durRange >= minutes(1)
                    obj.DefaultTimeBin = 'minute';
                else
                    obj.DefaultTimeBin = 'second';
                end
            else
                obj.DefaultTimeBin = 'year';
            end

            resetDefaults(obj);
            update(obj);
        end

        function str = get.Value(obj)
            % Value is used mainly for generated script
            str = '"none"';
            switch obj.BinningDropdown.Value
                case 'numBins'
                    str = num2str(obj.NumBinsSpinner.Value);
                case 'timeBins'
                    str = ['"' obj.TimeBinDD.Value '"'];
                case 'binEdges'
                    if ~isequal(obj.BinEdgesWSDD.Value,'select variable')
                        str = obj.BinEdgesWSDD.Value;
                    end
                case 'binEdgesInPlace'
                    if ~isempty(obj.BinEdgesEditField.Value)
                        str = obj.BinEdgesEditField.Value;
                        if obj.BinEdgesUnitsDD.Visible
                            str = [obj.BinEdgesUnitsDD.Value '(' str ')'];
                        end
                    end
                case 'binWidth'
                    str = [obj.BinWidthUnitsDD.Value '(' num2str(obj.BinWidthSpinner.Value,'%.16g') ')'];
            end
        end

        function val = get.State(obj)
            % State struct is used for serialization
            val = struct("VersionSavedFrom",obj.Version,...
                "MinCompatibleVersion",1,...
                "BinningDropdownItemsData",{obj.BinningDropdown.ItemsData},...
                "BinningDropdownValue",obj.BinningDropdown.Value,...
                "NumBinsSpinnerValue",obj.NumBinsSpinner.Value,...
                "BinEdgesWSDDValue",obj.BinEdgesWSDD.Value,...
                "BinEdgesEditFieldValue",obj.BinEdgesEditField.Value,...
                "BinEdgesUnitsDDValue",obj.BinEdgesUnitsDD.Value,...
                "TimeBinDDItemsData",{obj.TimeBinDD.ItemsData},...
                "TimeBinDDValue",obj.TimeBinDD.Value,...
                "BinWidthSpinnerValue",obj.BinWidthSpinner.Value,...
                "BinWidthUnitsDDItemsData",{obj.BinWidthUnitsDD.ItemsData},...
                "BinWidthUnitsDDValue",obj.BinWidthUnitsDD.Value,...
                "VariableName",obj.VariableName,...
                "VariableClass",obj.VariableClass,...
                "DefaultTimeBin",obj.DefaultTimeBin,...
                "NumUnique",obj.NumUnique,...
                "HasMissing",obj.HasMissing);
        end

        function set.State(obj,state)
            % State struct is used for serialization

            if obj.Version < state.MinCompatibleVersion
                % No op - saved from an incompatible future state
                return
            end
            % Controls with ItemsData and Value
            for k = ["BinningDropdown" "TimeBinDD"]
                if isfield(state,k+"ItemsData")
                    obj.(k).ItemsData = state.(k+"ItemsData");
                    obj.(k).Items = getItemsMessages(state.(k+"ItemsData"));
                    obj.(k).Value = state.(k+"Value");
                end
            end
            if isfield(state,"BinWidthUnitsDDItemsData")
                obj.BinWidthUnitsDD.ItemsData = state.BinWidthUnitsDDItemsData;
                obj.BinWidthUnitsDD.Items = getUnitsMessages(state.BinWidthUnitsDDItemsData);
                obj.BinWidthUnitsDD.Value = state.BinWidthUnitsDDValue;
            end
            % Values of Controls
            for k = ["NumBinsSpinner" "BinEdgesEditField" "BinEdgesUnitsDD" "BinWidthSpinner" "BinEdgesWSDD"]
                if isfield(state,k + "Value")
                    obj.(k).Value = state.(k+ "Value");
                end
            end
            % Properties
            for k = ["VariableName" "VariableClass" "DefaultTimeBin" "NumUnique" "HasMissing"]
                if isfield(state,k)
                    obj.(k) = state.(k);
                end
            end
            update(obj);
        end

        function tf = get.VariableIsBinnable(obj)
            % Used to determine whether to show binning controls at all

            % If the only option is "none", there are no binning options
            tf = numel(obj.BinningDropdown.Items) > 1;
        end

        function ws = get.Workspace(obj)
            % Workspace for the BinEdgesWSDD
            ws = obj.BinEdgesWSDD.Workspace;
        end

        function set.Workspace(obj,ws)
            % Workspace for the BinEdgesWSDD
            obj.BinEdgesWSDD.Workspace = ws;
        end
    end
end

function itemsMessages = getItemsMessages(items)
fcn = @(str) string(message(['MATLAB:tableui:grouping' str]));
itemsMessages = cellfun(fcn,items);
if isequal(items{1},'none')
    % different label than in ComputeByGroup since we have title for popout
    itemsMessages(1) = string(message("MATLAB:dataui:None"));
end
end
function itemsMessages = getUnitsMessages(items)
% message IDs don't have 'cal'
items = replace(items,'cal','');
% message IDs are capitalized
fcn = @(str) string(message(['MATLAB:dataui:' upper(str(1)) str(2:end)]));
itemsMessages = cellfun(fcn,items);
end
function donothing(~,~)
% Need this callback to make the pointer change on hovering over icon
end