classdef WrappableStringDecorator < matlab.automation.internal.diagnostics.FormattableString
    % This class is undocumented and may change in a future release.
    
    % Copyright 2016-2022 The MathWorks, Inc.
    
    properties (Dependent, SetAccess=private)
        Text string;
    end
    
    properties (SetAccess=private)
        StringToWrap matlab.automation.internal.diagnostics.LeafFormattableString;
    end
    
    properties (SetAccess=private)
        IndentionAmount double = 0;
    end
    
    methods
        function str = WrappableStringDecorator(stringToWrap)
            str.StringToWrap = stringToWrap;
        end
        
        function txt = get.Text(str)
            txt = str.StringToWrap.Text;
        end
        
        function str = enrich(str)
            str.StringToWrap = enrich(str.StringToWrap);
        end
        
        function str = wrap(str, width)
            import matlab.automation.internal.diagnostics.WrappedString;
            str = WrappedString(str, width);
        end
    end
    
    methods (Access=protected)
        function str = applyIndention(str, indentionAmount)
            str.IndentionAmount = str.IndentionAmount + indentionAmount;
        end
        
        function str = applyBoldHandling(str)
            str.StringToWrap = str.StringToWrap.applyBoldHandling();
        end
    end
end

% LocalWords:  Formattable
