classdef HTMLTextWrapper < ...
        matlab.hwmgr.internal.hwsetup.appdesigner.HTMLTextComponentWrapper
    %This class is undocumented and may change in a future release.
    
    %HTMLTABLEWRAPPER - This class acts as a wrapper for HTML tables
    %constructed using UI Components. This hides some of the implementation
    %quirkiness around managing tables.
    
    % Copyright 2023 The MathWorks, Inc.
    
    properties
        Text
    end
    
    properties(Dependent)
        BackgroundColor
    end
    
    methods
        function obj = HTMLTextWrapper(varargin)
            obj@matlab.hwmgr.internal.hwsetup.appdesigner.HTMLTextComponentWrapper(varargin{:});
        end

        function formatTextForDisplay(obj)
            import matlab.hwmgr.internal.hwsetup.util.*;
            
            formattedText = obj.Text;
            formattedText = HTMLStyles.applyErrorStyle(formattedText);
            formattedText = HTMLStyles.applyHeaderStyle(formattedText);
            
            obj.LabelComponent.Text = formattedText;
        end
    end
    
    %----------------------------------------------------------------------
    % setter methods
    %----------------------------------------------------------------------
    methods
        function set.BackgroundColor(obj, color)
            if isa(color, 'char') && startsWith(color, '--')
                % If input is a semantic variable, apply the theme color
                matlab.hwmgr.internal.hwsetup.util.Color.applyThemeColor(obj.ContainerComponent.Children, 'BackgroundColor', color);
            else
                % If input is an RGB triplet/color-string, set it directly 
                set(obj.ContainerComponent.Children, 'BackgroundColor', color);
            end
        end

        function set.Text(obj, value)
           obj.Text = value;
           obj.formatTextForDisplay();
        end
    end
    
    %----------------------------------------------------------------------
    % getter methods
    %----------------------------------------------------------------------
    methods
        function color = get.BackgroundColor(obj)
            color = obj.ContainerComponent.BackgroundColor;
        end
        
        function text = get.Text(obj)
           text = obj.Text; 
        end
    end
end