%SerializationNotifier Utility to send notifications about serialization

% Copyright 2018-2020 The MathWorks, Inc.

classdef SerializationNotifier < handle

    events
        ObjectSerialized
    end

    methods (Access = private)
        function obj = SerializationNotifier()
        end
    end

    methods (Static, Access = private)
        function obj = getInstance()
            persistent INSTANCE
            if isempty(INSTANCE)
                INSTANCE = parallel.internal.general.SerializationNotifier();
            end
            obj = INSTANCE;
        end
    end

    methods (Static)
        function notifySerialized(className)
            notify(parallel.internal.general.SerializationNotifier.getInstance(), 'ObjectSerialized', ...
                   parallel.internal.general.SerializationEventData(className, 'serialized'));

        end
        function notifyDeserialized(className)
            notify(parallel.internal.general.SerializationNotifier.getInstance(), 'ObjectSerialized', ...
                   parallel.internal.general.SerializationEventData(className, 'deserialized'));
        end
        function obj = createSerializationListener(callBackFcn)
            obj = event.listener(parallel.internal.general.SerializationNotifier.getInstance(), ...
                                 'ObjectSerialized', callBackFcn);
        end
        function [listener, getList] = createAccumulatingListener()
            list = {};
            function nCallback(~, eventData)
                list = unique([list, eventData.ClassName]);
            end
            function out = nGetList()
                out = list;
            end
            listener = parallel.internal.general.SerializationNotifier.createSerializationListener(...
                @nCallback);
            getList = @nGetList;
        end
    end
end
