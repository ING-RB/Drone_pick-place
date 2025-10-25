classdef TestSuiteRunPluginData < matlab.unittest.plugins.plugindata.RunPluginData
    % TestSuiteRunPluginData - Data that describes running a portion of a suite
    %
    %   The TestSuiteRunPluginData class holds information about a portion of a
    %   test suite being run.
    %
    %   TestSuiteRunPluginData properties:
    %       Name                - Name corresponding to the portion of the suite being executed
    %       TestSuite           - Specification of the test methods being executed
    %       TestResult          - The results of executing the test suite
    %       Group               - The number that identifies the group running the portion of the suite 
    %       NumGroups           - The total number of groups that the entire suite is divided into
    %       CommunicationBuffer - Buffer for Parallelizable plugins
    %       ResultDetails       - Modifier of test result details
    %
    %   See also: matlab.unittest.plugins.TestRunnerPlugin, matlab.unittest.TestSuite, matlab.unittest.TestResult
    %
    
    % Copyright 2013-2019 The MathWorks, Inc.
    
    properties (SetAccess = private, GetAccess = ?matlab.unittest.internal.TestRunStrategy)
        % Construct a map that holds the data stored by the Parallelizable
        % plugins.
        WorkerPluginDataMap
    end
    
    properties (SetAccess = immutable)        
        % Group - Identifier of the group running the portion of the suite
        %
        %   The Group property is a number between 1 and NumGroups that
        %   identifies the group running the current portion of the test
        %   suite.
        Group
        
        % NumGroups - The total number of groups in which the full suite is divided
        %
        %   The NumGroups property identifies the number of disjoint groups the test 
        %   suite is divided into. NumGroups is equal to 1 when tests are run  
        %   sequentially and can be greater than 1 when tests are run in parallel.
        NumGroups
    end
    
    properties (Dependent, SetAccess=private)
        % CommunicationBuffer - Buffer for Parallelizable plugins.
        %
        %   CommunicationBuffer provides a buffer for
        %   matlab.unittest.plugins.TestRunnerPlugin instances to store data within
        %   the scope of the runTestSuite plugin method and retrieve data within
        %   the scope of the reportFinalizedSuite plugin method. The
        %   TestRunnerPlugin instance must derive from the
        %   matlab.unittest.plugins.Parallelizable interface and use its storeIn
        %   and retrieveFrom methods to store data in the buffer and retrieve the
        %   data from it.
        %
        %   See Also: matlab.unittest.plugins.Parallelizable
        %             matlab.unittest.plugins.Parallelizable/storeIn
        %             matlab.unittest.plugins.Parallelizable/retrieveFrom
        CommunicationBuffer
    end
    
    methods(Access = {?matlab.unittest.plugins.plugindata.TestSuiteRunPluginData,...
            ?matlab.unittest.internal.TestRunStrategy})
        function p = TestSuiteRunPluginData(name, dataHolder, endIdx, varargin)
            parser = matlab.unittest.internal.strictInputParser;
            parser.addParameter('WorkerPluginDataMap',containers.Map('KeyType','double', 'ValueType','any'),@(k)validateattributes(k,{'containers.Map'},{},'','WorkerPluginDataMap'));
            parser.addParameter('NumGroups',1,  @(x) validateattributes(x,{'numeric'},{'scalar','integer','>', 0},'','NumGroups'));
            parser.addParameter('Group',1,  @(x) validateattributes(x,{'numeric'},{'scalar','integer','>', 0},'','Group'));
            parser.addParameter('ForLeafResult',false,@(x) validateattributes(x,{'logical'},{'scalar'},'','ForLeafResult'));
            parser.parse(varargin{:});            
            
            p@matlab.unittest.plugins.plugindata.RunPluginData(name,dataHolder,endIdx,'ForLeafResult',parser.Results.ForLeafResult);
            p.WorkerPluginDataMap = parser.Results.WorkerPluginDataMap;
            p.Group = parser.Results.Group;
            p.NumGroups = parser.Results.NumGroups;
        end
    end
    methods
         function buffer = get.CommunicationBuffer(pluginData)
            buffer = createCommunicationBuffer(pluginData);
        end
    end
    
    methods (Access = private)
        function comBuffer = createCommunicationBuffer(pluginData)
            comBuffer = matlab.unittest.plugins.plugindata.CommunicationBuffer(pluginData.WorkerPluginDataMap,pluginData.Group);   
        end
    end
end

% LocalWords:  plugindata subsuite unittest plugins
