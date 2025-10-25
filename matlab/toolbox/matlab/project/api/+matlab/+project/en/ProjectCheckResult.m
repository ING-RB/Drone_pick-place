classdef ProjectCheckResult< handle
%ProjectCheckResult   Contains the result of running a project check.

 
%   Copyright 2019-2022 The MathWorks, Inc.

    methods
        function out=ProjectCheckResult
        end

        function out=table(~) %#ok<STOUT>
        end

    end
    properties
        Description;

        ID;

        Passed;

        ProblemFiles;

    end
end
