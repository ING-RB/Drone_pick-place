classdef (ConstructOnLoad, UseClassDefaultsOnLoad, AllowedSubclasses=?hTestBubbleCloud)...
        BubbleCloud < matlab.graphics.chartcontainer.ChartContainer
    %

    %   Copyright 2020-2024 The MathWorks, Inc.

    properties (Dependent, UsedInUpdate=false, Resettable=false)
        SizeData (1,:)
        LabelData (1,:)
        GroupData (1,:)

        SourceTable = table.empty()
        SizeVariable = ''
        LabelVariable = ''
        GroupVariable = ''

        FontColor = [0 0 0]
        FontName matlab.internal.datatype.matlab.graphics.datatype.FontName = get(groot, 'FactoryAxesFontName')
        FontSize matlab.internal.datatype.matlab.graphics.datatype.Positive = get(groot, 'FactoryAxesFontSize')

        FaceColor matlab.internal.datatype.matlab.graphics.datatype.RGBFlatNoneColor = 'flat'
        EdgeColor matlab.internal.datatype.matlab.graphics.datatype.RGBFlatNoneColor = [0 0 0]
        ColorOrder matlab.internal.datatype.matlab.graphics.datatype.ColorOrder  = get(groot,'FactoryAxesColorOrder')

        FaceAlpha matlab.internal.datatype.matlab.graphics.datatype.ZeroToOne = 0.6

        Title matlab.internal.datatype.matlab.graphics.datatype.NumericOrString = ''

        LegendTitle = ''
        LegendVisible matlab.lang.OnOffSwitchState = matlab.lang.OnOffSwitchState.off
        
        MaxDisplayBubbles = 1000
    end

    properties (UsedInUpdate=false, Hidden, Transient, NonCopyable, AbortSet)
        FontColor_I matlab.internal.datatype.matlab.graphics.datatype.RGBAColor = [0 0 0]
    end

    properties (UsedInUpdate=false, Access=protected, Transient, NonCopyable)
        FontName_I matlab.internal.datatype.matlab.graphics.datatype.FontName = get(groot, 'FactoryAxesFontName')
    end

    properties (Access=protected, Transient, NonCopyable)
        FontSize_I matlab.internal.datatype.matlab.graphics.datatype.Positive = get(groot, 'FactoryAxesFontSize')
        Title_I matlab.internal.datatype.matlab.graphics.datatype.NumericOrString = ''
    end

    properties(Hidden, Transient, NonCopyable, AbortSet)
        EdgeColor_I matlab.internal.datatype.matlab.graphics.datatype.RGBFlatNoneColor = [0 0 0]
        ColorOrder_I matlab.internal.datatype.matlab.graphics.datatype.ColorOrder = get(groot,'FactoryAxesColorOrder')
    end
    
    properties (Access=private, Transient, NonCopyable)
        SizeData_I (1,:) = []
        LabelData_I (1,:) = string.empty(0,1)
        GroupData_I (1,:) = []

        SourceTable_I tabular = table.empty()
        SizeVariable_I = ''
        LabelVariable_I = ''
        GroupVariable_I = ''

        FaceColor_I matlab.internal.datatype.matlab.graphics.datatype.RGBFlatNoneColor = 'flat'
        FaceAlpha_I matlab.internal.datatype.matlab.graphics.datatype.ZeroToOne = 0.6

        LegendTitle_I matlab.internal.datatype.matlab.graphics.datatype.NumericOrString = ''
        LegendVisible_I matlab.lang.OnOffSwitchState = matlab.lang.OnOffSwitchState.off
        
        MaxDisplayBubbles_I=1000

        LayoutDirty=true
        RadiiDirty=true
        LabelsDirty=true
        ColorsDirty=true

        AspectRatio

        InnerPositionCache (1,4) double = nan(1,4)
        LimitsCache (1,4) double = nan(1,4)
    end

    properties (Transient, NonCopyable, UsedInUpdate=false, ...
            Access={?tBubbleCloudObject, ?tBubbleCloudInteractions})
        Axes matlab.graphics.axis.Axes
        Marker matlab.graphics.primitive.world.Marker
        Text matlab.graphics.primitive.world.Text
        Legend matlab.graphics.illustration.Legend
        LegendScatters matlab.graphics.chart.primitive.Scatter
        HighlightMarker matlab.graphics.primitive.world.Marker
        Datatip matlab.graphics.shape.internal.GraphicsTip

        XYR (3,:) double = zeros(3,0)
        RadiusIndex (1,:) double = []

        LabelStrings (1,:) string = string.empty(0,1)
        LabelNChars (1,:) double = []

        Linger
        LingerListeners
        SelectedMarkerIndex=nan

        SizeVariableName
        LabelVariableName
        GroupVariableName
    end

    properties (Hidden, Transient, NonCopyable)
        SizeDataMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
        LabelDataMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
        GroupDataMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'

        SourceTableMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
        SizeVariableMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
        LabelVariableMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
        GroupVariableMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'

        TitleMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'

        FaceColorMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
        EdgeColorMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
        FaceAlphaMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
        ColorOrderMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'

        LegendVisibleMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
        LegendTitleMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
        
        FontColorMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
        FontSizeMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
        FontNameMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
        
        MaxDisplayBubblesMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
    end
    
    properties (Access=protected)
        DataStorage
    end

    properties (Dependent, Hidden, Access=?tBubbleCloudObject)
        UsingTableForData
        NotUsingTableForData
    end
    
    properties (Transient, NonCopyable, Access=protected, AbortSet)
        FigureAncestorForPlotEditListener
        PlotEditListener
    end

    % Methods implemented in separate files:
    methods (Access = protected, Hidden)
        setup(obj)
        update(obj)
        setMarkerVertices(obj)
        setMarkerSize(obj)
        setAxesLimits(obj)
        setMarkerColor(obj)
        setLegendScatters(obj,groupnames,cdata,mfc,mec)
        computeRadii(obj)
        layoutBubbles(obj)
        setTextStringsAndVertices(obj)
        aspectratio=computeAspectRatio(obj)
        changeChartPosition(obj)
        setupLingerListeners(obj)
        LingerEvent(obj,eventdata)
        str=getDatatipString(obj,dataind,labelColor,valueColor)
        deserialize(obj,data)
        data=serialize(obj)
    end
    
    % Codegen methods
    methods (Access = public, Hidden)
        function tf = mcodeIgnoreHandle(~,~)
            % Enable code generation
            tf=false;
        end
        mcodeConstructor(obj,code)
    end
    % Overrides of charting methods
    methods (Access = protected, Hidden)
        function t = getTypeName(~)
            % set package-free type
            t='bubblecloud';
        end
        function tf = useGcaBehavior(~)
            tf = false;
        end
        function groups =  getPropertyGroups(obj)
            if obj.UsingTableForData
                groups = matlab.mixin.util.PropertyGroup( ...
                    {'SourceTable','SizeVariable','LabelVariable','GroupVariable'});
            else
                groups = matlab.mixin.util.PropertyGroup( ...
                    {'SizeData','LabelData','GroupData'});
            end
        end
    end
    
    % Theme method override
    methods (Access = protected, Static)
        function map = getThemeMap
            %             BubbleCloud Prop   Theme Attribute
            map = struct('EdgeColor',        '--mw-graphics-colorNeutral-line-secondary',...
                         'FontColor',        '--mw-color-primary',...
                         'ColorOrder',       'DiscreteColorList');
        end
    end

    % setters and getters
    methods
        function set.SizeData(obj,sz)
            % Note that setting SizeData checks NotUsingTableForData
            % instead of UsingTableForData. This is because switch from
            % table to vector workflows is allowed when SourceTable has a 
            % width of zero, necessary for initial set of SizeData when
            % mode is still auto.
            vectorMode = obj.NotUsingTableForData;
            assert(vectorMode, message('MATLAB:graphics:bubblecloud:TableWorkflow', 'SizeData'));
            
            err=validateSizeData(sz);
            if ~isempty(err)
                throwAsCaller(err)
            end

            obj.SizeVariable_I='';
            obj.SizeDataMode='manual';
            obj.SizeData_I=sz;
        end
        function set.LabelData(obj,lbl)
            % Note that setting LabelData checks NotUsingTableForData
            % instead of UsingTableForData. This is because switch from
            % table to vector workflows is allowed when SourceTable has a 
            % width of zero, necessary for initial set of SizeData when
            % mode is still auto.
            vectorMode = obj.NotUsingTableForData;
            assert(vectorMode, message('MATLAB:graphics:bubblecloud:TableWorkflow', 'LabelData'));
            
            err=validateLabelData(lbl);
            if ~isempty(err)
                throwAsCaller(err);
            end
            obj.LabelDataMode='manual';
            obj.LabelVariable_I='';
            obj.LabelData_I=lbl;
        end
        function set.GroupData(obj,gp)
            % Note that setting GroupData checks NotUsingTableForData
            % instead of UsingTableForData. This is because switch from
            % table to vector workflows is allowed when SourceTable has a 
            % width of zero, necessary for initial set of SizeData when
            % mode is still auto.
            vectorMode = obj.NotUsingTableForData;
            assert(vectorMode, message('MATLAB:graphics:bubblecloud:TableWorkflow', 'GroupData'));
            
            err=validateGroupData(gp);
            if ~isempty(err)
                throwAsCaller(err)
            end
            obj.GroupDataMode='manual';
            obj.GroupVariable_I='';
            obj.GroupData_I=gp;
        end
        function set.SourceTable(obj,tbl)
            % Validate each table variable. Don't set data properties or
            % store the SourceTable unless all used variables are valid.
            assert(obj.UsingTableForData, message('MATLAB:graphics:bubblecloud:VectorWorkflow', 'SourceTable'));

            [err,~,sz,szvarname]=validateTableVar(tbl, obj.SizeVariable, 'SizeVariable', @validateSizeData);
            if ~isempty(err)
                throwAsCaller(err);
            end

            [err,~,lbl,lblvarname]=validateTableVar(tbl, obj.LabelVariable, 'LabelVariable', @validateLabelData);
            if ~isempty(err)
                throwAsCaller(err);
            end

            [err,~,gp,gpvarname]=validateTableVar(tbl, obj.GroupVariable, 'GroupVariable', @validateGroupData);
            if ~isempty(err)
                throwAsCaller(err);
            end

            obj.SourceTable_I=tbl;
            obj.SourceTableMode='manual';
            if ~isempty(obj.SizeVariable)
                obj.SizeData_I=sz;
                obj.SizeVariableName=szvarname;
            end
            if ~isempty(obj.LabelVariable)
                obj.LabelData_I=lbl;
                obj.LabelVariableName=lblvarname;
            end
            if ~isempty(obj.GroupVariable)
                obj.GroupData_I=gp;
                obj.GroupVariableName=gpvarname;
            end
        end
        function set.SizeVariable(obj,var)
            assert(obj.UsingTableForData, message('MATLAB:graphics:bubblecloud:VectorWorkflow', 'SizeVariable'));
            
            [err,var,val,varname]=validateTableVar(obj.SourceTable_I, var, 'SizeVariable', @validateSizeData);
            if ~isempty(err)
                throwAsCaller(err)
            end

            obj.SizeData_I = val;
            obj.SizeVariable_I = var;
            obj.SizeVariableMode = 'manual';
            obj.SizeVariableName = varname;
            obj.SizeDataMode = 'auto';
        end
        function set.LabelVariable(obj,var)
            assert(obj.UsingTableForData, message('MATLAB:graphics:bubblecloud:VectorWorkflow', 'LabelVariable'));

            [err,var,val,varname]=validateTableVar(obj.SourceTable_I, var, 'LabelVariable', @validateLabelData);
            if ~isempty(err)
                throwAsCaller(err)
            end

            obj.LabelData_I=val;
            obj.LabelVariable_I = var;
            obj.LabelVariableMode = 'manual';
            obj.LabelVariableName = varname;
            obj.LabelDataMode = 'auto';
        end
        function set.GroupVariable(obj,var)
            assert(obj.UsingTableForData, message('MATLAB:graphics:bubblecloud:VectorWorkflow', 'GroupVariable'));
            
            [err,var,val,varname]=validateTableVar(obj.SourceTable_I, var, 'GroupVariable', @validateGroupData);
            if ~isempty(err)
                throwAsCaller(err)
            end

            obj.GroupData_I=val;
            obj.GroupVariable_I = var;
            obj.GroupVariableMode = 'manual';
            obj.GroupVariableName = varname;
            obj.GroupDataMode = 'auto';
        end
        function set.SizeData_I(obj,sz)
            % Store (already validated) size data
            obj.SizeData_I = sz;
            obj.RadiiDirty = true;
        end
        function set.GroupData_I(obj,gp)
            % Store (already validated) group data
            obj.GroupData_I = gp;
            obj.LayoutDirty = true;
            obj.ColorsDirty=true;
        end
        function set.LabelData_I(obj,lbl)
            % Store (already validated) label data
            obj.LabelData_I = lbl;
            if isempty(lbl)
                obj.LabelStrings = string.empty;
                obj.LabelNChars = [];
                obj.LabelsDirty = true;
                return
            end

            obj.LabelStrings = string(lbl);
            obj.LabelNChars = strlength(obj.LabelStrings);

            obj.LabelsDirty = true;
        end

        function set.FontColor(obj,clr)
            % This won't cause an update, just change the color on the
            % underlying text primitive.
            try
                clr=validatecolor(clr,'one');
            catch me
                if isequal(me.identifier,'MATLAB:graphics:validatecolor:MultipleColors')
                    throwAsCaller(MException(message('MATLAB:datatypes:RGBAColor:ValueMustBe3or4ElementVector')))
                else
                    throwAsCaller(me)
                end
            end
            obj.FontColor_I=clr(1:3);
            obj.FontColorMode='manual';
        end
        
        function set.FontColor_I(obj,clr)
            obj.FontColor_I=clr;
            obj.Text.ColorData=uint8([clr*255 255]');
        end

        function set.FontName(obj,fontname)
            % This won't cause an update, just change the name on the
            % underlying text primitive.
            obj.FontName_I=fontname;
            obj.FontNameMode='manual';
            font=matlab.graphics.general.Font('Name',obj.FontName,'Size',obj.FontSize);
            obj.Text.Font=font;
        end
        function set.FontSize(obj,fontsize)
            % This needs to update the contents of labels which may be
            % trimmed differently at the new size.
            obj.FontSize_I=fontsize;
            obj.FontSizeMode='manual';
            font=matlab.graphics.general.Font('Name',obj.FontName,'Size',obj.FontSize);
            obj.Text.Font=font;
            obj.LabelsDirty = true;
        end
        function set.Title(obj,str)
            obj.Title_I=str;
            obj.TitleMode='manual';
        end
        function set.Title_I(obj,str)
            obj.Axes.Title.String_I = str; %#ok<MCSUP> 
            obj.Title_I=str;
        end

        function set.FaceColor(obj,clr)
            obj.FaceColor_I=clr;
            obj.FaceColorMode='manual';
            obj.ColorsDirty=true;
        end

        function set.EdgeColor(obj,clr)
            obj.EdgeColor_I=clr;
            obj.EdgeColorMode='manual';
        end

        function set.EdgeColor_I(obj,clr)
            obj.EdgeColor_I=clr;
            obj.ColorsDirty=true;
        end

        function set.ColorOrder(obj,clrs)
            obj.ColorOrder_I=clrs;
            obj.ColorOrderMode='manual';
        end

        function set.ColorOrder_I(obj,clrs)
            obj.ColorOrder_I=clrs;
            obj.ColorsDirty=true;
        end

        function set.FaceAlpha(obj,alp)
            obj.FaceAlpha_I=alp;
            obj.FaceAlphaMode='manual';
            obj.ColorsDirty=true;
        end

        function set.LegendVisible(obj,onoff)
            obj.LegendVisible_I=onoff;
            obj.LegendVisibleMode='manual';
            obj.LayoutDirty=true;
        end

        function set.MaxDisplayBubbles(obj,val)
            validateattributes(val,{'numeric'},{'scalar','positive','nonnan'});
            if isfinite(val)
                validateattributes(val,{'numeric'},{'integer'});
            end
            obj.RadiiDirty=true;
            obj.MaxDisplayBubblesMode='manual';
            obj.MaxDisplayBubbles_I=val;
        end

        function set.LegendTitle(obj,tit)
            obj.LegendTitle_I=tit;
            obj.LegendTitleMode='manual';
            obj.LayoutDirty=true;
        end
        
        function set.DataStorage(obj,ds)
            obj.deserialize(ds);
        end

        function ds=get.DataStorage(obj)
            ds=obj.serialize;
        end

        function sz=get.SizeData(obj)
            sz=obj.SizeData_I;
        end
        function lbl=get.LabelData(obj)
            lbl=obj.LabelData_I;
        end
        function gp=get.GroupData(obj)
            gp=obj.GroupData_I;
        end
        function tbl=get.SourceTable(obj)
            tbl=obj.SourceTable_I;
        end
        function var=get.SizeVariable(obj)
            var=obj.SizeVariable_I;
        end
        function var=get.LabelVariable(obj)
            var=obj.LabelVariable_I;
        end
        function var=get.GroupVariable(obj)
            var=obj.GroupVariable_I;
        end
        function clr=get.FontColor(obj)
            clr=obj.FontColor_I;
        end
        function name=get.FontName(obj)
            name=obj.FontName_I;
        end
        function sz=get.FontSize(obj)
            sz=obj.FontSize_I;
        end
        function str=get.Title(obj)
            str = obj.Title_I;
        end
        function clr=get.FaceColor(obj)
            clr=obj.FaceColor_I;
        end
        function clr=get.EdgeColor(obj)
            clr=obj.EdgeColor_I;
        end
        function clrs=get.ColorOrder(obj)
            clrs=obj.ColorOrder_I;
        end
        function alp=get.FaceAlpha(obj)
            alp=obj.FaceAlpha_I;
        end
        function onoff=get.LegendVisible(obj)
            if strcmp(obj.LegendVisibleMode,'auto')
                onoff=matlab.lang.OnOffSwitchState(~isempty(obj.GroupData_I));
            else
                onoff=matlab.lang.OnOffSwitchState(obj.LegendVisible_I);
            end
        end
        function val=get.MaxDisplayBubbles(obj)
            val=obj.MaxDisplayBubbles_I;
        end
        function tit=get.LegendTitle(obj)
            if strcmp(obj.LegendTitleMode,'auto')
                obj.LegendTitle_I = obj.GroupVariableName;
            end
            tit=obj.LegendTitle_I;
        end
        function tf=get.UsingTableForData(obj)
            % Following pattern from heatmap:
            %   SizeDataMode == 'auto' indicates table workflow
            %   SizeDataMode == 'manual' indicates vector workflow
            tf = strcmp(obj.SizeDataMode,'auto');
        end
        function tf=get.NotUsingTableForData(obj)
            % Following pattern from heatmap, NotUsingTableForData allows 
            % switching from table to vector workflow, needed because at
            % initialization SizeDataMode is auto
            tf = strcmp(obj.SizeDataMode,'manual') || width(obj.SourceTable)==0;
        end
        function set.FigureAncestorForPlotEditListener(obj, fig)
            % Note that because this property is AbortSet, this function
            % runs only when the ancestor changes
            obj.FigureAncestorForPlotEditListener = fig;
            uigetmodemanager(fig);
            if ~isempty(fig)
                obj.PlotEditListener = fig.ModeManager.listener('CurrentMode', ...
                    'PostSet', @(~,e) obj.updateLingerAndDatatipsForPlotEdit(fig));
            end
        end
    end
    methods (Access=private)
        function updateLingerAndDatatipsForPlotEdit(obj, fig)
            if isscalar(obj.Linger) && isvalid(obj.Linger)
                mode = fig.ModeManager.CurrentMode;
                if isscalar(mode) && mode.Name == "Standard.EditPlot"
                    obj.Linger.disable;
                    obj.Datatip.Visible='off';
                    obj.HighlightMarker.Visible='off';
                else
                    obj.Linger.enable;
                end
            end
        end
    end
end

function err=validateSizeData(sz)
err=[];
if ~isnumeric(sz) || any(sz<0)
    err=MException(message('MATLAB:graphics:bubblecloud:SizeNonNegativeNumeric'));
end
end
function err=validateLabelData(lbl)
err=[];
try
    % Try casting the label to a string. BubbleCloud accepts anything
    % castable to string as a valid label, but stores the original
    % datatype e.g. bubblecloud(1:10,hours(1:10))
    string(lbl);
catch
    err=MException(message('MATLAB:graphics:bubblecloud:InvalidLabelData'));
end
end
function err=validateGroupData(gp)
err=[];
if ~(isstring(gp) || iscellstr(gp) || iscategorical(gp) || isnumeric(gp) || islogical(gp))
    err=MException(message('MATLAB:graphics:bubblecloud:InvalidGroupData'));
end
end

function [err,var,val,varname]=validateTableVar(tbl, var, propname, validatefunc)
val=[];

% Check that variable is valid
import matlab.graphics.chart.internal.validateTableSubscript
[varname, var, err] = validateTableSubscript(tbl, var, propname);
if ~isempty(err)
    return;
end

% Check that the contents are valid
if ~isempty(varname)
    val=tbl.(varname);
    err=validatefunc(val);
else
    val=[];
end
end

% LocalWords:  bubblecloud getters validatecolor RGBA castable
