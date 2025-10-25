classdef HelpText  < matlab.hwmgr.internal.hwsetup.Widget  & ...
        matlab.hwmgr.internal.hwsetup.mixin.EnableWidget
    %HELPTEXT This class provides an instance of a HelpText widget as a
    %result of calling getInstance. A HelpText will render three text areas
    %for display: "About Your Selection", "What To Consider" and
    %"Additional Information". Each areas can be populated by custom text
    %
    %   HelpText Widget Properties
    %   Position        -Location and Size [left bottom width height]
    %   Visible         -Widget visibility specified as 'on' or 'off'
    %   Tag             -String based identifier
    %   AboutSelection  -Text to describe the selection options
    %   WhatToConsider  -Text to describe what to consider before selecting
    %   an option
    %   Additional      -Text to provide any additional information
    %
    %   EXAMPLE:
    %   w = matlab.hwmgr.internal.hwsetup.Window.getInstance();
    %   p = matlab.hwmgr.internal.hwsetup.Panel.getInstance(w);
    %   ht = matlab.hwmgr.internal.hwsetup.HelpText.getInstance(p);
    %   ht.Position = [20 20 200 20];
    %   ht.AboutSelection = string('This selection will...');
    %   ht.WhatToConsider = string('Consider this before selecting...');
    %   ht.Additional = string('Additionally you may...');
    %   ht.show();
    %
    % Text decoration:
    % HelpText widget allows the usage of html technology, so the text that goes
    % in this section can be decorated using html tags.
    % Some of the tags are listed here to show as examples.
    %
    %  Tags                       Description
    % <h1></h1>   -   Text in the heading tag will be rendered as a title
    %                 of the section.
    %                 Color: MathWorks Blue
    %                 Font Weight: Bold
    % <h6></h6>   -   Text in the alert tag will be rendered in red color. 
    %                 Color: Red
    %                 Font Weight: Bold
    % <b></b>     -   Text in the emphasis tag will be rendered with bold font weight
    %
    % <ul         -   Text will be displayed as unordered list using circle bullets
    % class
    % ="bullets">
    % </ul>
    %
    % <ol         -   Text will be displayed as ordered numbered bullets
    % class
    % ="numbers">
    % </ol>
    %
    % <a 'href'="">-   Display hyperlinks (MATLAB Doc, MATLAB functions, external hyperlinks)
    % </a>             Ignore Single quotes in 'href' (use just href),
    %                  this is added to avoid showing the description
    %                  of href as hyperlink.
    %
    % <br>        -   Line break
    %

    %See also matlab.hwmgr.internal.hwsetup.widget

    % Copyright 2016-2021 The MathWorks, Inc.
    
    properties(Dependent)
        %AboutSelection - Localized string to be displayed in the 'About 
        %Your Selection' section
        AboutSelection
        
        %WhatToConsider - Localized string to be displayed in the 'What To 
        %Consider' section
        WhatToConsider
        
        %Additional - Localized string to be displayed in the 'Additional 
        %Information' section
        Additional
    end
    
    methods(Access = protected)
        function obj = HelpText(varargin)
            %HelpText - Construct HelpText and set defaults.
            
            obj@matlab.hwmgr.internal.hwsetup.Widget(varargin{:});

            %Configure Defaults
            obj.AboutSelection = matlab.hwmgr.internal.hwsetup.util.WidgetDefaults.HelpTextAboutSelection;
            obj.WhatToConsider = matlab.hwmgr.internal.hwsetup.util.WidgetDefaults.HelpTextWhatToConsider;
            obj.Additional = matlab.hwmgr.internal.hwsetup.util.WidgetDefaults.HelpTextAdditional;
        end
    end
    
    methods(Static)
       function obj = getInstance(aParent)
           %getInstance - returns instance of HelpText widget.
           
            obj = matlab.hwmgr.internal.hwsetup.Widget.createWidgetInstance(aParent,...
                mfilename);
        end
    end
    
    methods
        function set.AboutSelection(obj, value)
            %set.AboutSelection - set text to be displayed in 'About Your
            %Selection' section.
            
            validateattributes(value, {'string', 'char'}, {});
            obj.setAboutSelection(value);
        end

        function aboutSelection = get.AboutSelection(obj)
            %get.AboutSelection - get text displayed in 'About Your
            %Selection' section.
            
            aboutSelection = obj.getAboutSelection();
        end
        
        function set.WhatToConsider(obj, value)
            %set.WhatToConsider - set text to be displayed in 'What To
            %Consider' section.
            
            validateattributes(value, {'string', 'char'}, {});
            obj.setWhatToConsider(value);
        end

        function whatToConsider = get.WhatToConsider(obj)
            %get.WhatToConsider - get text displayed in 'What To Consider'
            %section.
            
            whatToConsider = obj.getWhatToConsider();
        end
        
        function set.Additional(obj, value)
            %set.Additional - set text to be displayed in 'Additional'
            %section.
            
            validateattributes(value, {'string', 'char'}, {});
            obj.setAdditional(value);

        end

        function additional = get.Additional(obj)
            %get.Additional - get text displayed in 'Additional' section.
            
            additional = obj.getAdditional();
        end
    end
    
    methods(Abstract, Access = protected)
        %setAboutSelection - Technology specific implementation of setting 
        %AboutSelection.
        setAboutSelection(obj, value)
        
        %setWhatToConsider - Technology specific implementation of setting 
        %WhatToConsider.
        setWhatToConsider(obj, value)
        
        %setAdditional - Technology specific implementation of setting 
        %Additional.
        setAdditional(obj, value)
        
        %getAboutSelection - Technology specific implementation of getting 
        %AboutSelection.
        value = getAboutSelection(obj)
        
        %getWhatToConsider - Technology specific implementation of getting 
        %WhatToConsider.
        value = getWhatToConsider(obj)
        
        %getAdditional - Technology specific implementation of getting
        %Additional.
        value = getAdditional(obj)
    end
end