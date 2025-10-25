classdef AppFunctionTestCaseService < matlab.unittest.internal.services.functiontestcase.FunctionTestCaseService

    % Copyright 2023 The MathWorks, Inc.

    properties(Constant, Access = protected)
        Keyword = "uitest";
        FunctionTestClassName = "matlab.uitest.FunctionTestCase";
    end

end