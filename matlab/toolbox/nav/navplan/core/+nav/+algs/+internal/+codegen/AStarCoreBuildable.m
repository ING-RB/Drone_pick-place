classdef AStarCoreBuildable < coder.ExternalDependency & nav.algs.internal.InternalAccess
    %This class is for internal use only. It may be removed in the future.

    %AStarCoreBuildable Buildable class for core A* code generation
    %
    %   See also nav.algs.internal.AStarCoreBuiltins.

    % Copyright 2022-2024 The MathWorks, Inc.

    %#codegen
    
    methods (Static)
        % Abstract method of coder.ExternalDependency that need to be
        %implemented

        function name = getDescriptiveName(~)
            %getDescriptiveName Get name for external dependency
            name = 'AStarCore';
        end

        function updateBuildInfo(buildInfo, buildConfig) %#ok<INUSD>
            %updateBuildInfo Add headers, libraries, and sources to the build info

            % Include paths containing the extern header files
            buildInfo.addIncludePaths(fullfile(matlabroot, 'extern', 'include', 'nav'));

            % Always build with full sources (for both host and target codegen)
            buildInfo.addSourcePaths({fullfile(matlabroot,'toolbox', ...
                'nav','navplan','builtins','libsrc','astarcodegen')});
            buildInfo.addSourceFiles('astarcore_api.cpp');
            buildInfo.addSourceFiles('astarcore.cpp');
        end

        function isSupported = isSupportedContext(~)
            %isSupportedContext Determine if external dependency supports this build context

            % Code generation is supported for both host and target
            % (portable) code generation.
            isSupported = true;
        end
    end

    properties (Access = private)
        %AStarCoreInternal
        AStarCoreInternal
    end

    methods
        % Actual methods to C-API for the AStarCore

        function obj = AStarCoreBuildable()
            % AStarCoreBuildable create AStarCore object 
            
            coder.inline('always');
            coder.cinclude('astarcore_api.hpp');
            obj.AStarCoreInternal = coder.opaque('void*','NULL');
            obj.AStarCoreInternal = coder.ceval('astarcore_construct');
        end

        function delete(obj)
            % delete Destructor

            coder.inline('always');
            coder.cinclude('astarcore_api.hpp');
            if ~isempty(obj.AStarCoreInternal)
                coder.ceval('astarcore_destruct', obj.AStarCoreInternal);
            end
        end

        function setStart(obj, start)
            % setStart Set start node ID for A* search

            coder.inline('always');
            coder.cinclude('astarcore_api.hpp');

            % Call the C API
            coder.ceval('astarcore_setStart', obj.AStarCoreInternal, uint32(start));
        end

        function setGoal(obj, goal)
            % setGoal Set goal node ID for A* search
            
            coder.inline('always');
            coder.cinclude('astarcore_api.hpp');

            % Call the C API
            coder.ceval('astarcore_setGoal', obj.AStarCoreInternal, uint32(goal));
        end

        function currentNodeID = getCurrentNode(obj)
            % getCurrentNode Get current node ID from A* search loop
            % The current node is popped from the priority queue

            coder.inline('always');
            coder.cinclude('astarcore_api.hpp');
            currentNodeID = coder.nullcopy(0);

            % Call the C API
            currentNodeID = coder.ceval('astarcore_getCurrentNode', obj.AStarCoreInternal);
        end

        function loopThroughNeighbors(obj, neighbors, transitionCosts, heuristicCosts)
            % loopThroughNeighbors Loop through neighbor node IDs and update the openSet, gScore etc.
           
            coder.inline('always');
            coder.cinclude('astarcore_api.hpp');
            nSize = length(neighbors);

            % Call the C API
            coder.ceval('astarcore_loopThroughNeighbors', obj.AStarCoreInternal,...
                uint32(nSize), uint32(neighbors), transitionCosts, heuristicCosts);
        end

        function pathNodeIDs = getPath(obj)
            % getPath Get the path output node IDs after the A* search
            
            coder.inline('always');
            coder.cinclude('astarcore_api.hpp');
            pthSize = getPathSize(obj);
            pathNodeIDs = coder.nullcopy(zeros(1, pthSize));

            % Call the C API
            coder.ceval('astarcore_getPath', obj.AStarCoreInternal, coder.ref(pathNodeIDs));
        end

        function cost = getPathCost(obj)
            % getPathCost Get the path cost output after A* search

            coder.inline('always');
            coder.cinclude('astarcore_api.hpp');
            cost = coder.nullcopy(0.0);

            % Call the C API
            cost = coder.ceval('astarcore_getPathCost', obj.AStarCoreInternal);
        end
        
        function exploredNodeIDs = getExploredNodes(obj)
            % getExploredNodes Get the explored node IDs after the A* search

            coder.inline('always');
            coder.cinclude('astarcore_api.hpp');
            numExploredNodes = getNumExploredNodes(obj);
            exploredNodeIDs = coder.nullcopy(zeros(1, numExploredNodes));

            % Call the C API
            coder.ceval('astarcore_getExploredNodes', obj.AStarCoreInternal, coder.ref(exploredNodeIDs));
        end

        function stop = stopCondition(obj)
            % stopCondition  Get stop condition when the A* search is
            % complete

            coder.inline('always');
            coder.cinclude('astarcore_api.hpp');
            stop = coder.nullcopy(0);

            % Call the C API
            stop = coder.ceval('astarcore_stopCondition', obj.AStarCoreInternal);
            stop = logical(stop);
        end
    end

    methods(Access=private)
        function pthSize = getPathSize(obj)
            % getPathSize Get the size of the path during the A* search

            coder.inline('always');
            coder.cinclude('astarcore_api.hpp');
            pthSize = coder.nullcopy(0);

            % Call the C API
            pthSize = coder.ceval('astarcore_getPathSize', obj.AStarCoreInternal);
        end

        function numExploredNodes = getNumExploredNodes(obj)
            % getNumExploredNodes Get the number of explored nodes during
            % the A* search
           
            coder.inline('always');
            coder.cinclude('astarcore_api.hpp');
            numExploredNodes = coder.nullcopy(0);

            % Call the C API
            numExploredNodes = coder.ceval('astarcore_getNumExploredNodes', obj.AStarCoreInternal);
        end
    end
end
