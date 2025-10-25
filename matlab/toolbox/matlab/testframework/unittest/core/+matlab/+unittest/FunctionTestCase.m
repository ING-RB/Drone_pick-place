classdef(Sealed) FunctionTestCase < matlab.unittest.internal.FunctionTestCase
    % FunctionTestCase - TestCase for use in function based tests
    %
    %   The matlab.unittest.FunctionTestCase is the means by which
    %   qualification is performed in tests written using the functiontests
    %   function. For each test function, MATLAB creates a FunctionTestCase
    %   and passes it into the test function. This allows test writers to
    %   use the qualification functions (verifications, assertions,
    %   assumptions, and fatal assertions) to ensure their MATLAB code
    %   operates correctly.
    %
    %   See also: functiontests, runtests
    
    % Copyright 2013-2023 The MathWorks, Inc.
    
    methods(Access=?matlab.unittest.internal.FunctionTestCase)
        function testCase = FunctionTestCase
            % Constructor is non-public. Not in model to create explicitly.
        end
    end
    
    
end

% Local function required for loading of suites created prior to R2020b:
function defaultFixtureFcn(~) %#ok<DEFNU>
    % A do nothing function to be used as fixture setup and teardown when no
    % functions have been provided.
end