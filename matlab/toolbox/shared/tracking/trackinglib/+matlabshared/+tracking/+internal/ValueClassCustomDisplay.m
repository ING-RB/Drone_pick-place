classdef ValueClassCustomDisplay <  matlab.mixin.CustomDisplay
    %
        
    % Copyright 2016-2020 The MathWorks, Inc.
    
    methods(Access = private, Static)
        % Redirect to enable codegen. We need this until
        % matlab.mixin.CustomDisplay supports codegen
        function name = matlabCodegenRedirect(~)
            name = 'matlabshared.tracking.internal.EmptyValueClass';
        end
    end
end
