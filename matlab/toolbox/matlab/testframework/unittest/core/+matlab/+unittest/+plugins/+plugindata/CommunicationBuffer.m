classdef CommunicationBuffer
    % CommunicationBuffer - Buffer for Parallizable plugins.
    %   The CommunicationBuffer is constructed by the test framework to
    %   enable storage and transfer of data between plugin methods for
    %   Parallelizable plugins.
    %
    %   See Also: matlab.unittest.plugins.Parallelizable
    
    % Copyright 2019-2023 The MathWorks, Inc.
    
    
    properties (Hidden, SetAccess=immutable, GetAccess = private)
        WorkerPluginDataMap;
        Group;
    end
    
    methods (Hidden, Access={?matlab.unittest.plugins.plugindata.PluginData,?matlab.unittest.plugins.plugindata.CommunicationBuffer})
        function buffer = CommunicationBuffer(workerPluginDataMap,group)           
            buffer.WorkerPluginDataMap = workerPluginDataMap;
            buffer.Group = group;
        end
    end
    
    methods (Hidden,Access = {?matlab.unittest.plugins.Parallelizable,?matlab.unittest.plugins.plugindata.CommunicationBuffer})
        function store_ (buffer,identifier,data)
            buffer.WorkerPluginDataMap(identifier) = data;
        end

        function data = retrieve_(buffer,identifier,pluginClassName,optionalArgs)
            arguments
                buffer
                identifier
                pluginClassName
                optionalArgs.DefaultData;
            end
            if ~isKey(buffer.WorkerPluginDataMap,identifier)
                if isfield(optionalArgs,'DefaultData')
                    data = optionalArgs.DefaultData;
                    return;
                else
                    error(message('MATLAB:unittest:PluginData:CannotCallRetrieveBeforeCallingStore',buffer.Group,pluginClassName));
                end
            end
            data = buffer.WorkerPluginDataMap(identifier);
        end
    end
end
