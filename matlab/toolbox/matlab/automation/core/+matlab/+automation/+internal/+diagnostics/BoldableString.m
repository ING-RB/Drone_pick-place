classdef BoldableString < matlab.automation.internal.diagnostics.FormattableStringDecorator
    % This class is undocumented and may change in a future release
    
    % Copyright 2016-2022 The MathWorks, Inc.
    
    properties (Dependent, SetAccess=private)
        Text string;
    end
    
    methods
        function str = BoldableString(strToCompose)
            str = str@matlab.automation.internal.diagnostics.FormattableStringDecorator(strToCompose);
            str = str.applyBoldHandling();
        end
        
        function txt = get.Text(str)
            txt = str.ComposedString.Text;
        end
    end
    
    methods(Access=protected)
        function str = postEnrich(str)
            import matlab.automation.internal.diagnostics.BoldedString;
            str = BoldedString(str);
        end
    end
end

% LocalWords:  Formattable Boldable Bolded
