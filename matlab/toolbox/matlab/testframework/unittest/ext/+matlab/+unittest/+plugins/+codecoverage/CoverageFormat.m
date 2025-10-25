classdef (HandleCompatible) CoverageFormat < matlab.mixin.Heterogeneous
    % CoverageFormat - base class for coverage formats. Only the test
    % framework subclasses this interface.

    % Copyright 2017-2024 The MathWorks, Inc.

    methods (Hidden, Abstract, Access = {?matlab.unittest.internal.mixin.CoverageFormatMixin,...
            ?matlab.unittest.plugins.codecoverage.CoverageFormat})
        generateCoverageReport(format,sources,profileData,msgID, varargin)
    end

    methods (Hidden)
        function validateReportCanBeCreated(~)
        end
    end

    methods (Static, Hidden)
        function files = listSupportingFiles()
            % Ability for format classes to define additional files
            % produced in support of the final coverage output
            files = string.empty();
        end
    end
end
