%matlabshared.planning.internal.PathPlanner Interface for path planning.

% Copyright 2017-2018 The MathWorks, Inc.

%#codegen
classdef PathPlanner < matlabshared.planning.internal.EnforceScalarHandle
    
    properties (Constant, Abstract, Access = protected)
        %Name
        %   Name of planner
        Name
        
        %PoseDim
        %   Number of dimensions in planner pose
        PoseDim
    end
    
    methods (Abstract)
        %plan
        %   plan a path between two states.
        varargout = plan(this, varargin)
        
        %plot
        %   plot a planned path on a map.
        varargout = plot(this, varargin)
    end
    
    %----------------------------------------------------------------------
    % Code Generation
    %----------------------------------------------------------------------
    methods (Access = public, Static=true, Hidden)
        %------------------------------------------------------------------
        function props = matlabCodegenNonTunableProperties(~)
            
            props = {'Name', 'PoseDim'};
        end
    end
    
end
