classdef CustomDisplay <  handle & matlab.mixin.CustomDisplay
%CustomDisplay Codegen compatible class for displaying custom properties
%
% This class is for internal use only

    %   Copyright 2020 The MathWorks, Inc.
    
    methods(Access = private, Static)
        % Redirect to enable codegen. We need this until
        % matlab.mixin.CustomDisplay supports codegen
        function name = matlabCodegenRedirect(~)
            name = 'handle';
        end
    end
end