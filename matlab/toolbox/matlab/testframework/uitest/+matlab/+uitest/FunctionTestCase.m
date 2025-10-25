classdef(Sealed) FunctionTestCase < matlab.uitest.TestCase &  matlab.unittest.internal.FunctionTestCase
    % FunctionTestCase - TestCase for use in function based tests for App
    % Testing Framework
    %
    %   The matlab.uitest.FunctionTestCase is the means by which
    %   qualification is performed in tests written using the functiontests
    %   function where the TestType is 'uitest'.
    %
    %   See also: functiontests, runtests

    % Copyright 2023 The MathWorks, Inc.

    methods(Access=?matlab.unittest.internal.FunctionTestCase)
        function testCase = FunctionTestCase
            % Constructor is non-public. Not in model to create explicitly.
        end
    end
end