classdef occupancyMap3DBuiltins < handle
%This class is for internal use only. It may be removed in the future.

%occupancyMap3DBuiltins Interface to builtins used for OccupancyMap3D
%
%   This class is a collection of functions used for interfacing with the
%   Octomap 3P library. Its main purpose is to dispatch function calls 
%   correctly when executed in MATLAB or code generation. During MATLAB 
%   execution, we call the existing MCOS C++ class. During code generation 
%   we use a codegen-compatible version.
%
%   See also nav.algs.internal.coder.occupancyMap3DBuildable

% Copyright 2020-2022 The MathWorks, Inc.

%#codegen

    properties
        %MCOSObj - MCOS interface object to octomap
        %   This is only used during MATLAB execution.
        MCOSObj = []
        
        %Octomap - Opaque C++ object
        %   This is only used during code generation.
        Octomap
    end    

    methods
        function obj = occupancyMap3DBuiltins(resolution)
        %MonteCarloLocalizationBuiltins Constructor

            if coder.target('MATLAB')
                % Create MCOS class in MATLAB
                obj.MCOSObj = nav.algs.internal.OctomapWrapper(resolution);
            else
                % Generate code through external dependency
                obj.Octomap = nav.algs.internal.coder.occupancyMap3DBuildable(resolution);
            end
        end
        
        function delete(obj)
            if ~isempty(obj.MCOSObj)
                delete(obj.MCOSObj);
            end
        end
    end

    methods
        function setClampingThreshold(obj, clampingThresMin, clampingThresMax)
            dObj = obj.getDispatchObj();
            dObj.setClampingThreshold(clampingThresMin, clampingThresMax);
        end
        
        function res = Resolution(obj)
            if coder.target('MATLAB')
                % Call MCOS method in MATLAB
                res = obj.MCOSObj.Resolution;
            else
                % Generate code through external dependency
                res = obj.Octomap.getResolution();
            end
        end
        
        function occThresh = OccupiedThreshold(obj)
            if coder.target('MATLAB')
                % Call MCOS method in MATLAB
                occThresh = obj.MCOSObj.OccupiedThreshold;
            else
                % Generate code through external dependency
                occThresh = obj.Octomap.getOccupiedThreshold();
            end
        end

        function freeThresh = FreeThreshold(obj)
            if coder.target('MATLAB')
                % Call MCOS method in MATLAB
                freeThresh = obj.MCOSObj.FreeThreshold;
            else
                % Generate code through external dependency
                freeThresh = obj.Octomap.getFreeThreshold();
            end
        end

        function occ = getOccupancy(obj, pos)
            dObj = obj.getDispatchObj();
            occ = dObj.getOccupancy(pos);
        end
        
        function tOcc = checkOccupancy(obj, pos)
            dObj = obj.getDispatchObj();
            tOcc = dObj.checkOccupancy(pos);
        end
        
        function setOccupiedThreshold(obj, val)
            if coder.target('MATLAB')
                % Call MCOS method in MATLAB
                obj.MCOSObj.OccupiedThreshold = val;
            else
                % Generate code through external dependency
                obj.Octomap.setOccupiedThreshold(val);
            end
        end

        function setFreeThreshold(obj, val)
            if coder.target('MATLAB')
                % Call MCOS method in MATLAB
                obj.MCOSObj.FreeThreshold = val;
            else
                % Generate code through external dependency
                obj.Octomap.setFreeThreshold(val);
            end
        end
        
        function str = serialization(obj)
            dObj = obj.getDispatchObj();
            str = dObj.serialization();
        end
        
        function deserialization(obj, pData)
            dObj = obj.getDispatchObj();
            dObj.deserialization(pData);
        end
        
        function setNodeValue(obj, xyz, prob, lazyEval)
            dObj = obj.getDispatchObj();
            dObj.setNodeValue(xyz, prob, lazyEval);
        end
        
        function updateNodeBoolean(obj, xyz, occupied, lazyEval)
            dObj = obj.getDispatchObj();
            dObj.updateNodeBoolean(xyz, occupied, lazyEval);
        end
        
        function updateNodeDouble(obj, xyz, probUpdate, lazyEval)
            dObj = obj.getDispatchObj();
            dObj.updateNodeDouble(xyz, probUpdate, lazyEval);
        end
        
        function inflate(obj, inflationRadius, occupiedThreshold)
            dObj = obj.getDispatchObj();
            dObj.inflate(inflationRadius, occupiedThreshold);
        end
        
        function insertPointCloud(obj, origin, points, maxRange, invModel, lazyEval, discretize)
            dObj = obj.getDispatchObj();
            dObj.insertPointCloud(origin, points, maxRange, invModel, lazyEval, discretize);
        end
        
        function out =  getRayIntersection(obj, ptStart, ptDirections, occupiedThreshold, ignoreUnknownCells, maxRange)
            dObj = obj.getDispatchObj();
            out = dObj.getRayIntersection(ptStart, ptDirections, occupiedThreshold, ignoreUnknownCells, maxRange);
        end
        
        function visData = extractVisualizationData(obj, maxDepth)
            % Call MCOS method in MATLAB
            % NOTE: occupancyMap3D.show does not support codegen, hence use
            % the MCOSObj always
            visData = obj.MCOSObj.extractVisualizationData(maxDepth);
        end
        
        function read(obj, filename)
            dObj = obj.getDispatchObj();
            dObj.read(filename);
            obj.setOccupiedThreshold(occupancyMap3D.OccupiedThresholdDefault);
            obj.setFreeThreshold(occupancyMap3D.FreeThresholdDefault);
        end
        
        function readBinary(obj, filename)
            dObj = obj.getDispatchObj();
            dObj.readBinary(filename);
            obj.setOccupiedThreshold(occupancyMap3D.OccupiedThresholdDefault);
            obj.setFreeThreshold(occupancyMap3D.FreeThresholdDefault);
        end
        
        function write(obj, filename)
            dObj = obj.getDispatchObj();
            dObj.write(filename);
        end
        
        function writeBinary(obj, filename)
            dObj = obj.getDispatchObj();
            dObj.writeBinary(filename);
        end
        
        function sz = memoryUsage(obj)
            dObj = obj.getDispatchObj();
            sz = dObj.memoryUsage();
        end
        
        function dims = getMapDimensions(obj)
            dObj = obj.getDispatchObj();
            dims = dObj.getMapDimensions();
        end
        
        function deserializationBinaryROSMsgData(obj, res, data)
            dObj = obj.getDispatchObj();
            dObj.deserializationBinaryROSMsgData(res, data);
        end
        
        function deserializationFullROSMsgData(obj, res, data)
            dObj = obj.getDispatchObj();
            dObj.deserializationFullROSMsgData(res, data);
        end
        
    end

    methods (Access = protected)
        function dObj = getDispatchObj(obj)
            if coder.target('MATLAB')
                % Call MCOS method in MATLAB
                dObj = obj.MCOSObj;
            else
                % Generate code through external dependency
                dObj = obj.Octomap;
            end
        end
    end
end
