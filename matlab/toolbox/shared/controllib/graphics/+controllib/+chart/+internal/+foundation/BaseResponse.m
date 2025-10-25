classdef BaseResponse < handle & dynamicprops & matlab.mixin.SetGet &...
        matlab.mixin.Heterogeneous & matlab.mixin.Copyable &...
        matlab.mixin.CustomDisplay & matlab.mixin.CustomElementSerialization &...
        controllib.chart.internal.foundation.MixInListeners
    % controllib.chart.internal.foundation.BaseResponse
    %   - base class for managing data and style for a response in Control charts
    %
    % h = BaseResponse()
    %
    % h = BaseResponse(Name-Value)
    %   Name            response name, string, "" (default)
    %   Tag             response tag, string, matlab.lang.internal.uuid (default)
    %   LegendDisplay   show response in legend, matlab.lang.OnOffSwitchState, true (default)
    %
    % Settable properties:
    %   Name            label for response in chart, string
    %   Visible         show response in chart, matlab.lang.OnOffSwitchState
    %   LegendDisplay   show response in legend, matlab.lang.OnOffSwitchState
    %   UserData        custom data, any MATLAB array
    %
    % Read-Only / Internal properties (for subclasses):
    %   Tag                  unique tag for indexing, string
    %   Type                 type of response for subclass, string
    %   AutoGenerateXData    logical value used to set limits focus, matlab.lang.OnOffSwitchState
    %   ArrayDim             array dimensions of ResponseData, double
    %   NResponses           number of elements in array of ResponseData, double
    %   CharacteristicTypes  characteristic types of response data, string
    %   ResponseData         data source object, controllib.chart.internal.data.response.BaseResponseDataSource
    %
    % Events:
    %   ResponseChanged      notified after update is called
    %   ResponseDeleted      notified after delete is called
    %   StyleChanged         notified after Style object is changed
    %
    % Public methods:
    %   build(this)
    %       Creates the response data. Can call in subclass
    %       constructor to build on instantiation.
    %   update(this,Name-Value)
    %       Update the response data with new parameter values.
    %
    % Protected methods (to override in subclass):
    %   initializeData(this)
    %       Create the response data. Called in build().
    %   updateData(this,Name-Value)
    %       Update the response data. Called in update().

    % Copyright 2022-2024 The MathWorks, Inc.

    %% Properties
    properties (Dependent,AbortSet, SetObservable)
        % "Name": string scalar
        % Assign label to response. Used to denote response in legend
        % and menus. Uses "" by defeault, which appears as "untitledx" 
        % in legend and menus.
        Name (1,1) string

        % "Visible": 'on' (default)|'off'   scalar
        % Set the visibility of all graphics objects (response lines,
        % characteristic markers) related to the response.
        Visible (1,1) matlab.lang.OnOffSwitchState

        % "LegendDisplay": 'on' (default)|'off'   scalar
        % Set the visibility of response on the chart legend object.
        LegendDisplay (1,1) matlab.lang.OnOffSwitchState
    end

    properties (Hidden,SetAccess = private,Transient,NonCopyable)
        % "Tag": string scalar
        % Assign a Tag used to search and index. Uses a uniquely
        % generated id by default.
        Tag (1,1) string
    end

    properties (Hidden,SetAccess = protected)
        % "Type": string scalar
        % Type of response defined by subclass.
        Type (1,1) string = "base"

        % "AutoGenerateXData": matlab.lang.OnOffSwitchState scalar
        % Automatically set limit focus for response data.
        AutoGenerateXData (1,1) matlab.lang.OnOffSwitchState = true
    end

    properties (Hidden, AbortSet, SetObservable)
        % "ArrayVisible": 'on' (default)|'off'    size of ArrayDim
        % Set the visibility of individual elements of a response for an LTI
        % model array
        ArrayVisible matlab.lang.OnOffSwitchState = true

        % "NominalIndex": double
        NominalIndex double {mustBeScalarOrEmpty,mustBeInteger,mustBePositive} = []

        % "Selected": 'on' | 'off' (default)  indicates whether related
        % graphics objects in ResponseView are selected.
        Selected (1,1) matlab.lang.OnOffSwitchState = false
    end

    properties (Hidden, AbortSet, SetObservable, NonCopyable)
        % "Style": controllib.chart.internal.options.ResponseStyle
        % Set the style (color, line style, line width, marker type, marker
        % size, marker color) for the graphics objects related to response.
        Style controllib.chart.internal.options.ResponseStyle {mustBeScalarOrEmpty} = controllib.chart.internal.options.ResponseStyle.empty
    end

    properties (Hidden,Dependent)
        % "MenuDisplay": 'on' (default)|'off'   scalar
        % Set the visibility of the context menu item
        VisibleMenuDisplay matlab.lang.OnOffSwitchState
    end

    properties(Hidden,SetAccess=private)
        % "DataTipInfo"
        % Custom data for data tip, typically from SamplingGrid.
        DataTipInfo cell
    end

    properties(Hidden,SetAccess=private,NonCopyable)
        % "DynamicProperties"
        % List of all dynamic properties added to response
        DynamicProperties
    end

    properties (Hidden,Dependent,SetAccess=private)
        % "ArrayDim": double array
        % Dimensions of the response data.
        ArrayDim

        % "NResponses": double scalar
        % Number of elements of the response data.
        NResponses

        % "CharacteristicTypes": string array
        % Characteristic types associated with response data.
        CharacteristicTypes

        % "DataException"
        % Data exception state for response data.
        DataException
    end

    properties (Access=protected,Transient,NonCopyable)
        SavedValues
    end

    properties (Access = {?controllib.chart.internal.foundation.BaseResponse,...
            ?controllib.chart.internal.foundation.AbstractPlot,...
            ?controllib.chart.internal.view.wave.BaseResponseView,...
            ?controllib.chart.internal.view.wave.data.ResponseWrapper,...
            ?controllib.chart.internal.view.axes.BaseAxesView,...
            ?controllib.chart.internal.view.characteristic.BaseCharacteristicView,...
            ?matlab.unittest.TestCase},Transient,NonCopyable)
        % "ResponseData": controllib.chart.internal.data.response.BaseResponseDataSource
        % Assign in method "initializeData". Object that creates and
        % updates all response and characteristic data for the response.
        ResponseData controllib.chart.internal.data.response.BaseResponseDataSource {mustBeScalarOrEmpty} = controllib.chart.internal.data.response.BaseResponseDataSource.empty
    end

    properties (Hidden,GetObservable,SetObservable)
        % "UserData"
        % Custom data associated with response.
        UserData

        % "IsDirty"
        IsDirty logical

        % "ShowInView"
        % Hide response lines, remove response from legend object and
        % context menu
        ShowInView matlab.lang.OnOffSwitchState = matlab.lang.OnOffSwitchState(true)
    end

    properties (GetAccess=protected,SetAccess=private)
		Version = matlabRelease
        Name_I
        Visible_I
        LegendDisplay_I
        VisibleMenuDisplay_I = true
    end

    properties (Access = protected, Transient, NonCopyable)
        VisibleMenu
    end

    properties (Hidden,GetAccess=private,SetAccess={?controllib.chart.internal.foundation.AbstractPlot})
        IsParentedToChart logical = false
        IsChartUpdatingResponse logical = false
    end

    properties (Hidden,SetAccess = ?controllib.chart.internal.foundation.AbstractPlot,Transient,NonCopyable)
        DataExceptionMessage (1,1) string {mustBeMember(DataExceptionMessage,["error","warning","none"])} = "error"
    end

    %% Events
    events
        ResponseChanged
        ResponseDeleted
        StyleChanged
        DataExceptionOnUpdate
    end

    %% Constructor/destructor
    methods
        function this = BaseResponse(optionalInputs)
            arguments
                optionalInputs.Name (1,1) string = ""
                optionalInputs.Style (1,1) controllib.chart.internal.options.ResponseStyle = controllib.chart.internal.options.ResponseStyle()
                optionalInputs.Visible (1,1) matlab.lang.OnOffSwitchState = true;
                optionalInputs.LegendDisplay (1,1) matlab.lang.OnOffSwitchState = true;
            end
            this.Tag = matlab.lang.internal.uuid;
            this.DynamicProperties = string.empty;
            L1 = addlistener(this,'PropertyAdded',@(es,ed) addDynamicProperty(this,ed.PropertyName));
            L2 = addlistener(this,'PropertyRemoved',@(es,ed) removeDynamicProperty(this,ed.PropertyName));
            registerListeners(this,[L1;L2],["DynamicPropertyAddedListener";"DynamicPropertyRemovedListener"])
            this.Name = optionalInputs.Name;
            this.Style = optionalInputs.Style;
            this.LegendDisplay = optionalInputs.LegendDisplay;
            this.Visible = optionalInputs.Visible;
        end

        function delete(this)
            delete@controllib.chart.internal.foundation.MixInListeners(this);
            delete(this.ResponseData);
            delete(this.VisibleMenu);
            delete(this.Style);
            notify(this,"ResponseDeleted");
        end
    end

    %% Sealed methods
    methods (Sealed, Hidden)
        function build(this)
            arguments
                this (1,1) controllib.chart.internal.foundation.BaseResponse
            end
            try
                initializeData(this);
                this.IsDirty = false;
            catch ME
                throw(ME)
            end
            this.ArrayVisible = true(this.ArrayDim);
        end

        function update(this,varargin)
            arguments
                this (1,1) controllib.chart.internal.foundation.BaseResponse
            end
            arguments (Repeating)
                varargin 
            end

            if (this.IsParentedToChart && this.IsChartUpdatingResponse && this.IsDirty) || ...
                    ~this.IsParentedToChart
                try
                    updateData(this,varargin{:});
                    this.IsDirty = false;
                catch ME
                    throw(ME)
                end
                notify(this,'ResponseChanged');
                if ~isempty(this.DataException)
                    if ~strcmp(this.DataExceptionMessage,"none") % update only throws warning
                        warning(this.DataException.identifier,'%s',this.DataException.message);
                    end
                    data.DataException = this.DataException;
                    ed = controllib.chart.internal.utils.GenericEventData(data);
                    notify(this,"DataExceptionOnUpdate",ed);
                end
            end
        end
    end

    %% Get/Set
    methods        
        % Name
        function Name = get.Name(this)
            Name = this.Name_I;
        end

        function set.Name(this,Name)
            arguments
                this (1,1) controllib.chart.internal.foundation.BaseResponse
                Name (1,1) string
            end
            this.Name_I = Name;
            if ~isempty(this.VisibleMenu)
                this.VisibleMenu.Text = Name;
            end
        end

        % Visible
        function Visible = get.Visible(this)
            Visible = this.Visible_I;
        end

        function set.Visible(this,Visible)
            arguments
                this (1,1) controllib.chart.internal.foundation.BaseResponse
                Visible (1,1) matlab.lang.OnOffSwitchState
            end
            this.Visible_I = Visible;
            if ~isempty(this.VisibleMenu)
                this.VisibleMenu.Checked = Visible;
            end
        end

        % LegendDisplay
        function LegendDisplay = get.LegendDisplay(this)
            LegendDisplay = this.LegendDisplay_I;
        end

        function set.LegendDisplay(this,LegendDisplay)
            arguments
                this (1,1) controllib.chart.internal.foundation.BaseResponse
                LegendDisplay (1,1) matlab.lang.OnOffSwitchState
            end
            this.LegendDisplay_I = LegendDisplay;
        end

        % Style
        function set.Style(this,Style)
            arguments
                this (1,1) controllib.chart.internal.foundation.BaseResponse
                Style (1,1) controllib.chart.internal.options.ResponseStyle
            end
            % Set Style. Re-initialize listener. Notify of 'StyleChanged'.
            this.Style = Style;
            initializeStyleProperties(this);
            notify(this,'StyleChanged');
        end

        % ArrayDim
        function ArrayDim = get.ArrayDim(this)
            if isempty(this.ResponseData)
                ArrayDim = 1;
            else
                ArrayDim = this.ResponseData.ArrayDim;
            end
        end

        % NResponses
        function NResponses = get.NResponses(this)
            if isempty(this.ResponseData)
                NResponses = 1;
            else
                NResponses = this.ResponseData.NResponses;
            end
        end
        
        % ArrayVisible
        function set.ArrayVisible(this,ArrayVisible)
            arguments
                this (1,1) controllib.chart.internal.foundation.BaseResponse
                ArrayVisible matlab.lang.OnOffSwitchState {validateArrayVisibleSize(this,ArrayVisible)}
            end
            this.ArrayVisible = ArrayVisible;
        end

        % CharacteristicTypes
        function CharacteristicTypes = get.CharacteristicTypes(this)
            arguments
                this (1,1) controllib.chart.internal.foundation.BaseResponse
            end
            if isempty(this.ResponseData)
                CharacteristicTypes = string.empty;
            else
                CharacteristicTypes = this.ResponseData.CharacteristicTypes;
            end
        end

        % DataException
        function DataException = get.DataException(this)
            if isempty(this.ResponseData)
                DataException = MException.empty;
            else
                DataException = this.ResponseData.DataException;
            end
        end

        % MenuDisplay
        function MenuDisplay = get.VisibleMenuDisplay(this)
            MenuDisplay = matlab.lang.OnOffSwitchState(this.VisibleMenuDisplay_I);
        end

        function set.VisibleMenuDisplay(this,MenuDisplay)
            arguments
                this controllib.chart.internal.foundation.BaseResponse
                MenuDisplay (1,1) matlab.lang.OnOffSwitchState
            end
            
            this.VisibleMenuDisplay_I = MenuDisplay;
            if ~isempty(this.VisibleMenu) && isvalid(this.VisibleMenu)
                this.VisibleMenu.Visible = MenuDisplay;
            end
        end

        % ShowInView
        function set.ShowInView(this,ShowInView)
            if ShowInView
                showInView(this);
            else
                hideInView(this);
            end 
            this.ShowInView = ShowInView;
        end
    end
    
    %% Get/Set dynamic props
    methods (Access=private)
        function value = getStyleProp(this,prop)
            value = this.Style.(prop);
        end
        function setStyleProp(this,newValue,prop)
            try
                this.Style.(prop) = newValue;
            catch ME
                throw(ME)
            end
        end
    end

    %% Static methods
    methods (Static)
        function modifyIncomingSerializationContent(thisSerialized)
            if ~thisSerialized.hasNameValue("Version") %24b
                thisSerialized.rename("Name","Name_I");
                thisSerialized.rename("Visible","Visible_I");
                thisSerialized.rename("LegendDisplay","LegendDisplay_I");
            end
        end

        function this = finalizeIncomingObject(this)
            this.Tag = matlab.lang.internal.uuid;
            this.Version = matlabRelease;
            initializeData(this);
        end

        function modifyOutgoingSerializationContent(thisSerialized,this)
            thisSerialized.addNameValue('SavedValues',this.SavedValues);
            this.SavedValues = [];
        end
    end

    %% Protected methods (override in subclass)
    methods (Access = protected)
        function initializeData(this) %#ok<MANU>
            % "initializeData(this)":
            % Called in base class constructor. Overload in sub class to
            % initialize all related data objects.
        end

        function updateData(this,varargin) %#ok<INUSD>
        end

        function initializeStyleProperties(this)
            unregisterListeners(this,"StyleChangedListener")
            L = addlistener(this.Style,'ResponseStyleChanged',@(es,ed) notify(this,'StyleChanged'));
            registerListeners(this,L,"StyleChangedListener")
            allProps = properties(this.Style);
            allProps = [allProps;{'SemanticColor'};{'SemanticFaceColor'};{'SemanticEdgeColor'}];
            for ii = 1:length(allProps)
                p = findprop(this,allProps{ii});
                if ~isempty(p)
                    delete(p);
                end
            end
            [props,hiddenProps] = this.getStyleProperties();
            for ii = 1:length(props)
                p = addprop(this,props(ii));
                p.Dependent = true;
                p.AbortSet = true;
                p.SetObservable = true;
                p.GetMethod = @(this) getStyleProp(this,props(ii));
                p.SetMethod = @(this,newVal) setStyleProp(this,newVal,props(ii));
            end
            for ii = 1:length(hiddenProps)
                p = addprop(this,hiddenProps(ii));
                p.Dependent = true;
                p.AbortSet = true;
                p.SetObservable = true;
                p.Hidden = true;
                p.GetMethod = @(this) getStyleProp(this,hiddenProps(ii));
                p.SetMethod = @(this,newVal) setStyleProp(this,newVal,hiddenProps(ii));
            end
        end

        function thisCopy = copyElement(this)
            thisCopy = copyElement@matlab.mixin.Copyable(this);
            L1 = addlistener(thisCopy,'PropertyAdded',@(es,ed) addDynamicProperty(thisCopy,ed.PropertyName));
            L2 = addlistener(thisCopy,'PropertyRemoved',@(es,ed) removeDynamicProperty(thisCopy,ed.PropertyName));
            registerListeners(thisCopy,[L1;L2],["DynamicPropertyAddedListener";"DynamicPropertyRemovedListener"])
            thisCopy.Tag = matlab.lang.internal.uuid;
            thisCopy.ResponseData = copy(this.ResponseData);
            thisCopy.Style = copy(this.Style);
        end
    end

    methods (Hidden,Access={?controllib.chart.internal.foundation.BaseResponse,...
            ?controllib.chart.internal.foundation.AbstractPlot})
        function addVisibleMenu(this,responsesMenu)
            arguments
                this (1,1) controllib.chart.internal.foundation.BaseResponse
                responsesMenu (1,1) matlab.ui.container.Menu
            end
            % Add menu to toggle visibility if MenuDisplay is true
            if this.VisibleMenuDisplay
                this.VisibleMenu = uimenu(responsesMenu,"Text",this.Name,...
                    "MenuSelectedFcn",@(es,ed) cbVisibleMenuSelected(this,es),...
                    "Checked",this.Visible,"Visible",this.VisibleMenuDisplay);
            end
        end
    end

    %% Protected sealed methods
    methods (Access = protected, Sealed)
        function setDataTipInfo(this,dataTipInfoStruct,ko,ki,ka)
            arguments
                this (1,1) controllib.chart.internal.foundation.BaseResponse
                dataTipInfoStruct (1,1) struct
                ko (1,1) double
                ki (1,1) double
                ka (1,1) double
            end
            this.DataTipInfo{ka}(ko,ki) = dataTipInfoStruct;
        end

        function clearDataTipInfo(this)
            this.DataTipInfo = [];
        end

        function markDirtyAndUpdate(this)
            this.IsDirty = true;
            update(this);
        end  

        function displayNonScalarObject(this)
            header = getHeader(this);
            for ii = 1:length(this)
                className = matlab.mixin.CustomDisplay.getClassNameForHeader(this(ii));
                className = char(extractBetween(string(className),">","<"));
                if this(ii).Name ~= ""
                    header = [header '  ' className '    (' char(this(ii).Name) ')' newline]; %#ok<AGROW>
                else
                    header = [header '  ' className newline]; %#ok<AGROW>
                end
            end
            disp(header)
        end

        function header = getHeader(this)
            if isempty(this)
                dims = matlab.mixin.CustomDisplay.convertDimensionsToString(this);
                className = matlab.mixin.CustomDisplay.getClassNameForHeader(this);
                header = ['  ' dims ' empty ' className ' array.' newline newline];                
            elseif ~isscalar(this)
                dims = matlab.mixin.CustomDisplay.convertDimensionsToString(this);
                className = matlab.mixin.CustomDisplay.getClassNameForHeader(this);
                header = ['  ' dims ' ' className ' array:' newline newline];
            else
                header = matlab.mixin.CustomDisplay.getSimpleHeader(this);
                if this.Name ~= ""
                    k = strfind(header,'</a>')+3;
                    header = [header(1:k) ' (' char(this.Name) ')' header(k+1:end)];
                end
            end
        end

        function propertyGroups = getPropertyGroups(this)
            if ~isscalar(this)
                propertyGroups = matlab.mixin.util.PropertyGroup.empty;
            else
                if isempty(this.getDataProperties())
                    dataPropertyGroup = matlab.mixin.util.PropertyGroup.empty;
                else
                    dataPropertyGroup = matlab.mixin.util.PropertyGroup(this.getDataProperties());
                end
                if isempty(this.getResponseProperties())
                    responsePropertyGroup = matlab.mixin.util.PropertyGroup.empty;
                else
                    responsePropertyGroup = matlab.mixin.util.PropertyGroup(this.getResponseProperties());
                end
                if isempty(this.getStyleProperties())
                    stylePropertyGroup = matlab.mixin.util.PropertyGroup.empty;
                else
                    stylePropertyGroup = matlab.mixin.util.PropertyGroup(this.getStyleProperties());
                end

                propertyGroups = [dataPropertyGroup responsePropertyGroup stylePropertyGroup];
            end
        end
    end
    
    %% Private methods
    methods (Access = private)
        function cbVisibleMenuSelected(this,es)
            this.Visible = ~this.Visible;
            es.Checked = this.Visible;
        end

        function validateArrayVisibleSize(this,value)
            if ~isempty(this.ResponseData)
                controllib.chart.internal.utils.validators.mustBeSize(value,this.ArrayDim);
            end
        end

        function addDynamicProperty(this,name)
            this.DynamicProperties = [this.DynamicProperties;string(name)];
        end

        function removeDynamicProperty(this,name)
            this.DynamicProperties = this.DynamicProperties(this.DynamicProperties~=string(name));
        end

        function showInView(this)
            this.VisibleMenu.Visible = this.VisibleMenuDisplay;
        end

        function hideInView(this)
            this.VisibleMenu.Visible = 'off';
        end
    end

    %% Hidden methods (access to test)
    methods (Hidden)
        function data = qeGetData(this)
            data = this.ResponseData;
        end
        function registerData(this,data)
            this.ResponseData = data;
        end
        function registerCharacteristic(this,characteristic)
            registerCharacteristic(this.ResponseData,characteristic);
        end
    end

    %% Hidden static methods
    methods (Hidden,Static)
        function dataProperties = getDataProperties()
            dataProperties = string.empty;
        end

        function responseProperties = getResponseProperties()
            responseProperties = ["Name" "Visible" "LegendDisplay"];
        end

        function [styleProperties,hiddenStyleProperties] = getStyleProperties()
            styleProperties = ["Color","LineStyle","MarkerStyle","LineWidth","MarkerSize"];
            hiddenStyleProperties = "SemanticColor";
        end
    end
end