classdef SensorBase < handle
    % Any sensor that wants to leverage the Sensor Simulation Framework and
    % be compatible with SensorSim should derive from this class

    % Copyright 2022-2023 The MathWorks, Inc.

    %#codegen
    
    properties (Hidden)
        SupportsSensorSimulation = true;
    end
    
    properties (Hidden, Dependent, SetAccess=private)
        SensorSim;
        ConnectedToScenario;
    end

    properties (Transient, GetAccess=protected, SetAccess=?matlabshared.scenario.SensorSimulation.SensorSim)
        SensorBlockPath char = '';
    end

    properties (Access=protected)
        SensorBaseSensorID;
        SensorSimCacheID;
    end

    % Will give access to all classes and sub-classes of SensorBase and SensorSim
    properties (Access={?matlabshared.scenario.SensorSimulation.SensorBase,?matlabshared.scenario.SensorSimulation.SensorSim})
        SensorActorIDs (1,:) uint64
    end

    methods (Access = {?matlabshared.scenario.SensorSimulation.SensorSim})
        function sensorSimCacheID = getSensorSimCacheID(obj)
            coder.extrinsic('bdroot')
            coder.extrinsic('gcb')

            sensorSimCacheID = '';
            if isa(obj,'matlab.System') && obj.getExecPlatformIndex() 
                % Sensor System Block - assuming this is called from the
                % context of block (SysObj) code so gcb == "the block"
                sensorSimCacheID = coder.const(bdroot(gcb));
            elseif ~isempty(obj.SensorSimCacheID)
                sensorSimCacheID = coder.const(obj.SensorSimCacheID);
            end
        end
    end

    methods
        function sensorSim = get.SensorSim(obj)
            uniqueID = obj.getSensorSimCacheID();
                        
            if coder.target('MATLAB')
                sensorSim = [];
                if isempty(obj.SensorBaseSensorID)
                    obj.SensorBaseSensorID = obj.getSensorIndex();
                end
                if ~isempty(uniqueID)
                    sensorSim = matlabshared.scenario.internal.SSF.getSensorSim(uniqueID, obj.SensorBaseSensorID);
                end
            else
                sensorSim = matlabshared.scenario.SensorSimulation.coder.SensorSimCoder(uniqueID);
            end
        end

        function tf = get.ConnectedToScenario(obj)
            if coder.target('MATLAB')
                cacheID = obj.getSensorSimCacheID();
                if isempty(obj.SensorBaseSensorID)
                    % protected method. Sensor authors can overload
                    % getSensorIndex() since a call to config can be expensive
                    obj.SensorBaseSensorID = obj.getSensorIndex();
                end   
                tf = ~isempty(cacheID) && ...
                    matlabshared.scenario.internal.SSF.cachedSensorSimExists(cacheID, obj.SensorBaseSensorID);
            else
                cacheID = obj.getSensorSimCacheID();
                tf = ~isempty(cacheID) && matlabshared.scenario.SensorSimulation.coder.SensorSimCoderUtils.connectedToScenario(cacheID);
            end
        end
    end

    methods(Access=protected)
        function customSensorSimRemove(obj)
            % NO OP
        end
    end

    
    % Make sure only SensorSim has access to this function since changing
    % sensor index needs to be handled properly because SSF needs to be
    % updated too
    methods (Access={?matlabshared.scenario.SensorSimulation.SensorSim})
        function setSensorIndex(obj, sensorIdx)
           obj.SensorBaseSensorID = sensorIdx;
        end
        
        function resetSensorState(obj)
            obj.customSensorSimRemove();
            uniqueID = obj.getSensorSimCacheID();
	        obj.SensorBaseSensorID = obj.getSensorIndex();
            matlabshared.scenario.internal.SSF.clearSensorSimCache(uniqueID, obj.SensorBaseSensorID);
        end

    end


    methods (Abstract,Hidden)
        % Derived class needs to override config if they want to add
        % sensors to the SensorSim
        sensorConfigArray = config(obj)

    end

    methods (Hidden, Access={?matlabshared.scenario.SensorSimulation.SensorBase, ?matlabshared.scenario.SensorSimulation.SensorSim})
        function sensorIdx = getSensorIndex(obj)
            sensorIdx = [];
            
            % Check SensorBaseSensorID before calling config
            if ~isempty(obj.SensorBaseSensorID)
                sensorIdx = obj.SensorBaseSensorID;
            else
                sensorConfig = obj.config();
                if ~isempty(sensorConfig.sensor_id)
                    sensorIdx = sensorConfig.sensor_id.value;
                end
                
            end
        end
    end

    methods(Hidden)

        function sensorAsStruct = getSensorConfigAsStructForBES(obj)
            sensorConfig = obj.config();
            sensorAsStruct.index = sensorConfig.sensor_id.value;
            sensorAsStruct.x = sensorConfig.mounting_position.position.x;
            sensorAsStruct.y = sensorConfig.mounting_position.position.y;
            sensorAsStruct.roll = rad2deg(sensorConfig.mounting_position.orientation.roll);
            sensorAsStruct.pitch = rad2deg(sensorConfig.mounting_position.orientation.pitch);
            sensorAsStruct.yaw =  rad2deg(sensorConfig.mounting_position.orientation.yaw);
            sensorAsStruct.maxRange = sensorConfig.range.max;
            % Check for FOV
            if isempty(sensorConfig.fov)
                % If FOV is empty, manually calcualte the fov using azimuth
                % angles
                if isprop(obj, 'AzimuthLimits')
                    fov = abs(diff(obj.AzimuthLimits));
                end
                % already in degree
                sensorAsStruct.fieldOfView = fov;
            else
                sensorAsStruct.fieldOfView = rad2deg(sensorConfig.fov.azimuth);
            end
       
        end
       
        function output = customSensorSimInit(obj, varargin)
            % No op by default!
            output = [];
        end

        function output = customSensorSimUpdate(obj, varargin)
            % No op by default!
            output = [];
        end
        
        function isSSF = isSensorSimSensor(obj)
            isSSF = obj.SupportsSensorSimulation;
        end
       
    end

    methods (Hidden, Access={?matlabshared.scenario.SensorSimulation.SensorSim})
        function setSensorSim(obj, sensorSim, sensorSimCacheID)
            obj.SensorSimCacheID = sensorSimCacheID;
            if coder.target("MATLAB")
                if ~isempty(sensorSimCacheID) && ~matlabshared.scenario.internal.SSF.cachedSensorSimExists(sensorSimCacheID, obj.SensorBaseSensorID)
                    matlabshared.scenario.internal.SSF.cacheSensorSim(sensorSimCacheID,sensorSim, obj.SensorBaseSensorID);
                end
            end
        end
    end
end
