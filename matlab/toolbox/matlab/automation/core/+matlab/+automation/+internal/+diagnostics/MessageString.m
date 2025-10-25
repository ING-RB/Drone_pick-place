classdef MessageString < matlab.automation.internal.diagnostics.DelegateFunctionString
    % This class is undocumented and may change in a future release.
    
    % Note: MessageString(...) accepts the same inputs as message(...).
    
    % Copyright 2016-2022 The MathWorks, Inc.
    methods
        function str = MessageString(varargin)
            delegateFcn = @messageString;
            str = str@matlab.automation.internal.diagnostics.DelegateFunctionString(...
                delegateFcn, varargin{:});
        end
    end
end

function str = messageString(varargin)
str = getString(message(varargin{:}));
end