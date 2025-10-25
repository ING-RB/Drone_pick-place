classdef HoleReporter< mlreportgen.report.Reporter
%HOLEREPORTER Base class for hole reporters

 
    %   Copyright 2017-2019 The MathWorks, Inc.

    methods
        function out=HoleReporter
        end

    end
    properties
        % HoleId Id of hole to be filled by this reporter
        %
        % Must be a string that specifies the name of the hole to be
        % filled by this reporter.
        HoleId;

    end
end
