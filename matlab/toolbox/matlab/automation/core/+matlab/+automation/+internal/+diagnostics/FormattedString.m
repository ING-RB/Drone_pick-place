classdef FormattedString < matlab.automation.internal.diagnostics.CompositeFormattableString
    %

    % Copyright 2016-2022 The MathWorks, Inc.
    
    properties (Dependent, SetAccess=private)
        Text string;
    end
    
    properties (SetAccess=immutable)
        Format string;
    end
    
    methods
        function formatted = FormattedString(format, varargin)
            import matlab.automation.internal.diagnostics.FormattableString;
            
            formatted = formatted@matlab.automation.internal.diagnostics.CompositeFormattableString(FormattableString.fromMixedTypes(varargin{:}));
            formatted.Format = format;
        end
        
        function txt = get.Text(str)
            txt = sprintf(str.Format, str.ComposedText);
        end
    end
end

% LocalWords:  Formattable strs
