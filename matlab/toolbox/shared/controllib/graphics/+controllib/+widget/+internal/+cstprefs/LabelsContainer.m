classdef (ConstructOnLoad) LabelsContainer < controllib.widget.internal.cstprefs.AbstractContainer
    % "LabelsContainer":
    % Widget that is used to set the title, xlabel and ylabel.
    %
    % To use container in a dialog/panel:
    %   
    %   c = controllib.widget.internal.cstprefs.LabelsContainer('NumberOfXLabels',2,'NumberOfYLabels',2); 
    %   w = getWidget(c); 
    %   f = uifigure; 
    %   w.Parent = f;
    %
    % Properties
    %   Title       string or char array
    %   XLabel      string array or cell array
    %   YLabel      string array or cell array
    
    % Copyright 2020 The MathWorks, Inc.
    
    properties(Dependent,SetObservable,AbortSet)
        Title
        XLabel
        YLabel
    end
    
    properties (Access = private)
        NXLabels
        NYLabels
        TitleInternal
        XLabelInternal
        YLabelInternal
        
        TitleText       
        XLabelText
        YLabelText
        TitleEditField          matlab.ui.control.TextArea
        XLabelEditField         matlab.ui.control.TextArea
        YLabelEditField         matlab.ui.control.TextArea
        UpdateWidget = true
        WidgetTags = struct(...
                'TitleEditField','LabelsTitleEditField',...
                'XLabelEditField','LabelsXLabelEditField',...
                'YLabelEditField','LabelsYLabelEditField');
    end
    
    properties(Hidden)
        AddTagToWidgets = false
    end
    
    methods
        function this = LabelsContainer(inputArguments)
            arguments
                inputArguments.NumberOfXLabels = 1
                inputArguments.NumberOfYLabels = 1
            end
            this.NXLabels = inputArguments.NumberOfXLabels;
            this.NYLabels = inputArguments.NumberOfYLabels;
            this.TitleInternal = "";
            this.XLabelInternal = repmat({""},1,this.NXLabels); %#ok<*STRSCALR>
            this.YLabelInternal = repmat({""},1,this.NYLabels);
            this.ContainerTitle = m('Controllib:gui:strLabels');
        end
        
        function Title = get.Title(this)
            Title = this.TitleInternal;
        end
        
        function set.Title(this,Title)
            arguments
                this
                Title
            end
            if ischar(Title)
                Title = {Title};
            end
            if ~isempty(this.TitleEditField) && isvalid(this.TitleEditField) && this.UpdateWidget
                this.TitleEditField.Value = Title;
            end  
            this.TitleInternal = Title;
        end
        
        function XLabel = get.XLabel(this)
            XLabel = this.XLabelInternal;
        end
        
        function set.XLabel(this,XLabel)
            arguments
                this
                XLabel
            end
            if ischar(XLabel)
                XLabel = {XLabel};
            end
            if ~isempty(this.XLabelEditField) && isvalid(this.XLabelEditField(1)) && this.UpdateWidget
                if this.NXLabels == 1
                    this.XLabelEditField.Value = XLabel;
                else
                    for k = 1:this.NXLabels
                        this.XLabelEditField(k).Value = XLabel{k};
                    end
                end
            end
            this.XLabelInternal = XLabel;
        end
        
        function YLabel = get.YLabel(this)
            YLabel = this.YLabelInternal;
        end
        
        function set.YLabel(this,YLabel)
            arguments
                this
                YLabel
            end
            if ischar(YLabel)
                YLabel = {YLabel};
            end
            if ~isempty(this.YLabelEditField) && isvalid(this.YLabelEditField(1)) && this.UpdateWidget
                if this.NYLabels == 1
                    this.YLabelEditField.Value = YLabel;
                else
                    for k = 1:this.NYLabels
                        this.YLabelEditField(k).Value = YLabel{k};
                    end
                end
            end  
            this.YLabelInternal = YLabel;
        end
    end
    
    methods(Access = protected, Sealed)
        function widget = createWidget(this)
            widget = uigridlayout('Parent',[],...
                        'RowHeight',repmat({'fit'},1,1+this.NXLabels+this.NYLabels),...
                        'ColumnWidth',{'fit','1x'},'Scrollable',false);
            widget.Padding = 0;
            % Title
            this.TitleText = uilabel(widget,'Text',m('Controllib:gui:strTitleLabel'));
            this.TitleText.Layout.Row = 1;
            this.TitleText.Layout.Column = 1;
            this.TitleText.VerticalAlignment = 'top';
            this.TitleEditField = uitextarea(widget,'Value',this.TitleInternal);
            this.TitleEditField.Layout.Row = 1;
            this.TitleEditField.Layout.Column = 2;
            this.TitleEditField.ValueChangedFcn = ...
                @(es,ed) cbTitleEditFieldValueChanged(this,es,ed);
            % XLabel
            this.XLabelText = uilabel(widget,'Text',m('Controllib:gui:strXLabelLabel'));
            this.XLabelText.Layout.Row = 2;
            this.XLabelText.Layout.Column = 1;
            this.XLabelText.VerticalAlignment = 'top';
            for k = 1:this.NXLabels
                this.XLabelEditField(k) = uitextarea(widget,'Value',this.XLabelInternal{k});
                this.XLabelEditField(k).Layout.Row = 1+k;
                this.XLabelEditField(k).Layout.Column = 2;
                this.XLabelEditField(k).ValueChangedFcn = ...
                    @(es,ed) cbXLabelEditFieldValueChanged(this,es,ed,k);
            end
            % YLabel
            this.YLabelText = uilabel(widget,'Text',m('Controllib:gui:strYLabelLabel'));
            this.YLabelText.Layout.Row = 2+this.NXLabels;
            this.YLabelText.Layout.Column = 1;
            this.YLabelText.VerticalAlignment = 'top';
            for k = 1:this.NYLabels
                this.YLabelEditField(k) = uitextarea(widget,'Value',this.YLabelInternal{k});
                this.YLabelEditField(k).Layout.Row = 1+this.NXLabels+k;
                this.YLabelEditField(k).Layout.Column = 2;
                this.YLabelEditField(k).ValueChangedFcn = ...
                    @(es,ed) cbYLabelEditFieldValueChanged(this,es,ed,k);
            end
            % Add Tags
            if this.AddTagToWidgets
                addTags(this);
            end
        end
    end
    
    methods (Access = private)
        function addTags(this)
            widgetNames = fieldnames(this.WidgetTags);
            for wn = widgetNames'
                if ~isempty(this.(wn{1})) && isvalid(this.(wn{1}))
                    for k = 1:length(this.(wn{1}))
                        w = this.wn{1};
                        w(k).Tag = this.WidgetTags.(wn{1});
                    end
                end
            end
        end
        
        function cbTitleEditFieldValueChanged(this,es,ed)
            try
                this.UpdateWidget = false;
                if isscalar(ed.Value)
                    this.Title = ed.Value;
                else
                    label = [];
                    for ii = 1:length(ed.Value)
                        label = [label ed.Value{ii} newline]; %#ok<AGROW>
                    end
                    label = label(1:end-1);
                    this.Title = {label};
                end
                this.UpdateWidget = true;
            catch
                this.UpdateWidget = true;
                this.Title = this.TitleInternal;
            end
        end
        
        function cbXLabelEditFieldValueChanged(this,es,ed,idx)
            try
                this.UpdateWidget = false;
                if isscalar(ed.Value)
                    this.XLabel(idx) = ed.Value;
                else
                    label = [];
                    for ii = 1:length(ed.Value)
                        label = [label ed.Value{ii} newline]; %#ok<AGROW>
                    end
                    label = label(1:end-1);
                    this.XLabel{idx} = label;
                end
                this.UpdateWidget = true;
            catch
                this.UpdateWidget = true;
                es.Value = this.XLabelInternal(idx);
            end
        end
        
        function cbYLabelEditFieldValueChanged(this,es,ed,idx)
            try
                this.UpdateWidget = false;
                if isscalar(ed.Value)
                    this.YLabel(idx) = ed.Value;
                else
                    label = [];
                    for ii = 1:length(ed.Value)
                        label = [label ed.Value{ii} newline]; %#ok<AGROW>
                    end
                    label = label(1:end-1);
                    this.YLabel{idx} = label;
                end
                this.UpdateWidget = true;
            catch
                this.UpdateWidget = true;
                es.Value = this.YLabelInternal(idx);
            end
        end
    end
    
    methods (Hidden)
        function widgets = qeGetWidgets(this)
            widgets.TitleText = this.TitleText;
            widgets.XLabelText = this.XLabelText;
            widgets.YLabelText = this.YLabelText;
            widgets.TitleEditField = this.TitleEditField;
            widgets.XLabelEditField = this.XLabelEditField;
            widgets.YLabelEditField = this.YLabelEditField;
        end
    end
end

function s = m(id, varargin)
% Reads strings from the resource bundle
m = message(id, varargin{:});
s = m.getString;
end
