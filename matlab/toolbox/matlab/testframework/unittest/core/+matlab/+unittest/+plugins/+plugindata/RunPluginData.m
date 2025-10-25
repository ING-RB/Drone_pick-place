classdef RunPluginData < matlab.unittest.plugins.plugindata.PluginData & ...
        matlab.unittest.internal.plugins.plugindata.TestResultDetailsAccessorMixin
    % RunPluginData - Data that describes running a portion of a suite.
    %
    %   The RunPluginData class holds information about a portion of a
    %   test suite being run.
    %
    %   RunPluginData properties:
    %       Name          - Name corresponding to the portion of the suite being executed
    %       TestSuite     - Specification of the Test methods being executed
    %       TestResult    - The results of executing the portion of the suite
    %       ResultDetails - Modifier of test result details
    %
    %   See also: matlab.unittest.plugins.TestRunnerPlugin, matlab.unittest.TestSuite, matlab.unittest.TestResult
    %
    
    % Copyright 2019-2020 The MathWorks, Inc.
    
    properties (Dependent, SetAccess=immutable)
        % TestSuite - Specification of the Test methods being executed.
        %
        %   The TestSuite property is a matlab.unittest.TestSuite that specifies
        %   the Test methods executed within the scope of the plugin method.
        TestSuite
    end
    
    properties (Dependent, SetAccess={?matlab.unittest.internal.TestRunnerExtension, ?matlab.unittest.plugins.plugindata.RunPluginData, ?matlab.unittest.internal.TestRunStrategy})
        % TestResult - The results of executing the portion of the suite.
        %
        %   The TestResult property is a matlab.unittest.TestResult array that
        %   contains the results of executing the Test methods specified by the
        %   TestSuite property.
        TestResult
    end
    
    properties (Hidden, Dependent, SetAccess={?matlab.unittest.TestRunner, ?matlab.unittest.plugins.plugindata.RunPluginData})
        % This property is undocumented and may change in a future release.
        
        % CurrentIndex - Index into TestSuite of the currently executing Test method.
        %
        %   The CurrentIndex property is an integer scalar that represents the index
        %   into TestSuite (and also TestResult) of the Test method currently being
        %   executed. CurrentIndex is initially one and increases as content in the
        %   scope of the plugin method is executed.
        CurrentIndex;
    end
    
    properties (Hidden, Dependent, SetAccess=private)
        RepeatIndex;
    end
    
    properties (SetAccess=immutable, GetAccess=private)
        % Index into the full TestSuite array of where this subsuite starts.
        StartIndex;
        
        % Index into the full TestSuite array of where this subsuite ends.
        EndIndex;
    end
    
    properties (SetAccess=immutable, GetAccess = ?matlab.unittest.internal.TestRunStrategy)
        OutputStream
        NumWorkers
    end
    
    properties (Constant, Access=private)
        DefaultOutputStream = matlab.unittest.plugins.ToStandardOutput;
    end
    
    methods (Access = {?matlab.unittest.internal.TestRunnerExtension, ?matlab.unittest.plugins.plugindata.RunPluginData})
        function p = RunPluginData(name, dataHolder, endIdx, namedargs)
            arguments
                name
                dataHolder
                endIdx
                namedargs.NumWorkers = 1;
                namedargs.OutputStream = matlab.unittest.plugins.plugindata.RunPluginData.DefaultOutputStream;
                namedargs.ForLeafResult = false;
            end
            
            import matlab.unittest.plugins.ToStandardOutput;
            import matlab.unittest.internal.plugins.DeterminedDetailsLocationProvider;
            
            p@matlab.unittest.plugins.plugindata.PluginData(name);
            p@matlab.unittest.internal.plugins.plugindata.TestResultDetailsAccessorMixin(dataHolder,...
                DeterminedDetailsLocationProvider(dataHolder.CurrentIndex, endIdx), ~namedargs.ForLeafResult);
            
            p.StartIndex = dataHolder.CurrentIndex;
            p.EndIndex = endIdx;
            
            p.OutputStream = namedargs.OutputStream;
            p.NumWorkers = namedargs.NumWorkers;
        end
    end
    
    methods
        function index = get.CurrentIndex(pluginData)
            index = pluginData.TestRunData.CurrentIndex - pluginData.StartIndex + 1;
        end
        
        function set.CurrentIndex(pluginData, index)
            pluginData.TestRunData.CurrentIndex = pluginData.StartIndex + index - 1;
        end
        
        function index = get.RepeatIndex(pluginData)
            index = pluginData.TestRunData.RepeatIndex;
        end
        
        function result = get.TestResult(pluginData)
            result = pluginData.obtainIndexedRange(pluginData.TestRunData.TestResult);
        end
        
        function set.TestResult(pluginData, result)
            pluginData.TestRunData.TestResult(pluginData.StartIndex:pluginData.EndIndex) = result;
        end
        
        function suite = get.TestSuite(pluginData)
            suite = pluginData.obtainIndexedRange(pluginData.TestRunData.TestSuite);
        end
    end
    
    methods (Access=private)
        function array = obtainIndexedRange(pluginData, array)
            % For performance, only index if needed
            if pluginData.StartIndex ~= 1 || pluginData.EndIndex ~= numel(array)
                array = array(pluginData.DetailsLocationProvider.PotentialAffectedIndices);
            end
            array = reshape(array,1,[]);
        end
    end
end

% LocalWords:  plugindata subsuite unittest plugins
