classdef ValueClassCustomCompactDisplayProvider < matlab.mixin.CustomDisplay ...
    & matlab.mixin.CustomCompactDisplayProvider
    %
        
    % Copyright 2024 The MathWorks, Inc.
    
    methods(Access = private, Static)
        % Redirect to enable codegen. We need this until
        % matlab.mixin.CustomCompactDisplayProvider supports codegen
        function name = matlabCodegenRedirect(~)
            name = 'matlabshared.tracking.internal.EmptyValueClass';
        end
    end

    methods (Hidden)
        function varargout = compactRepresentationForColumn(varargin)
            [varargout{1:nargout}] = compactRepresentationForColumn@matlab.mixin.CustomCompactDisplayProvider(varargin{:});
        end

        function varargout = compactRepresentationForSingleLine(varargin)
            [varargout{1:nargout}] = compactRepresentationForSingleLine@matlab.mixin.CustomCompactDisplayProvider(varargin{:});
        end
    end

end