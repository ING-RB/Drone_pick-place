classdef FontChooser < handle
    % Font chooser for web figres
    
    % Copyright 2020-2024 The MathWorks, Inc.
    
    properties (SetAccess = immutable)
       % Title to be set on the dialog
       Title = getString(message('MATLAB:FontChooser:FontChooserDialogTitle'));
       % InitialFont refers to the font structure that gets applied to the dialog 
       InitialFont = struct('FontName','Arial',...
                   'FontSize',10,...
                   'FontUnits','points',...
                   'FontWeight','normal',...
                   'FontAngle','normal');
    end
    
    properties
       % SelectedFont refers to the font structure that is returned by
       % the dialog upon selection by clicking ok
       SelectedFont = []
       WaitFlag
    end
    
    properties (Access = private)
        Handles
    end
    
    properties (Constant, Access = private)
        FontNames = listfonts;
        FontStyles = {'Plain','Bold','Italic','Bold Italic'};
        % Font Sizes are in pt
        FontSizes = {'8','9','10','12','14','18','24','36','48'};
    end
    
    methods
        function obj = FontChooser(title, initialFont)  
            arguments
                title {mustBeTextScalar} = '';
                initialFont = [];
            end
            
            % title  
            if ~isempty(title)
                obj.Title = title;
            end
            
            % if the default font 'Arial' is not available use the first
            % fontname returned by listfonts
            obj.InitialFont.FontName = obj.getInitialFontName(obj.InitialFont.FontName);
            
            % initial font
            if ~isempty(initialFont)
                if (~isstruct(initialFont))
                    error(message('MATLAB:UiFontChooser:InvalidFont'));
                end

                % initialFont is a structure and we take those properties
                % we are interested in, namely
                % FontName, FontAngle, FontWeight and FontSize.
                % FontUnits is always points.
                % Populate InitialFont based only on the
                % fields supplied. Incomplete structs are also allowed.
                if isfield(initialFont,'FontName')
                    obj.InitialFont.FontName = obj.getInitialFontName(initialFont.FontName);
                end
                if isfield(initialFont,'FontAngle')
                    obj.InitialFont.FontAngle = obj.getInitialFontAngle(initialFont.FontAngle);
                end
                if isfield(initialFont,'FontWeight')
                    obj.InitialFont.FontWeight = obj.getInitialFontWeight(initialFont.FontWeight);
                end
                if isfield(initialFont,'FontSize')
                    validateattributes(initialFont.FontSize,{'numeric'}, {'finite','scalar','positive'}, 'uisetfont','''FontSize''');
                    obj.InitialFont.FontSize = initialFont.FontSize;
                end
            end

            obj.createFontChooserDialog;
        end
        
        function show(obj)
            obj.SelectedFont = [];
            set(obj.Handles.Fig,'WindowStyle','modal',...
                'Visible','on');
            obj.blockMATLAB();
        end
    end
    
    methods
        function delete(obj)                       
            % delete the fig handle
            if ~isempty(obj.Handles) && ishandle(obj.Handles.Fig)
                delete(obj.Handles.Fig);
            end
        end
    end
    
    methods (Access = private)
        function createFontChooserDialog(obj)
            pos = matlab.ui.internal.dialog.DialogUtils.centerWindowToFigure([0 0 415 330]);
            obj.Handles.Fig = uifigure('Name',obj.Title,...
                    'Position',pos,...
                    'Resize','off',...
                    'Visible','off',...
                    'KeyPressFcn',@ obj.closeOnEsc,...
                    'CloseRequestFcn',@ obj.hide,...
                    'Tag','FontChooserFig',...
                    'WindowStyle','modal');
            matlab.graphics.internal.themes.figureUseDesktopTheme(obj.Handles.Fig)
            g = uigridlayout(obj.Handles.Fig,'ColumnWidth',{175,100,100},...
                    'RowHeight',{'fit','fit',136,5,'fit',75},...
                    'RowSpacing',0);

            uilabel(g,'Text',getString(message('MATLAB:FontChooser:FontTitle')));
            uilabel(g,'Text',getString(message('MATLAB:FontChooser:StyleTitle')));
            uilabel(g,'Text',getString(message('MATLAB:FontChooser:SizeTitle')));

            initialStyle = obj.convertToStyle(obj.InitialFont.FontWeight,obj.InitialFont.FontAngle);
            initialSize = num2str(obj.InitialFont.FontSize);
            obj.Handles.FontField = uieditfield(g,'ValueChangingFcn',@ obj.searchFontName,...
                'ValueChangedFcn',@ obj.setFontField,...
                'Value',obj.InitialFont.FontName,...
                'Tag','FontField');
            obj.Handles.StyleField = uieditfield(g,'ValueChangingFcn',@ obj.searchFontStyle,...
                'ValueChangedFcn',@ obj.setStyleField,...
                'Value',initialStyle,...
                'Tag','StyleField');
            obj.Handles.SizeField = uieditfield(g,'ValueChangingFcn',@ obj.searchFontSize,...
                'ValueChangedFcn',@ obj.setSizeField,...
                'Value',initialSize,...
                'Tag','SizeField');

            obj.Handles.FontList = uilistbox(g,'Items',obj.FontNames,...
                'ValueChangedFcn',@ obj.updateFontName,...
                'Value',obj.InitialFont.FontName,...
                'Tag','FontList');
            scroll(obj.Handles.FontList,obj.Handles.FontList.Value);
            obj.Handles.StyleList = uilistbox(g,'Items',obj.FontStyles,...
                'ValueChangedFcn',@ obj.updateFontStyle,...
                'Value',initialStyle,...
                'Tag','StyleList');
            obj.Handles.SizeList = uilistbox(g,'Items',obj.FontSizes,...
                'ValueChangedFcn',@ obj.updateFontSize,...
                'Tag','SizeList');
            if ~isempty(find(strcmp(obj.FontSizes,initialSize), 1))
                obj.Handles.SizeList.Value = initialSize;
                scroll(obj.Handles.SizeList,obj.Handles.SizeList.Value);
            end

            sampleTitle = uilabel(g,'Text',getString(message('MATLAB:FontChooser:SampleTitle')));
            sampleTitle.Layout.Row = 5;
            
            samplePanel = uipanel(g);
            samplePanel.Layout.Row = 6;
            samplePanel.Layout.Column = [1 3];

            panelGrid = uigridlayout(samplePanel,'ColumnWidth',{'1x'},...
                'RowHeight',{'fit'},...
                'Padding',zeros(1,4));
            obj.Handles.SampleLabel = uilabel(panelGrid,'Text',getString(message('MATLAB:FontChooser:SampleText')),...
                'WordWrap','on',...
                'FontName',obj.InitialFont.FontName,...
                'FontSize',obj.convertPointsToPixels(initialSize),...
                'FontWeight',obj.InitialFont.FontWeight,...
                'FontAngle',obj.InitialFont.FontAngle,...
                'Tag','SampleText');

            uibutton(obj.Handles.Fig,'Text',getString(message('MATLAB:FontChooser:OK')),...
                'Position',[225,10,85,22],...
                'ButtonPushedFcn',@ obj.commit,...
                'Tag','OKButton');
            uibutton(obj.Handles.Fig,'Text',getString(message('MATLAB:FontChooser:Cancel')),...
                'Position',[320,10,85,22],...
                'ButtonPushedFcn',@ obj.hide,...
                'Tag','CancelButton');
        end

        function updateFontName(obj, ~, e)
            % when Font listbox value is changed update 
            % font edit field and apply change to sample
            if ~isempty(e.Value)
                obj.Handles.FontField.Value = e.Value;
                obj.Handles.SampleLabel.FontName = e.Value;
            end
        end

        function updateFontStyle(obj, ~, e)
            % when Style listbox value is changed update 
            % style edit field and apply change to sample
            if ~isempty(e.Value)
                obj.Handles.StyleField.Value = e.Value;
                obj.updateSampleLabelStyle(e.Value);
            end
        end
        
        function updateSampleLabelStyle(obj, style)
            [weight, angle] = obj.convertToFontWeightAndAngle(style);
            obj.Handles.SampleLabel.FontWeight = weight;
            obj.Handles.SampleLabel.FontAngle = angle;
        end
        
        function updateFontSize(obj, ~, e)
            % when Size listbox value is changed update 
            % size edit field and apply change to sample
            if ~isempty(e.Value)
                numValueInPixels = obj.convertPointsToPixels(e.Value);
                obj.Handles.SizeField.Value = e.Value;
                obj.Handles.SampleLabel.FontSize = numValueInPixels;
            end
        end
        
        function searchFontName(obj, ~, e)
            % as user types in the font edit field, lookup
            % the font listbox and select if there is a match.
            % Also, apply the change to the sample
            matches = find(startsWith(obj.FontNames,e.Value,'IgnoreCase',true));
            if ~isempty(matches)
                value = obj.Handles.FontList.Items{matches(1)};
                scroll(obj.Handles.FontList,value);
                obj.Handles.FontList.Value = value;
                obj.Handles.SampleLabel.FontName = value;
            end
        end
        
        function setFontField(obj, ~, ~)
            obj.Handles.FontField.Value = obj.Handles.FontList.Value;
        end
        
        function setStyleField(obj, ~, ~)
            obj.Handles.StyleField.Value = obj.Handles.StyleList.Value;
        end
        
        function setSizeField(obj, ~, e)
            if ~isnan(str2double(e.Value))
                obj.Handles.SizeField.Value = e.Value;
            else
                obj.Handles.SizeField.Value = num2str(obj.convertPixelsToPoints(obj.Handles.SampleLabel.FontSize));
            end
        end
        
        function searchFontStyle(obj, ~, e)
            % as user types in the style edit field, lookup
            % the style listbox and select if there is a match.
            % Also, apply the change to the sample
            matches = find(startsWith(obj.FontStyles,e.Value,'IgnoreCase',true));
            if ~isempty(matches)
                value = obj.Handles.StyleList.Items{matches(1)};
                obj.Handles.StyleList.Value = value;
                obj.updateSampleLabelStyle(value);
            end
        end
        
        function searchFontSize(obj, ~, e)
            % as user types in the size edit field, lookup
            % the size listbox and select if there is a match.
            % Also, apply the change to the sample
            matches = find(strcmpi(obj.FontSizes,e.Value));
            if ~isempty(matches)
                value = obj.Handles.SizeList.Items{matches(1)};
                obj.Handles.SizeList.Value = value;
                obj.Handles.SampleLabel.FontSize = obj.convertPointsToPixels(value);
            elseif ~isnan(str2double(e.Value))
                obj.Handles.SampleLabel.FontSize = obj.convertPointsToPixels(e.Value);
            end
        end
        
        function closeOnEsc(obj, ~, e)
            if strcmp(e.Key,'escape')
                obj.hide();
            elseif strcmp(e.Key,'return')
                obj.commit();
            end
        end
        
        function commit(obj, ~, ~)
            selectedFont = struct('FontName',obj.Handles.SampleLabel.FontName,...
                'FontWeight',obj.Handles.SampleLabel.FontWeight,...
                'FontAngle',obj.Handles.SampleLabel.FontAngle,...
                'FontUnits','points',...
                'FontSize',obj.convertPixelsToPoints(obj.Handles.SampleLabel.FontSize));
            obj.SelectedFont = selectedFont;
            obj.hide();
        end
        
        function hide(obj, ~, ~)
            obj.Handles.Fig.Visible = 'off';
            obj.unblockMATLAB()
        end
        
        function fontName = getInitialFontName(obj, initialFontName)
            match = find(strcmpi(initialFontName,obj.FontNames), 1);
            if ~isempty(match)
                fontName = obj.FontNames{match};
            else
                % if initialFont FontName is not available use the first
                % available font from listfonts
                fontName = obj.FontNames{1};
            end
        end

        function pixels = convertPointsToPixels(obj, points)
            ptNumValue = str2double(points);
            vec = hgconvertunits(obj.Handles.Fig, [0 0 ptNumValue, ptNumValue], 'points', 'pixels', obj.Handles.Fig);
            pixels = vec(3);
        end
        
        function points = convertPixelsToPoints(obj, pixels)
            vec = hgconvertunits(obj.Handles.Fig, [0 0 pixels, pixels], 'pixels', 'points', obj.Handles.Fig);
            points = round(vec(3));
        end

        function fontWeight = getInitialFontWeight(~, initialFontWeight)
            if strcmpi(initialFontWeight,'normal') || strcmpi(initialFontWeight,'bold')
                fontWeight = convertStringsToChars(lower(initialFontWeight));
            else
                fontWeight = 'normal';
            end
        end
        
        function fontAngle = getInitialFontAngle(~, initialFontAngle)
            if strcmpi(initialFontAngle,'normal') || strcmpi(initialFontAngle,'italic')
                fontAngle = convertStringsToChars(lower(initialFontAngle));
            else
                fontAngle = 'normal';
            end
        end
    end
    
    methods (Access = protected)
        function blockMATLAB(obj)
            waitfor(obj,'WaitFlag','stopWaiting');
        end
        
        function unblockMATLAB(obj)            
            obj.WaitFlag = 'stopWaiting';
        end
    end
    
    methods (Static, Access = private)
        function [weight, angle] = convertToFontWeightAndAngle(style)
            switch style
                case 'Plain'
                    weight = 'normal';
                    angle = 'normal';
                case 'Bold'
                    weight = 'bold';
                    angle = 'normal';
                case 'Italic'
                    weight = 'normal';
                    angle = 'italic';
                case 'Bold Italic'
                    weight = 'bold';
                    angle = 'italic';
            end
        end
        
        function style = convertToStyle(weight, angle)
            switch [weight,angle]
                case ['normal','normal']
                    style = 'Plain';
                case ['bold','normal']
                    style = 'Bold';
                case ['normal','italic']
                    style = 'Italic';
                case ['bold','italic']
                    style = 'Bold Italic';
                otherwise
                    style = 'Plain';
            end
        end
        
    end
end
