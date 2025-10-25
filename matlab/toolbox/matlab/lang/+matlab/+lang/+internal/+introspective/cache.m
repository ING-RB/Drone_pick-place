classdef cache < handle
    methods (Static)
        function cleanup = enable
            obj = matlab.lang.internal.introspective.cache.instance;
            obj.enabled = true;
            cleanup = onCleanup(@()obj.disable);
        end

        function result = lookup(fcn, varargin)
            obj = matlab.lang.internal.introspective.cache.instance;
            result = call(obj, fcn, varargin);
        end
    end

    methods (Static, Access=private)
        function c = instance()
            persistent singleton;
            if isempty(singleton)
                singleton = matlab.lang.internal.introspective.cache;
            end
            c = singleton;
        end
    end

    properties (Access=private)
        enabled;
        map;
    end

    methods (Access=private)
        function result = call(obj, fcn, args)
            if obj.enabled
                key = func2str(fcn);
                topicAsField = makeFieldName(key, args);
                if obj.map.isKey(topicAsField)
                    result = obj.map(topicAsField);
                else
                    result = fcn(args{:});
                    obj.map(topicAsField) = result;
                end
            else
                result = fcn(args{:});
            end
        end

        function obj = cache()
            obj.reset;
        end

        function disable(obj)
            obj.reset;
        end

        function reset(obj)
            obj.enabled = false;
            obj.map = containers.Map;
        end
    end
end

function fieldName = makeFieldName(key, args)
    fieldName = append(key, ":", join(string(args),''));
end

%   Copyright 2021-2023 The MathWorks, Inc.
