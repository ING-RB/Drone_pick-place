classdef PlainString < matlab.automation.internal.diagnostics.LeafFormattableString
    %

    % Copyright 2016-2022 The MathWorks, Inc.
    
    properties (SetAccess=private)
        Text string = "";
    end
    
    methods
        function str = PlainString(text)
            if nargin > 0
                str.Text = text;
            end
        end
    end
end

% LocalWords:  Formattable
