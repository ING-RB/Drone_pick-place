%SerializedDataQueue Trivial helper class for parallel.internal.dataqueue.AbstractDataQueue
%   This class only exists as a marker so that parallel.internal.dataqueue.AbstractDataQueue
%   can mimic a private constructor.

% Copyright 2015-2021 The MathWorks, Inc.

classdef (Hidden) SerializedDataQueue
    properties (SetAccess = immutable)
        Uuid
        RemoteProcessQueueFactory
        MvmUuid
        Class
    end
    methods (Access = ?parallel.internal.dataqueue.AbstractDataQueue)
        function obj = SerializedDataQueue(uuid, factory, mvmUuid, aClass)
            obj.Uuid = uuid;
            obj.RemoteProcessQueueFactory = factory;
            obj.MvmUuid = mvmUuid;
            obj.Class = aClass;
        end
    end
end