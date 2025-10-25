classdef (ConstructOnLoad) FontsContainer < controllib.widget.internal.cstprefs.AbstractContainer & ...
                                                matlab.mixin.SetGet
    % "FontsContainer": 
    % Widget that is used to set font styles for titles and labels in the
    % plots
    %
    % To use container with specific rows in a dialog or panel:
    %
    %   c = controllib.widget.internal.cstprefs.FontsContainer('Title','XYLabels','AxesLabels','IOLabels'); 
    %   w = getWidget(c); 
    %   f = uifigure; 
    %   w.Parent = f;
    %
    %   c = controllib.widget.internal.cstprefs.FontsContainer('Title','IOLabels'); 
    %   w = getWidget(c); 
    %   f = uifigure; 
    %   w.Parent = f;
    %
    % To use container with all rows (title, xy-labels, tick(axes) labels
    % and io-labels) in a dialog/panel:
    %   
    %   c = controllib.widget.internal.cstprefs.FontsContainer(); 
    %   w = getWidget(c); 
    %   f = uifigure; 
    %   w.Parent = f;
    %
    % Properties
    %   TitleFontSize,XYLabelsFontSize,AxesFontSize,IOLabelsFontSize
    %       Set or get font size (numeric) for the specific label.
    %   TitleFontWeight,XYLabelsFontWeight,AxesFontWeight,IOLabelsFontWeight
    %       Set or get the bold style ('bold' or 'normal')
    %   TitleFontAngle
    %       Set or get the italic style ('italic' or 'normal)
    
    % Copyright 2020-2022 The MathWorks, Inc.
    
    properties (Dependent,SetObservable,AbortSet)
        LabelTypes
        TitleText
        TitleFontSize
        TitleFontWeight
        TitleFontAngle
        XYLabelsText
        XYLabelsFontSize
        XYLabelsFontWeight
        XYLabelsFontAngle
        AxesText
        AxesFontSize
        AxesFontWeight
        AxesFontAngle
        IOLabelsText
        IOLabelsFontSize
        IOLabelsFontWeight
        IOLabelsFontAngle
    end
    
    properties (Access = private, SetObservable)
        LabelTypes_I

        TitleRow = []
        XYLabelsRow = []
        AxesLabelsRow = []
        IOLabelsRow = []
        
        TitleWidget
        XYLabelsWidget
        AxesWidget
        IOLabelsWidget
        
        TitleTextInternal
        TitleFontSizeInternal
        TitleFontWeightInternal
        TitleFontAngleInternal
        XYLabelsTextInternal
        XYLabelsFontSizeInternal
        XYLabelsFontWeightInternal
        XYLabelsFontAngleInternal
        AxesTextInternal
        AxesFontSizeInternal
        AxesFontWeightInternal
        AxesFontAngleInternal
        IOLabelsTextInternal
        IOLabelsFontSizeInternal
        IOLabelsFontWeightInternal
        IOLabelsFontAngleInternal
        
        UpdateWidget = true
        WidgetTags
    end
    
    properties(Hidden)
        AddTagsToWidgets = true
    end
    
    methods
        function this = FontsContainer(varargin)
            if nargin > 0
                this.LabelTypes_I = varargin;
            else
                this.LabelTypes_I = {'Title','XYLabels','AxesLabels','IOLabels'};
            end

            assignLabelRows(this);
            
            this.ContainerTitle = m('Controllib:gui:strFonts');
            initializeStyle(this);
            createWidgetTags(this);
        end
    end
    
    methods %get/set
        % LabelTypes
        function LabelTypes = get.LabelTypes(this)
            LabelTypes = this.LabelTypes_I;
        end

        function set.LabelTypes(this,LabelTypes)
            if ~this.IsWidgetValid
                this.LabelTypes_I = LabelTypes;
                assignLabelRows(this);
            else
                error('Cannot change LabelTypes after widget is created');
            end
        end
        
        % TitleText
        function TitleText = get.TitleText(this)
            TitleText = this.TitleTextInternal;
        end
        
        function set.TitleText(this,TitleText)
            if ~isempty(this.TitleWidget) && isvalid(this.TitleWidget) && ...
                    this.UpdateWidget
                this.TitleWidget.FontLabel = TitleText;
            end
            this.TitleTextInternal = TitleText;
        end
        
        % TitleFontSize
        function TitleFontSize = get.TitleFontSize(this)
            TitleFontSize = this.TitleFontSizeInternal;
        end
        
        function set.TitleFontSize(this,TitleFontSize)
            if ~isempty(this.TitleWidget) && isvalid(this.TitleWidget) && ...
                    this.UpdateWidget
                this.TitleWidget.FontSize = TitleFontSize;
            end
            this.TitleFontSizeInternal = TitleFontSize;
        end
        
        % TitleFontWeight
        function TitleFontWeight = get.TitleFontWeight(this)
            TitleFontWeight = this.TitleFontWeightInternal;
        end
        
        function set.TitleFontWeight(this,TitleFontWeight) 
            if ~isempty(this.TitleWidget) && isvalid(this.TitleWidget) && ...
                    this.UpdateWidget
                this.TitleWidget.FontWeight = TitleFontWeight;
            end
            this.TitleFontWeightInternal = TitleFontWeight;
        end
        
        % TitleFontAngle
        function TitleFontAngle = get.TitleFontAngle(this)
            TitleFontAngle = this.TitleFontAngleInternal;
        end
        
        function set.TitleFontAngle(this,TitleFontAngle)
            if ~isempty(this.TitleWidget) && isvalid(this.TitleWidget) && ...
                    this.UpdateWidget
                this.TitleWidget.FontAngle = TitleFontAngle;
            end
            this.TitleFontAngleInternal = TitleFontAngle;
        end
        
        % XYLabelsText
        function XYLabelsText = get.XYLabelsText(this)
            XYLabelsText = this.XYLabelsTextInternal;
        end
        
        function set.XYLabelsText(this,XYLabelsText)
            if ~isempty(this.XYLabelsWidget) && isvalid(this.XYLabelsWidget) && ...
                    this.UpdateWidget
                this.XYLabelsWidget.FontLabel = XYLabelsText;
            end
            this.XYLabelsTextInternal = XYLabelsText;
        end
        
        % XYLabelsFontSize
        function XYLabelsFontSize = get.XYLabelsFontSize(this)
            XYLabelsFontSize = this.XYLabelsFontSizeInternal;
        end
        
        function set.XYLabelsFontSize(this,XYLabelsFontSize)
            if ~isempty(this.XYLabelsWidget) && isvalid(this.XYLabelsWidget) && ...
                    this.UpdateWidget
                this.XYLabelsWidget.FontSize = XYLabelsFontSize;
            end
            this.XYLabelsFontSizeInternal = XYLabelsFontSize;
        end
        
        % XYLabelsFontWeight
        function XYLabelsFontWeight = get.XYLabelsFontWeight(this)
            XYLabelsFontWeight = this.XYLabelsFontWeightInternal;
        end
        
        function set.XYLabelsFontWeight(this,XYLabelsFontWeight)
            if ~isempty(this.XYLabelsWidget) && isvalid(this.XYLabelsWidget) && ...
                    this.UpdateWidget
                this.XYLabelsWidget.FontWeight = XYLabelsFontWeight;
            end
            this.XYLabelsFontWeightInternal = XYLabelsFontWeight;
        end
        
        % XYLabelsFontAngle
        function XYLabelsFontAngle = get.XYLabelsFontAngle(this)
            XYLabelsFontAngle = this.XYLabelsFontAngleInternal;
        end
        
        function set.XYLabelsFontAngle(this,XYLabelsFontAngle)
            if ~isempty(this.XYLabelsWidget) && isvalid(this.XYLabelsWidget) && ...
                    this.UpdateWidget
                this.XYLabelsWidget.FontAngle = XYLabelsFontAngle;
            end
            this.XYLabelsFontAngleInternal = XYLabelsFontAngle;
        end
        
        % AxesText
        function AxesText = get.AxesText(this)
            AxesText = this.AxesTextInternal;
        end
        
        function set.AxesText(this,AxesText)
            if ~isempty(this.AxesWidget) && isvalid(this.AxesWidget) && ...
                    this.UpdateWidget
                this.AxesWidget.FontLabel = AxesText;
            end
            this.AxesTextInternal = AxesText;
        end
        
        % AxesFontSize
        function AxesFontSize = get.AxesFontSize(this)
            AxesFontSize = this.AxesFontSizeInternal;
        end
        
        function set.AxesFontSize(this,AxesFontSize)
            if ~isempty(this.AxesWidget) && isvalid(this.AxesWidget) && ...
                    this.UpdateWidget
                this.AxesWidget.FontSize = AxesFontSize;
            end
            this.AxesFontSizeInternal = AxesFontSize;
        end
        
        % AxesFontWeight
        function AxesFontWeight = get.AxesFontWeight(this)
            AxesFontWeight = this.AxesFontWeightInternal;
        end
        
        function set.AxesFontWeight(this,AxesFontWeight)
            if ~isempty(this.AxesWidget) && isvalid(this.AxesWidget) && ...
                    this.UpdateWidget
                this.AxesWidget.FontWeight = AxesFontWeight;
            end
            this.AxesFontWeightInternal = AxesFontWeight;
        end
        
        % AxesFontAngle
        function AxesFontAngle = get.AxesFontAngle(this)
            AxesFontAngle = this.AxesFontAngleInternal;
        end
        
        function set.AxesFontAngle(this,AxesFontAngle)
            if ~isempty(this.AxesWidget) && isvalid(this.AxesWidget) && ...
                    this.UpdateWidget
                this.AxesWidget.FontAngle = AxesFontAngle;
            end
            this.AxesFontAngleInternal = AxesFontAngle;
        end
        
        % IOLabelsText
        function IOLabelsText = get.IOLabelsText(this)
            IOLabelsText = this.IOLabelsTextInternal;
        end
        
        function set.IOLabelsText(this,IOLabelsText)
            if ~isempty(this.IOLabelsWidget) && isvalid(this.IOLabelsWidget) && ...
                    this.UpdateWidget
                this.IOLabelsWidget.FontLabel = IOLabelsText;
            end
            this.IOLabelsTextInternal = IOLabelsText;
        end
        
        % IOLabelsFontSize
        function IOLabelsFontSize = get.IOLabelsFontSize(this)
            IOLabelsFontSize = this.IOLabelsFontSizeInternal;
        end
        
        function set.IOLabelsFontSize(this,IOLabelsFontSize)
            if ~isempty(this.IOLabelsWidget) && isvalid(this.IOLabelsWidget) && ...
                    this.UpdateWidget
                this.IOLabelsWidget.FontSize = IOLabelsFontSize;
            end
            this.IOLabelsFontSizeInternal = IOLabelsFontSize;
        end
        
        % IOLabelsFontWeight
        function IOLabelsFontWeight = get.IOLabelsFontWeight(this)
            IOLabelsFontWeight = this.IOLabelsFontWeightInternal;
        end
        
        function set.IOLabelsFontWeight(this,IOLabelsFontWeight)
            if ~isempty(this.IOLabelsWidget) && isvalid(this.IOLabelsWidget) && ...
                    this.UpdateWidget
                this.IOLabelsWidget.FontWeight = IOLabelsFontWeight;
            end
            this.IOLabelsFontWeightInternal = IOLabelsFontWeight;
        end
        
        % IOLabelsFontAngle
        function IOLabelsFontAngle = get.IOLabelsFontAngle(this)
            IOLabelsFontAngle = this.IOLabelsFontAngleInternal;
        end
        
        function set.IOLabelsFontAngle(this,IOLabelsFontAngle)
            if ~isempty(this.IOLabelsWidget) && isvalid(this.IOLabelsWidget) && ...
                    this.UpdateWidget
                this.IOLabelsWidget.FontAngle = IOLabelsFontAngle;
            end
            this.IOLabelsFontAngleInternal = IOLabelsFontAngle;
        end
    end
    
    methods(Access = protected, Sealed)
        function widget = createWidget(this)
            widget = uigridlayout('Parent',[],'RowHeight',{'fit'},'ColumnWidth',{'fit'},...
                'Scrollable',"off");
            widget.Padding = 0;
            nRows = max([this.TitleRow,this.XYLabelsRow,this.AxesLabelsRow,this.IOLabelsRow]);
            if ~isempty(nRows)
                % Set RowHeight and ColumnWidth
                widget.RowHeight = repmat({'fit'},1,nRows);
                % Title
                if this.TitleRow
                    this.TitleWidget = localBuildRow(widget,this.TitleText,...
                        this.TitleFontSize,this.TitleFontWeight,...
                        this.TitleFontAngle,this.TitleRow);
                    if this.AddTagsToWidgets
                        setTags(this.TitleWidget,this.WidgetTags.TitleWidget);
                    end
                end
                % XYLabels
                if this.XYLabelsRow
                    this.XYLabelsWidget = localBuildRow(widget,this.XYLabelsText,...
                        this.XYLabelsFontSize,this.XYLabelsFontWeight,...
                        this.XYLabelsFontAngle,this.XYLabelsRow);
                    if this.AddTagsToWidgets
                        setTags(this.XYLabelsWidget,this.WidgetTags.XYLabelsWidget);
                    end
                end
                % Axes
                if this.AxesLabelsRow
                    this.AxesWidget = localBuildRow(widget,this.AxesText,...
                        this.AxesFontSize,this.AxesFontWeight,...
                        this.AxesFontAngle,this.AxesLabelsRow);
                    if this.AddTagsToWidgets
                        setTags(this.AxesWidget,this.WidgetTags.AxesWidget);
                    end
                end
                % IOLabels
                if this.IOLabelsRow
                    this.IOLabelsWidget = localBuildRow(widget,this.IOLabelsText,...
                        this.IOLabelsFontSize,this.IOLabelsFontWeight,...
                        this.IOLabelsFontAngle,this.IOLabelsRow);
                    if this.AddTagsToWidgets
                        setTags(this.IOLabelsWidget,this.WidgetTags.IOLabelsWidget);
                    end
                end
            end
        end
        
        function connectUI(this)
            % Title
            weakThis = matlab.lang.WeakReference(this);
            if ~isempty(this.TitleWidget) && isvalid(this.TitleWidget)
                L = [addlistener(this.TitleWidget,'FontSizeChanged',...
                        @(es,ed) setValueOnWidgetEvent(weakThis.Handle,'TitleFontSize',ed.Data));...
                     addlistener(this.TitleWidget,'FontWeightChanged',...
                        @(es,ed) setValueOnWidgetEvent(weakThis.Handle,'TitleFontWeight',ed.Data));...
                     addlistener(this.TitleWidget,'FontAngleChanged',...
                        @(es,ed) setValueOnWidgetEvent(weakThis.Handle,'TitleFontAngle',ed.Data))];
                registerUIListeners(this,L,{'TitleFontSizeLis';'TitleFontWeightLis';...
                                            'TitleFontAngleLis'});
            end
            
            % XYLabels
            if ~isempty(this.XYLabelsWidget) && isvalid(this.XYLabelsWidget)
                L = [addlistener(this.XYLabelsWidget,'FontSizeChanged',...
                        @(es,ed) setValueOnWidgetEvent(weakThis.Handle,'XYLabelsFontSize',ed.Data));...
                     addlistener(this.XYLabelsWidget,'FontWeightChanged',...
                        @(es,ed) setValueOnWidgetEvent(weakThis.Handle,'XYLabelsFontWeight',ed.Data));...
                     addlistener(this.XYLabelsWidget,'FontAngleChanged',...
                        @(es,ed) setValueOnWidgetEvent(weakThis.Handle,'XYLabelsFontAngle',ed.Data))];
                registerUIListeners(this,L,{'XYLabelsFontSizeLis';'XYLabelsFontWeightLis';...
                                            'XYLabelsFontAngleLis'});
            end
            
            % Axes
            if ~isempty(this.AxesWidget) && isvalid(this.AxesWidget)
                L = [addlistener(this.AxesWidget,'FontSizeChanged',...
                        @(es,ed) setValueOnWidgetEvent(weakThis.Handle,'AxesFontSize',ed.Data));...
                     addlistener(this.AxesWidget,'FontWeightChanged',...
                        @(es,ed) setValueOnWidgetEvent(weakThis.Handle,'AxesFontWeight',ed.Data));...
                     addlistener(this.AxesWidget,'FontAngleChanged',...
                        @(es,ed) setValueOnWidgetEvent(weakThis.Handle,'AxesFontAngle',ed.Data))];
                registerUIListeners(this,L,{'AxesFontSizeLis';'AxesFontWeightLis';...
                                            'AxesFontAngleLis'});
            end
            
            % IOLabels
            if ~isempty(this.IOLabelsWidget) && isvalid(this.IOLabelsWidget)
                L = [addlistener(this.IOLabelsWidget,'FontSizeChanged',...
                        @(es,ed) setValueOnWidgetEvent(weakThis.Handle,'IOLabelsFontSize',ed.Data));...
                     addlistener(this.IOLabelsWidget,'FontWeightChanged',...
                        @(es,ed) setValueOnWidgetEvent(weakThis.Handle,'IOLabelsFontWeight',ed.Data));...
                     addlistener(this.IOLabelsWidget,'FontAngleChanged',...
                        @(es,ed) setValueOnWidgetEvent(weakThis.Handle,'IOLabelsFontAngle',ed.Data))];
                registerUIListeners(this,L,{'IOLabelsFontSizeLis';'IOLabelsFontWeightLis';...
                                            'IOLabelsFontAngleLis'});
            end
        end
    end
    
    methods (Access = private)
        function initializeStyle(this)
            toolboxPreferences = cstprefs.tbxprefs;
            this.TitleTextInternal = m('Controllib:gui:strTitlesLabel');
            this.TitleFontSizeInternal = toolboxPreferences.TitleFontSize;
            this.TitleFontWeightInternal = toolboxPreferences.TitleFontWeight;
            this.TitleFontAngleInternal = toolboxPreferences.TitleFontAngle;
            this.XYLabelsTextInternal = m('Controllib:gui:strXYLabel');
            this.XYLabelsFontSizeInternal = toolboxPreferences.XYLabelsFontSize;
            this.XYLabelsFontWeightInternal = toolboxPreferences.XYLabelsFontWeight;
            this.XYLabelsFontAngleInternal = toolboxPreferences.XYLabelsFontAngle;
            this.AxesTextInternal = m('Controllib:gui:strTickLabelsLabel');
            this.AxesFontSizeInternal = toolboxPreferences.AxesFontSize;
            this.AxesFontWeightInternal = toolboxPreferences.AxesFontWeight;
            this.AxesFontAngleInternal = toolboxPreferences.AxesFontAngle;
            this.IOLabelsTextInternal = m('Controllib:gui:strIONamesLabel');
            this.IOLabelsFontSizeInternal = toolboxPreferences.IOLabelsFontSize;
            this.IOLabelsFontWeightInternal = toolboxPreferences.IOLabelsFontWeight;
            this.IOLabelsFontAngleInternal = toolboxPreferences.IOLabelsFontAngle;
        end
        
        function createWidgetTags(this)
            % TitleWidget
            tags.TitleWidget.FontSize = 'TitleFontSizeDropDown';
            tags.TitleWidget.FontWeight = 'TitleFontWeightCheckBox';
            tags.TitleWidget.FontAngle = 'TitleFontAngleCheckBox';
            tags.TitleWidget.FontLabel = 'TitleFontLabel';
            % XYLabels widget tags
            tags.XYLabelsWidget.FontSize = 'XYLabelsFontSizeDropDown';
            tags.XYLabelsWidget.FontWeight = 'XYLabelsFontWeightCheckBox';
            tags.XYLabelsWidget.FontAngle = 'XYLabelsFontAngleCheckBox';
            tags.XYLabelsWidget.FontLabel = 'XYLabelsFontLabel';
            % Axes widget tags
            tags.AxesWidget.FontSize = 'AxesFontSizeDropDown';
            tags.AxesWidget.FontWeight = 'AxesFontWeightCheckBox';
            tags.AxesWidget.FontAngle = 'AxesFontAngleCheckBox';
            tags.AxesWidget.FontLabel = 'AxesFontLabel';
            % XYLabels widget tags
            tags.IOLabelsWidget.FontSize = 'IOLabelsFontSizeDropDown';
            tags.IOLabelsWidget.FontWeight = 'IOLabelsFontWeightCheckBox';
            tags.IOLabelsWidget.FontAngle = 'IOLabelsFontAngleCheckBox';
            tags.IOLabelsWidget.FontLabel = 'IOLabelsFontLabel';
            
            this.WidgetTags = tags;
        end
        
        function setValueOnWidgetEvent(this,name,value)
            updateWidgetFlag = this.UpdateWidget;
            this.UpdateWidget = false;
            this.(name) = value;
            this.UpdateWidget = updateWidgetFlag;
        end

        function assignLabelRows(this)
            this.TitleRow = find(contains(this.LabelTypes_I,'Title'));
            this.XYLabelsRow = find(contains(this.LabelTypes_I,'XYLabels'));
            this.AxesLabelsRow = find(contains(this.LabelTypes_I,'AxesLabels') | ...
                                      contains(this.LabelTypes_I,'Axes'));
            this.IOLabelsRow = find(contains(this.LabelTypes_I,'IOLabels'));
        end
    end
    
    methods (Hidden)
        function widgets = qeGetWidgets(this)
            widgetNames = {'TitleWidget','XYLabelsWidget','AxesWidget','IOLabelsWidget'};
            for wn = widgetNames
                if ~isempty(this.(wn{1})) && isvalid(this.(wn{1}))
                    widgets.(wn{1}) = qeGetWidgets(this.(wn{1}));
                end
            end
        end
    end
end

function component = localBuildRow(container,fontLabel,fontSize,fontWeight,fontAngle,idx)
component = controllib.widget.internal.cstprefs.FontOptionsWidget();
component.FontSize = fontSize;
component.FontWeight = fontWeight;
component.FontAngle = fontAngle;
component.FontLabel = fontLabel;

widget = getWidget(component);
widget.Parent = container;
widget.Layout.Row = idx;
end

function s = m(id, varargin)
% Reads strings from the resource bundle
m = message(id, varargin{:});
s = m.getString;
end
