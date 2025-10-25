classdef SharedObjectManager < handle
%This class is for internal use only. It may be removed in the future.

%   SharedObjectManager is a utility class that manages shared objects used
%   in Simulink System objects

%   Copyright 2023 The MathWorks, Inc.

    properties (SetAccess = private)
        % SvcServerDict - Dictionary for service server objects
        SvcServerDict
    end

    methods (Access = private)
        % Private constructor to prevent explicit object construction
        function obj = SharedObjectManager
        end
    end

    %% Singleton class access method
    methods (Static)
        function obj = getInstance
            persistent instance__
            if isempty(instance__)
                instance__ = ros.internal.block.SharedObjectManager();
                instance__.SvcServerDict = dictionary();
            end
            obj = instance__;
        end
    end

    methods
        function addSvcServer(obj, key, node, name, type, qosArgs)
            obj.SvcServerDict(key) = ros.slros2.internal.block.SvcServerObj(...
                                        node,name,type,qosArgs{:});
        end

        function removeSvcServer(obj, key)
            if isConfigured(obj.SvcServerDict) && isKey(obj.SvcServerDict,key)
                obj.SvcServerDict(key) = [];
            end
        end

        function serverObj = getSvcServer(obj, key)
            serverObj = obj.SvcServerDict(key);
        end
    end
end