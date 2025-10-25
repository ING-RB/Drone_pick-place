classdef HTMLText < matlab.hwmgr.internal.hwsetup.Widget & ...
        matlab.hwmgr.internal.hwsetup.mixin.EnableWidget
    % HTMLText provides a text widget that allows you to display HTML
    % content
    %
    % HTMLText widget properties:
    %   Position - Location and Size [left bottom width height]
    %   Visible  - Widget visibility specified as 'on' or 'off'
    %   Text     - String label for the HTMLText
    %   Tag      - Unique identifier for the HTMLText widget
    %
    % Example:
    %   w = matlab.hwmgr.internal.hwsetup.Window.getInstance();
    %   h = matlab.hwmgr.internal.hwsetup.HTMLText.getInstance(w);
    %   h.Text = '<ul><li>Step 1</li><li>Step 2</li></ul>';
    % or
    %   w = matlab.hwmgr.internal.hwsetup.Window.getInstance();
    %   h = matlab.hwmgr.internal.hwsetup.HTMLText.getInstance(w);
    %   h.loadFile('test.html'); % sets h.Text using content from test.html
    %
    % See also matlab.hwmgr.internal.hwsetup.widget
    
    % Copyright 2017-2023 The MathWorks, Inc.
    
    properties(Access = public, Dependent)
        BackgroundColor
        Text
        VerticalAlignment
    end
    
    methods(Access = protected)
        function obj = HTMLText(varargin)
            obj@matlab.hwmgr.internal.hwsetup.Widget(varargin{:});
            
            % defaults
            obj.Text = matlab.hwmgr.internal.hwsetup.util.WidgetDefaults.HTMLText;
            obj.Position = matlab.hwmgr.internal.hwsetup.util.WidgetDefaults.HTMLTextPosition;
        end
    end
    
    methods(Static)
        function obj = getInstance(aParent)
            obj = matlab.hwmgr.internal.hwsetup.Widget.createWidgetInstance(aParent, mfilename);
        end
    end
    
    methods(Abstract, Access = protected)
        % technology implementation
        setText(obj, value);
        setBackgroundColor(obj, value);
        text = getText(obj);
        color = getBackgroundColor(obj);     
    end
    
    methods
        function text = get.Text(obj)
            text = obj.getText();
        end
        
        function color = get.BackgroundColor(obj)
            color = obj.getBackgroundColor();
        end
        
        function set.BackgroundColor(obj, color)
            obj.setBackgroundColor(color);
        end
        
        function set.Text(obj, text)
            validateattributes(text, {'char', 'string'},{});
            obj.setText(text);
        end

        function set.VerticalAlignment(obj, value)                        
            set(obj.Peer, 'VerticalAlignment', value);
        end
        
        function value = get.VerticalAlignment(obj)           
            value = get(obj.Peer, 'VerticalAlignment') ;
        end
        
        function loadFile(obj, filename)
            fileType = {'html', 'htm'};
            rgx = regexp(filename, ['(.+?)', '\.' strjoin(fileType, '|')], 'match');
            if isempty(rgx)
               error(message('ERRORHANDLER:utils:InvalidFileTypeSpecific', filename)); 
            end
            try
                obj.Text = fileread(filename);
            catch ex
                error(ex.message);
            end
        end
    end
end