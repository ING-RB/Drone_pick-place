classdef AlternativeRichString < matlab.automation.internal.diagnostics.FormattableStringDecorator
    % This class is undocumented and may change in a future release.
    
    % Copyright 2016-2022 The MathWorks, Inc.
    
    properties (SetAccess=private)
        Text string;
    end
    
    methods
        function str = AlternativeRichString(plainText, richString)
            plainText = string(plainText);
            assert(isscalar(plainText),'AlternativeRichString:internal:sanityCheck','');
            
            str = str@matlab.automation.internal.diagnostics.FormattableStringDecorator(richString);
            str.Text = plainText;
        end
    end
    
    methods(Access=protected)
        function str = postEnrich(str)
            str = str.ComposedString;
        end
    end
end

% LocalWords:  Formattable
