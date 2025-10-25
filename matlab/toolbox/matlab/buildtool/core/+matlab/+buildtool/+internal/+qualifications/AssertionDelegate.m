classdef AssertionDelegate < matlab.buildtool.internal.qualifications.QualificationDelegate
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2023 The MathWorks, Inc.

    properties(Constant, Access = protected)
        Type = "assert";
    end

    methods
        function doFail(~)
            import matlab.buildtool.internal.qualifications.AssertionFailedException

            msg = message("MATLAB:buildtool:Assertable:AssertionFailed");
            ex = AssertionFailedException("MATLAB:buildtool:Assertable:AssertionFailed", msg);
            throw(ex);
        end
    end
end