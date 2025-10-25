
%

%   Copyright 2017 The MathWorks, Inc.

classdef CustomDisplay <  handle & matlab.mixin.CustomDisplay
    
    methods(Access = private, Static)
        % Redirect to enable codegen. We need this until
        % matlab.mixin.CustomDisplay supports codegen
        function name = matlabCodegenRedirect(~)
            name = 'handle';
        end
    end
end