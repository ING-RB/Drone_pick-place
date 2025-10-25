classdef ImplicitFixturePluginData < matlab.unittest.plugins.plugindata.PluginData &...
        matlab.unittest.internal.plugins.plugindata.TestResultDetailsAccessorMixin
    % ImplicitFixturePluginData - Data about setting up or tearing down a test
    %
    %   The ImplicitFixturePluginData class holds information about a test
    %   being set up or torn down.
    %
    %   ImplicitFixturePluginData properties:
    %       Name                 - Name of the content being set up or torn down
    %       QualificationContext - Context for performing qualifications
    %       ResultDetails        - Modifier of test result details
    %
    %   See Also
    %       matlab.unittest.plugins.TestRunnerPlugin
    %       matlab.unittest.plugins.QualifyingPlugin
    
    %  Copyright 2014-2022 The MathWorks, Inc.
    
    properties (Dependent, SetAccess=private)
        % QualificationContext - Context for performing qualifications.
        %   QualificationContext provides the context for plugins to perform
        %   qualifications on test content. To perform a qualification, a plugin
        %   should derive from the matlab.unittest.plugins.QualifyingPlugin
        %   interface and use one of its qualification methods: verifyUsing,
        %   assumeUsing, assertUsing, or fatalAssertUsing.
        %
        %   See Also: matlab.unittest.plugins.QualifyingPlugin
        QualificationContext;
    end
    
    properties (Access=private)
        TestCase
    end

    properties(Hidden,SetAccess = private)
        LegacyName
    end
    
    methods (Access={?matlab.unittest.TestRunner,?matlab.unittest.plugins.plugindata.PluginData})
        function p = ImplicitFixturePluginData(name, testCase, testRunData, provider, namedargs)
            arguments
                name
                testCase
                testRunData
                provider
                namedargs.ForLeafResult = false;
                namedargs.LegacyName = name; 
            end
            
            p@matlab.unittest.plugins.plugindata.PluginData(name);
            p@matlab.unittest.internal.plugins.plugindata.TestResultDetailsAccessorMixin(testRunData, provider, ~namedargs.ForLeafResult);
            p.TestCase = testCase;
            p.LegacyName = namedargs.LegacyName;
        end
    end
    
    methods
        function context = get.QualificationContext(pluginData)
            context = matlab.unittest.plugins.plugindata.QualificationContext(pluginData.TestCase);
        end
    end
end

% LocalWords:  plugindata
