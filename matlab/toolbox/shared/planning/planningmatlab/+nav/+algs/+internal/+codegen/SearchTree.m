classdef SearchTree < nav.algs.internal.InternalAccess & ...
                      coder.ExternalDependency
    %SEARCHTREE nav.algs.codegen.SearchTree (SearchTree codegen API, only used during codegen)
    
    %   Copyright 2019-2023 The MathWorks, Inc.
    
    %#codegen
    
    properties
        %BuiltinTree
        BuiltinTree
    end
    
    properties (Access = protected)
        %ActiveMetricId
        ActiveMetricId
        
        %TreeExtendsOutward Indicates whether the tree grows towards the 
        %   root (inward) or away from the root (outward)
        TreeExtendsOutward
        
        %MaxNumStates
        MaxNumStates
        
        %States
        States
        
        %NumStates
        NumStates
        
        %StateDim
        StateDim

        %BallRadiusConstant
        BallRadiusConstant

        %MaxConnectionDistance
        MaxConnectionDistance
    end


    properties
        %CustomizedStateSpace
        CustomizedStateSpace
    end
    
    methods (Static)
       
        function dName = getDescriptiveName(~)
            %getDescriptiveName Return descriptive name for external dependency
            dName = 'libmwplanningcodegen_SearchTree';
        end
        
        function tf = isSupportedContext(~)
            %isSupportedContext Determine if build context supports external dependency
            
            % We support both host and portable code generation
            tf = true;
        end
        
        function updateBuildInfo(buildInfo, buildConfig)
            %updateBuildInfo Update build information (for host codegen only)

            buildInfo.addIncludePaths(fullfile(matlabroot, 'extern', 'include', 'nav'));
            buildInfo.addIncludePaths(fullfile(matlabroot, 'extern', 'include', 'shared_autonomous'));
            
            % Add defines to OPTS group, so rapid accelerator recognizes these
            % defines. See g1762922 and g1974701 for more information.            
            buildInfo.addDefines('_USE_MATH_DEFINES', 'OPTS');
            
            % Always build with full sources
            
            buildInfo.addDefines('IS_NOT_MATLAB_HOST', 'OPTS');
            
            % Include sources for search tree implementation.
            planningDir = fullfile(matlabroot,'toolbox', ...
                'shared','planning','builtins','libsrc','planningcodegen');
            buildInfo.addSourceFiles('planningcodegen_cghelpers.cpp', planningDir);
            
            % Also include sources for Dubins and Reeds-Shepp C++
            % implementation. We cannot rely on MATLAB Coder
            % automatically adding these dependencies, since the C++
            % code in planningcodegen_cghelpers.cpp directly depends on
            % both Dubins and Reeds Shepp, even if only one of them is
            % used in MATLAB code.
            autonomousDir = fullfile(matlabroot,'toolbox', ...
                'shared','autonomous','builtins','libsrc','autonomouscodegen');
            buildInfo.addSourceFiles('autonomouscodegen_dubins.cpp', fullfile(autonomousDir, 'dubins'));
            buildInfo.addSourceFiles('autonomouscodegen_reeds_shepp.cpp', fullfile(autonomousDir, 'reeds_shepp'));
     
        end
        
    end


    methods
        function obj = SearchTree(startState, maxNumStates)
            %SEARCHTREE Constructor
            coder.inline('never');
            coder.cinclude('planningcodegen_cghelpers.hpp');
            
            obj.BuiltinTree = coder.opaquePtr('void', coder.internal.null);

            len = size(startState, 2);
            
            obj.BuiltinTree = coder.ceval('planningcodegen_createTree', startState, len);
            obj.ActiveMetricId = 0;
            obj.TreeExtendsOutward = true;
            obj.MaxNumStates = maxNumStates;
            obj.States = zeros(obj.MaxNumStates, len);
            obj.States(1,:) = startState;
            obj.NumStates = 1;
            obj.StateDim = len;
        end
        
        function delete(obj)
            %delete
            coder.inline('never');
            coder.cinclude('planningcodegen_cghelpers.hpp');
            
            if ~isempty(obj.BuiltinTree)
                coder.ceval('planningcodegen_destructTree', obj.BuiltinTree);
            end
        end
        
        function configureCommonCSMetric(obj, topologies, weights, isReversed)
            %configureCommonCSMetric
            coder.inline('never');
            coder.cinclude('planningcodegen_cghelpers.hpp');
            
            len = length(topologies);
            coder.ceval('planningcodegen_configureCommonCSMetric', obj.BuiltinTree, topologies, weights, len);

            obj.TreeExtendsOutward = ~isReversed;
            obj.ActiveMetricId = 1;
        end
        
        function configureDubinsMetric(obj, turningRadius, isReversed)
            %configureDubinsMetric
            coder.inline('never');
            coder.cinclude('planningcodegen_cghelpers.hpp');
            
            coder.ceval('planningcodegen_configureDubinsMetric', obj.BuiltinTree, turningRadius, isReversed);
            obj.TreeExtendsOutward = ~isReversed;
            
            obj.ActiveMetricId = 2;
        end
        
        function configureReedsSheppMetric(obj, turningRadius, reverseCost, isReversed)
            %configureReedsSheppMetric
            coder.inline('never');
            coder.cinclude('planningcodegen_cghelpers.hpp');

            coder.ceval('planningcodegen_configureReedsSheppMetric', obj.BuiltinTree, turningRadius, reverseCost, isReversed);
            obj.TreeExtendsOutward = ~isReversed;
            
            obj.ActiveMetricId = 3;
        end

        function out = extendsOutward(obj)
            %extendsOutward
            out = obj.TreeExtendsOutward;
        end
        
        function dists = customDistanceFcn(obj, states1, states2)
            %customDistanceFcn Only used when ActiveMetricId == 4
            if obj.TreeExtendsOutward
                dists = obj.CustomizedStateSpace.distance(states1, states2);
            else
                dists = obj.CustomizedStateSpace.distance(states2, states1);
            end
        end
        
        function setCustomizedStateSpace(obj, ss, isReversed)
            %setCustomizedStateSpace
            obj.CustomizedStateSpace = ss;
            obj.ActiveMetricId = 4;

            obj.TreeExtendsOutward = ~isReversed;

        end


        function numNodes = getNumNodes(obj)
            %getNumNodes
            coder.inline('never');
            coder.cinclude('planningcodegen_cghelpers.hpp');

            numNodes = coder.nullcopy(0);
            numNodes = coder.ceval('planningcodegen_getNumNodes', obj.BuiltinTree);
        end
        
        function newNodeId = insertNode(obj, newState, parentId)
            %insertNode
            coder.inline('never');
            coder.cinclude('planningcodegen_cghelpers.hpp');
            
            newNodeId = 0;
            len = size(newState, 2);
            
            isSuccess = coder.nullcopy(true);
            if obj.ActiveMetricId == 4
                if ~isempty(obj.CustomizedStateSpace)
                    parentState = obj.getNodeState(parentId);
                    precomputedCost = obj.customDistanceFcn(parentState, newState);
                    isSuccess = coder.ceval('planningcodegen_insertNodeWithPrecomputedCost', obj.BuiltinTree, newState, len, precomputedCost, parentId, coder.ref(newNodeId));
                else
                    isSuccess = false;
                    newNodeId = nan;
                end
            else
                isSuccess = coder.ceval('planningcodegen_insertNode', obj.BuiltinTree, newState, len, parentId, coder.ref(newNodeId));
            end
            if ~isSuccess
                newNodeId = nan;
            else
                obj.States(newNodeId + 1,:) = newState;
                obj.NumStates = newNodeId + 1;
            end
        end
        
        function idx = nearestNeighbor(obj, inputState)
            %nearestNeighbor
            coder.inline('never');
            coder.cinclude('planningcodegen_cghelpers.hpp');
                
            if obj.ActiveMetricId == 4
                %dists = obj.CustomizedMetric(inputState, obj.States(1:obj.NumStates,:));
                if ~isempty(obj.CustomizedStateSpace)
                    dists = obj.customDistanceFcn(obj.States(1:obj.NumStates,:), inputState);
                else
                    dists = ones(obj.NumStates,1);
                end
                % coder.ceval call requires idx to be a scalar at compile-time.
                % For making idx a scalar, making sure dists is a column vector of distances.
                % This ensures idx is a compile-time scalar.
                [~, idx] = min(dists(:));
                idx = idx - 1;

            else
                idx = coder.nullcopy(0);
                idx = coder.ceval('planningcodegen_nearestNeighbor', obj.BuiltinTree, inputState, obj.StateDim);
            end
        end
        
        function state = getNodeState(obj, idx)
            %getNodeState
            coder.inline('never');
            coder.cinclude('planningcodegen_cghelpers.hpp');
            
            state = zeros(1, obj.StateDim);
            isSuccess = coder.nullcopy(0);
            isSuccess = coder.ceval('planningcodegen_getNodeState', obj.BuiltinTree, idx, coder.ref(state));
            if ~isSuccess
                state = nan(1, obj.StateDim);
            end
        end

        function treeData = inspect(obj)
            %inspect
            coder.inline('never');
            coder.cinclude('planningcodegen_cghelpers.hpp');

            numNodesInSeq = 3*obj.NumStates - 1;
            td = coder.nullcopy(zeros(numNodesInSeq, obj.StateDim)); 
            
            coder.ceval('planningcodegen_inspect', obj.BuiltinTree, coder.ref(td));
            treeData = reshape(td, numNodesInSeq, obj.StateDim);
            treeData = treeData';
        end

        function status = rewire(obj, nodeId, newParentNodeId)
            %rewire
            coder.inline('never');
            coder.cinclude('planningcodegen_cghelpers.hpp');
            
            status = coder.nullcopy(0);

            if obj.ActiveMetricId == 4
                parentState = obj.getNodeState(newParentNodeId);
                state = obj.getNodeState(nodeId);
                if ~isempty(obj.CustomizedStateSpace)
                    precomputedCost = obj.customDistanceFcn(parentState, state);
                    status = coder.ceval('planningcodegen_rewireWithPrecomputedCost', obj.BuiltinTree, nodeId, newParentNodeId, precomputedCost);
                else
                    status = 1;
                end
            else
                status = coder.ceval('planningcodegen_rewire', obj.BuiltinTree, nodeId, newParentNodeId);
            end
        end

        function states = tracebackToRoot(obj, nodeId)
            %tracebackToRoot
            coder.inline('never');
            coder.cinclude('planningcodegen_cghelpers.hpp');
            
            numNodes = coder.nullcopy(0);
            nodeStateSeq = coder.nullcopy(zeros(obj.StateDim, nodeId + 1)); % allocate a matrix that is large enough
            coder.ceval('planningcodegen_tracebackToRoot', obj.BuiltinTree, nodeId, coder.ref(nodeStateSeq), coder.ref(numNodes));

            states = nodeStateSeq(1:obj.StateDim, 1:numNodes);
        end

        function cost = getNodeCostFromRoot(obj, nodeId)
            %getNodeCostFromRoot
            coder.inline('never');
            coder.cinclude('planningcodegen_cghelpers.hpp');

            cost = coder.nullcopy(0);
            cost = coder.ceval('planningcodegen_getNodeCostFromRoot', obj.BuiltinTree, nodeId);
        end

        function setBallRadiusConstant(obj, rc)
            %setBallRadiusConstant
            coder.inline('never');
            coder.cinclude('planningcodegen_cghelpers.hpp');

            coder.ceval('planningcodegen_setBallRadiusConstant', obj.BuiltinTree, rc);
            obj.BallRadiusConstant = rc;
        end

        function setMaxConnectionDistance(obj, dist)
            %setMaxConnectionDistance
            coder.inline('never');
            coder.cinclude('planningcodegen_cghelpers.hpp');
            
            coder.ceval('planningcodegen_setMaxConnectionDistance', obj.BuiltinTree, dist);
            obj.MaxConnectionDistance = dist;
        end

        function nearIndices = near(obj, state)
            %near
            coder.inline('never');
            coder.cinclude('planningcodegen_cghelpers.hpp');

            if obj.ActiveMetricId == 4
                if ~isempty(obj.CustomizedStateSpace)
                    dists = obj.customDistanceFcn(obj.States(1:obj.NumStates,:), state);
                else
                    dists = ones(obj.NumStates,1);
                end
                % compute ball radius
                [sortedDists, originalIds] = sort(dists); % ascending
                radius = power(obj.BallRadiusConstant * log(obj.NumStates) / obj.NumStates, 1 / obj.StateDim);
                radius = min(radius, obj.MaxConnectionDistance);
                nearIds = originalIds( sortedDists < radius );
                nearIndices = nearIds' - 1;
            else

                numNearNodes = coder.nullcopy(0);
                nearNodeIds = coder.nullcopy(zeros(1, obj.NumStates));
                coder.ceval('planningcodegen_near', obj.BuiltinTree, state, coder.ref(nearNodeIds), coder.ref(numNearNodes));
                nearIndices = nearNodeIds(1:numNearNodes);
            end
        end
    end
    
end
