classdef AssertionFailedException < matlab.buildtool.internal.qualifications.QualificationFailedException
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2023 The MathWorks, Inc.

    methods (Access = ?matlab.buildtool.internal.qualifications.AssertionDelegate)
        function exception = AssertionFailedException(id, message)
            exception = exception@matlab.buildtool.internal.qualifications.QualificationFailedException(id, message);
        end
    end
end
