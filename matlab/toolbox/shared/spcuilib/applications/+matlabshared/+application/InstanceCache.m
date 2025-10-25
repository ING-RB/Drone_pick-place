classdef InstanceCache < handle
    %InstanceCache - Cache instance handles

    %   Copyright 2020 The MathWorks, Inc.
    properties (Constant, Hidden)
        Instance  = matlabshared.application.InstanceCache;
        Instances = containers.Map('KeyType','char','ValueType','any');
    end
    
    methods (Access = protected)
        function this = InstanceCache()
            mlock;
        end
    end
    
    methods (Static)
        function add(tag, instance)
            map = matlabshared.application.InstanceCache.Instances;
            
            if map.isKey(tag)
                val = map(tag);
                if ~any(val == instance)
                    val(end+1) = instance;
                    map(tag) = val; %#ok<*NASGU>
                end
            else
                % Create a new key/val pair
                map(tag) = instance;
            end
        end
        
        function remove(tag, instance)
            % Removing the handle from the array of app handles
            map = matlabshared.application.InstanceCache.Instances;
            if map.isKey(tag)
                val = map(tag);
                val(val == instance) = [];
                map(tag) = val;
            end
        end
        
        function instances = get(tag)
            map = matlabshared.application.InstanceCache.Instances;
            if nargin == 0
                instances = map;
            elseif map.isKey(tag)
                instances = map(tag);
            else
                instances = [];
            end
        end
        
        function clear(tag)
            map = matlabshared.application.InstanceCache.Instances;
            if nargin == 0
                k = keys(map);
                for indx = 1:numel(k)
                    map.remove(k{indx});
                end
            else
                map.remove(tag);
            end
        end
    end
end

% [EOF]
