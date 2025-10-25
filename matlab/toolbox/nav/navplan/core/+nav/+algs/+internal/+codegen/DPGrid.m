classdef DPGrid < coder.ExternalDependency & nav.algs.internal.InternalAccess
%This class is for internal use only. It may be removed in the future.

% DPGrid C-API interface to builtins used for DPGrid algorithm

% Copyright 2024 The MathWorks, Inc.

%#codegen

    methods(Static)

        function name = getDescriptiveName(~)
        %getDescriptiveName Get name for external dependency
            name = 'DPGrid';
        end

        function updateBuildInfo(buildInfo, buildConfig) %#ok<INUSD>
        %updateBuildInfo Add headers, libraries, and sources to the build info

        % Include paths containing the extern header files
            buildInfo.addIncludePaths(fullfile(matlabroot, 'extern', 'include', 'nav'));            

            % Always build with full sources (for both host and target codegen)
            buildInfo.addSourcePaths({fullfile(matlabroot,'toolbox', ...
                       'nav','navplan','builtins','libsrc','dpgridcodegen')});
            buildInfo.addSourceFiles('dpgrid_api.cpp');
            buildInfo.addSourceFiles('dpgrid.cpp');
        end

        function isSupported = isSupportedContext(~)
        %isSupportedContext Determine if external dependency supports
        %this build context

        % Code generation is supported for both host and target
        % (portable) code generation.
            isSupported = true;
        end
    end


    properties (Access = private)
        % DPGridInternal
        DPGridInternal

        %Resolution Map resolution
        Resolution

        %Rows Number of rows in map matrix
        Rows

        %Cols Number of cols in map matrix
        Cols
    end

    methods
        % Actual methods to C-API for the DPGrid

        function obj = DPGrid(mapMatrix, resolution)
        % DPGrid create DPGrid object
            validateattributes(mapMatrix, {'logical'}, {'2d', 'nonempty'}, 'DPGridBuiltins', 'mapMatrix')            
            coder.cinclude('dpgrid_api.hpp');
            obj.DPGridInternal = coder.opaquePtr('void', coder.internal.null);
			[rows, cols] = size(mapMatrix);
            obj.DPGridInternal = coder.ceval('dpgrid_construct', mapMatrix, uint32(rows), uint32(cols));
            obj.Resolution = resolution;
        end


        function delete(obj)
        % delete Destructor

            coder.cinclude('dpgrid_api.hpp');
            if ~isempty(obj.DPGridInternal)
                coder.ceval('dpgrid_destruct', obj.DPGridInternal);
            end
        end

        function setGoal(obj, goal)
        % setGoal Set goal node ID for DP search
            
            % goal input is location of grid cell corresponding to one-indexing
            % [1,1] <= goal <= map.GridSize
            % Convert goal to zero-indexing required by the builtin DPGrid
            goal = goal-1;
            goal = uint32(goal);

            % Set goal            
            coder.cinclude('dpgrid_api.hpp');
            coder.ceval('dpgrid_setGoal', obj.DPGridInternal, goal);
        end

        function cost = getPathCost(obj, start)
        %getPathCost Get path cost for a specified node

            % start input is location of grid cell corresponding to one-indexing
            % [1,1] <= start <= map.GridSize
            % Convert to zero-indexing required by the builtin DPGrid
            start = start-1;
            start = uint32(start);

            % Compute path cost for the specified start            
            coder.cinclude('dpgrid_api.hpp');
            cost = coder.nullcopy(0.0);
            cost = coder.ceval('dpgrid_getPathCost', obj.DPGridInternal, start);
            cost = cost/obj.Resolution; % cells/(cells/m)
        end
    end
end
