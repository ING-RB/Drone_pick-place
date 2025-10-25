classdef SearchTree < nav.algs.internal.InternalAccess
    %SEARCHTREE nav.algs.internal.SearchTree wrapper
    
    %   Copyright 2019-2021 The MathWorks, Inc.
    
    properties
        %BuiltinTree
        BuiltinTree
    end
    
    methods
        function obj = SearchTree(startState, ~)
            %SEARCHTREE Constructor
            obj.BuiltinTree = nav.algs.internal.builtin.SearchTree(startState);
        end

        function out = extendsOutward(obj)
            %extendsOutward
            out = obj.BuiltinTree.ExtendsOutward;
        end
        
        function numNodes = getNumNodes(obj)
            %getNumNodes
            numNodes = obj.BuiltinTree.getNumNodes();
        end
        
        function newNodeId = insertNode(obj, newState, parentId)
            %insertNode
            newNodeId = obj.BuiltinTree.insertNode(newState, parentId);
        end
        
        function idx = nearestNeighbor(obj, randState)
            %nearestNeighbor
            idx = obj.BuiltinTree.nearestNeighbor(randState);
        end
        
        function configureCommonCSMetric(obj, topologies, weights, isReversed)
            %configureCommonCSMetric
            obj.BuiltinTree.configureCommonCSMetric(topologies, weights, isReversed);
        end
        
        function configureDubinsMetric(obj, turningRadius, isReversed)
            %configureDubinsMetric
            obj.BuiltinTree.configureDubinsMetric(turningRadius, isReversed);
        end
        
        function configureReedsSheppMetric(obj, turningRadius, reverseCost, isReversed)
            %configureReedsSheppMetric
            obj.BuiltinTree.configureReedsSheppMetric(turningRadius, reverseCost, isReversed);
        end
        
        function setCustomizedStateSpace(obj, ss, isReversed)
            %setCustomizedStateSpace
            obj.BuiltinTree.configureCustomizedMetric(@ss.distance, isReversed);
        end
        
        function configureCustomizedMetric(obj, callbackFcn, isReversed)
            %configureCustomizedMetric
             obj.BuiltinTree.configureCustomizedMetric(callbackFcn, isReversed);
        end
        
        function state = getNodeState(obj, idx)
            %getNodeState
            state = obj.BuiltinTree.getNodeState(idx);
        end

        function treeData = inspect(obj)
            %inspect
            treeData = obj.BuiltinTree.inspect();
        end

        function status = rewire(obj, nodeIdx, newParentNodeIdx)
            %rewire
            status = obj.BuiltinTree.rewire(nodeIdx, newParentNodeIdx);
        end

        function states = tracebackToRoot(obj, nodeId)
            %tracebackToRoot
            states = obj.BuiltinTree.tracebackToRoot(nodeId);
        end

        function cost = getNodeCostFromRoot(obj, nodeId)
            %getNodeCostFromRoot
            cost = obj.BuiltinTree.getNodeCostFromRoot(nodeId);
        end

        function setBallRadiusConstant(obj, rc)
            %setBallRadiusConstant
            obj.BuiltinTree.setBallRadiusConstant(rc);
        end

        function setMaxConnectionDistance(obj, dist)
            %setMaxConnectionDistance
            obj.BuiltinTree.setMaxConnectionDistance(dist);
        end

        function nearIndices = near(obj, state)
            %near
            nearIndices = obj.BuiltinTree.near(state);
        end
    end
    
    methods (Static = true, Access = private)
        function name = matlabCodegenRedirect(~)
            name = 'nav.algs.internal.codegen.SearchTree';
        end
    end
end

