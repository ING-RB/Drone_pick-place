classdef MATLABFunctionTestCaseService < matlab.unittest.internal.services.functiontestcase.FunctionTestCaseService
    
    %
    
    % Copyright 2020 The MathWorks, Inc.
    
    properties(Constant, Access = protected)
        Keyword = "matlab";
        FunctionTestClassName = "matlab.unittest.FunctionTestCase";
    end
    
end