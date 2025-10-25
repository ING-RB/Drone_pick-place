classdef(Hidden) TestContentOperator < handle & matlab.mixin.Heterogeneous
    % This class is undocumented and may change in a future release.
    
    % matlab.unittest.TestContentOperator Interface class common to both
    % TestRunner and TestRunnerPlugin. It defines the methods required to be
    % evaluated on test content throughout the test run.
    
    % Copyright 2012-2020 The MathWorks, Inc.
    
    methods (Abstract, Access = protected)        
        runSession(operator, pluginData)
        runTestSuite(operator, pluginData)
        fixture = createSharedTestFixture(operator, pluginData)
        setupSharedTestFixture(operator, pluginData)
        runTestClass(operator, pluginData)
        testcase = createTestClassInstance(operator, pluginData)
        setupTestClass(operator, pluginData)
        runTest(operator, pluginData)
        testcase = createTestMethodInstance(operator, pluginData)
        setupTestMethod(operator, pluginData)
        runTestMethod(operator, pluginData)
        teardownTestMethod(operator, pluginData)
        teardownTestClass(operator, pluginData)
        teardownSharedTestFixture(operator, pluginData)
        reportFinalizedResult(operator, pluginData)
        reportFinalizedSuite(operator,pluginData)
    end
    
    methods (Hidden, Abstract, Access = protected)
        evaluateMethod(operator, pluginData)
        testcase = createTestRepeatLoopInstance(operator, pluginData)
        teardownTestRepeatLoop(operator, pluginData)
    end
end

