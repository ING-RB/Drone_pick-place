classdef ValueClassCustomDisplay <  matlab.mixin.CustomDisplay
%

% Copyright 2023 The MathWorks, Inc.

    methods(Access = private, Static)
        % Redirect to enable codegen. We need this until
        % matlab.mixin.CustomDisplay supports codegen
        function name = matlabCodegenRedirect(~)
            name = 'matlabshared.env_encoder.internal.EmptyValueClass';
        end
    end
end
