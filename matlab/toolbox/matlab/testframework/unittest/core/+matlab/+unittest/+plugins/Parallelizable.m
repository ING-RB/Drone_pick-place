classdef (Abstract)Parallelizable < handle
    % Parallelizable - Interface for plugins that support running tests in parallel
    %
    %   The Parallelizable class is an interface for
    %   matlab.unittest.plugins.TestRunnerPlugin instances that support
    %   dividing the test suite into separate groups and running each group
    %   on the current parallel pool. Parallelizable provides a
    %   TestRunnerPlugin instance the ability to communicate the data
    %   collected from each group to the client.
    %
    %   Parallelizable methods:
    %       storeIn          - Store the data collected for a group of tests
    %       retrieveFrom     - Retrieve the stored data for a group of tests
    %       supportsParallel - Determine whether a plugin supports running tests in parallel
    %
    
    % Copyright 2019-2023 The MathWorks, Inc.
    
    properties (Access = private)
        Identifier
    end
    
    methods(Hidden, Sealed)
        function tf = supportsParallel_(p)
            tf = p.supportsParallel;
        end
    end
    
    methods
        function tf = supportsParallel(~)
            % SUPPORTSPARALLEL - Determine whether a plugin supports running tests in parallel
            %
            %  SUPPORTSPARALLEL(PLUGIN) returns true if PLUGIN supports running tests
            %  in parallel. If PLUGIN only supports running tests sequentially, the method
            %  returns false.
            tf = true;
        end
    end
    
    methods (Sealed, Access = ?matlab.unittest.internal.TestRunnerExtension)
        function setIdentifier(plugin, identifier)
            plugin.Identifier = identifier;            
        end
    end
    
    methods (Access = protected, Sealed)
        function storeIn(plugin,communicationBuffer,data)
            % STOREIN - Store the data collected for a group of tests
            %
            %   PLUGIN.STOREIN(COMMUNICATIONBUFFER,DATA) stores the data collected by
            %   PLUGIN while running a group from the test suite, specified as DATA, in
            %   a communication buffer. The storeIn method can be invoked within the
            %   scope of the runTestSuite method on PLUGIN. COMMUNICATIONBUFFER must be
            %   an instance of the
            %   matlab.unittest.plugins.plugindata.CommunicationBuffer class.
            %
            %   See also: matlab.unittest.plugins.Parallelizable/retrieveFrom
            %             matlab.unittest.plugins.TestRunnerPlugin/runTestSuite
            %             matlab.unittest.plugins.plugindata.CommunicationBuffer
            
            validateattributes(communicationBuffer,{'matlab.unittest.plugins.plugindata.CommunicationBuffer'},{'scalar'})
            communicationBuffer.store_(plugin.Identifier,data);
        end
        
        function data = retrieveFrom(plugin,communicationBuffer, varargin)
            % RETRIEVEFROM - Retrieve the stored data for a group of tests
            %
            %   DATA = PLUGIN.RETRIEVEFROM(COMMUNICATIONBUFFER) returns the data stored by
            %   PLUGIN while running a group from the test suite from a communication
            %   buffer. The retrieveFrom method can be invoked within the scope of the
            %   reportFinalizedSuite method of PLUGIN. COMMUNICATIONBUFFER must be an
            %   instance of the matlab.unittest.plugins.plugindata.CommunicationBuffer
            %   class.
            %
            %   DATA = PLUGIN.RETRIEVEFROM(COMMUNICATIONBUFFER,DefaultData=VALUE)
            %   returns VALUE if PLUGIN has not stored any data on the
            %   communication buffer before invoking this method.
            %   
            %   See also: matlab.unittest.plugins.Parallelizable/storeIn
            %             matlab.unittest.plugins.TestRunnerPlugin/reportFinalizedSuite
            %             matlab.unittest.plugins.plugindata.CommunicationBuffer
            %         
            validateattributes(communicationBuffer,{'matlab.unittest.plugins.plugindata.CommunicationBuffer'},{'scalar'});           
            data = communicationBuffer.retrieve_(plugin.Identifier,class(plugin), varargin{:});  
        end
    end
end
