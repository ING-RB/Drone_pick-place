classdef FinalizedSuitePluginData < matlab.unittest.plugins.plugindata.PluginData
    % FinalizedSuitePluginData - Data about finalized test suite
    %
    %   The FinalizedSuitePluginData class holds information about a test
    %   suite that is finalized.
    %
    %   FinalizedSuitePluginData properties:
    %       Group               - Identifier of the group running the portion of the suite
    %       NumGroups           - The total number of groups in which the full suite is divided
    %       TestSuite           - Test elements in the current group
    %       TestResult          - TestResult elements that are finalized
    %       SuiteIndices        - Positions of the group's suite relative to the entire suite
    %       CommunicationBuffer - Buffer for Parallelizable plugins
    %
    %   See also: matlab.unittest.plugins.TestRunnerPlugin
    
    % Copyright 2019 The MathWorks, Inc.
    
    properties (SetAccess=immutable)        
        % Group - Identifier of the group running the portion of the suite
        %
        %   The Group property is a number between one and NumGroups that
        %   identifies the group running the current portion of the test
        %   suite.
        Group;
        
        % NumGroups - The total number of groups in which the full suite is divided
        %
        %   The NumGroups property identifies the number of disjoint groups the test 
        %   suite is divided into. NumGroups is equal to one when tests are run  
        %   serially and can be greater than one when tests are run in parallel.
        NumGroups;
        
        % TestSuite - Test elements in the current group
        %
        %   The TestSuite property is a matlab.unittest.Test array that
        %   specifies the test methods executed to produce the TestResult.
        TestSuite;
        
        % TestResult - TestResult elements that are finalized
        %
        %   The TestResult property is a matlab.unittest.TestResult array that
        %   holds the finalized results of running a portion of the test suite.
        TestResult;
        
        % SuiteIndices - Positions of the group's suite relative to the entire suite
        %
        %   The SuiteIndices property is a numeric array with values that
        %   give the location of the finalized suite in relation to the
        %   entire suite being run. SuiteIndices also gives the locations
        %   of the finalized results in the TestResult array. These indices
        %   might not always be contiguous or in a sorted order.
        SuiteIndices;
        
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
    
    properties (Access = private)       
        WorkerPluginDataMap;
    end
    
    methods (Access={?matlab.unittest.internal.TestRunStrategy,?matlab.unittest.plugins.plugindata.PluginData})
        function p = FinalizedSuitePluginData(name, pluginDataMap, suiteIndices, groupNumber, numGroups, suite, testResults)
            p@matlab.unittest.plugins.plugindata.PluginData(name);
            p.WorkerPluginDataMap = pluginDataMap;
            p.SuiteIndices = suiteIndices;
            p.Group = groupNumber;
            p.NumGroups = numGroups;
            p.TestSuite = suite;
            p.TestResult = testResults;
        end
    end
    
    methods
        function buffer = get.CommunicationBuffer(pluginData)
            buffer = matlab.unittest.plugins.plugindata.CommunicationBuffer(pluginData.WorkerPluginDataMap,pluginData.Group);
        end
    end
    
end