classdef FormattableStringDecorator < matlab.automation.internal.diagnostics.CompositeFormattableString
    % This class is undocumented and may change in a future release.
    
    % Copyright 2018-2022 The MathWorks, Inc.
    methods
        function str = FormattableStringDecorator(strToCompose)
            if ischar(strToCompose)
                strToCompose = string(strToCompose);
            end
            assert(isscalar(strToCompose),'FormattableStringDecorator:internal:sanityCheck','');
            
            str = str@matlab.automation.internal.diagnostics.CompositeFormattableString(strToCompose);
        end
    end
end
