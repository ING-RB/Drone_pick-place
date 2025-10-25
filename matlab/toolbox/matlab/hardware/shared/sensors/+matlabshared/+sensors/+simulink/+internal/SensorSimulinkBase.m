classdef SensorSimulinkBase < matlab.System              
   %SensorSimulinkBase class is the parent classes for all targets
   % which follows sensor 2 by 2. This class implements IO related
   % functionalities and is non peripheral dependent hence
   % can be used to check if the object is of correct class 
    
   %   Copyright 2022 The MathWorks, Inc.
    %#codegen
    properties(Access = protected)
        DeployAndConnectHandle
	%Flag to indicate if the execution mode is ConnectedIO
	%Added as a solution to g2786038
        IsIOEnable = false; 
    end
    
    properties(Hidden)
        ProtocolObj
    end
    
    methods
        function obj = SensorSimulinkBase(~)
            if coder.target('MATLAB')
                obj.IsIOEnable = matlabshared.svd.internal.isSimulinkIoEnabled;
                if obj.IsIOEnable
                    obj.setProtocolObject();
                end
            end
        end
        
        function closeIOClient(obj)
           % Clear the resources related to connected IO workflow
           if coder.target('MATLAB') 
             if obj.IsIOEnable
                  obj.DeployAndConnectHandle.deleteConnectedIOClient;
             end
            end
        end

         function protocolObj = getProtocolObject(obj)
            protocolObj = obj.ProtocolObj;
        end
    end
    
    methods(Access = protected)
        function obj = setProtocolObject(obj)
            % flash the IO server and connect
            obj.DeployAndConnectHandle = matlabshared.ioclient.DeployAndConnectHandle();
            obj.DeployAndConnectHandle.getConnectedIOClient();
            obj.ProtocolObj = obj.DeployAndConnectHandle.IoProtocol;
        end
    end
end