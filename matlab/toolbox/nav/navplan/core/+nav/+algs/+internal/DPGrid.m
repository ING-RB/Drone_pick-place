classdef DPGrid < nav.algs.internal.InternalAccess
% This class is for internal use only. It may be removed in the future.

% DPGrid MCOS interface to builtins used for DPGrid algorithm

% Copyright 2024 The MathWorks, Inc.

%#codegen

    properties (Access=private)
        %MCOSObj - MCOS interface object to DPGrid
        %   This is only used during MATLAB execution.
        MCOSObj

        %Resolution Map resolution
        Resolution      
    end

    methods
        function obj = DPGrid(mapMatrix, resolution)
        %DPGrid Constructor for DPGrid builtin class
            validateattributes(mapMatrix, {'logical'}, {'2d', 'nonempty'}, 'DPGridBuiltins', 'mapMatrix')
            obj.MCOSObj = nav.algs.internal.builtin.DPGrid(mapMatrix);
            obj.Resolution = resolution;            
        end

        function setGoal(obj, goal)
        % setGoal Set goal for DP search

            % goal input is location of grid cell corresponding to one-indexing
            % [1,1] <= goal <= map.GridSize
            % Convert to zero-indexing required by the builtin DPGrid           
            goal = goal-1;
            goal = uint32(goal);

            % Set goal
            obj.MCOSObj.setGoal(goal);
        end

        function cost = getPathCost(obj, start)
        % getPathCost Get the path cost for given start

            % start input is location of grid cell corresponding to one-indexing
            % [1,1] <= start <= map.GridSize
            % Convert to zero-indexing required by the builtin DPGrid  
            start = start-1;
            start = uint32(start);

            % Compute path cost for the specified start
            cost = obj.MCOSObj.getPathCost(start)/obj.Resolution; % cells/(cells/m)
        end

        function delete(obj)            
            if ~isempty(obj.MCOSObj)
                delete(obj.MCOSObj);
            end
        end
    end

    methods (Static = true, Access = private)
        function name = matlabCodegenRedirect(~)
        % matlabCodegenRedirect Redirect to buildable class that calls
        % C-API
            name = 'nav.algs.internal.codegen.DPGrid';
        end
    end
end
