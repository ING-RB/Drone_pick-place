classdef CompositeFormattableString < matlab.automation.internal.diagnostics.FormattableString
    % CompositeFormattableString - A FormattableString that holds onto other FormattableStrings.
    
    % Copyright 2016-2022 The MathWorks, Inc.
    
    properties (SetAccess=protected)
        ComposedString (1,:) matlab.automation.internal.diagnostics.FormattableString;
    end
    
    properties (Dependent, SetAccess=private)
        ComposedText string;
    end
    
    methods
        function composite = CompositeFormattableString(composedString)
            import matlab.automation.internal.diagnostics.FormattableString;
            assert(isa(composedString,'matlab.automation.internal.diagnostics.FormattableString') ...
                || isa(composedString,'string'),...
                'CompositeFormattableString:internal:sanityCheck','');
            composite.ComposedString = [FormattableString.empty(1,0),composedString];
        end
        
        function str = get.ComposedText(composite)
            str = [string.empty, composite.ComposedString.Text];
        end
    end
    
    methods (Sealed)
        function str = enrich(str)
            for idx = 1:numel(str.ComposedString)
                str.ComposedString(idx) = enrich(str.ComposedString(idx));
            end
            str = str.postEnrich();
        end
        
        function str = wrap(str, width)
            for idx = 1:numel(str.ComposedString)
                str.ComposedString(idx) = wrap(str.ComposedString(idx), width);
            end
        end
    end
    
    methods (Sealed, Access=protected)
        function str = applyIndention(str, indentionAmount)
            for idx = 1:numel(str.ComposedString)
                str.ComposedString(idx) = applyIndention(str.ComposedString(idx), indentionAmount);
            end
        end
        
        function str = applyBoldHandling(str)
            for idx = 1:numel(str.ComposedString)
                str.ComposedString(idx) = applyBoldHandling(str.ComposedString(idx));
            end
        end
    end
    
    methods(Access=protected)
        function str = postEnrich(str)
            % may be overridden by subclasses
        end
    end
end

% LocalWords:  Formattable
