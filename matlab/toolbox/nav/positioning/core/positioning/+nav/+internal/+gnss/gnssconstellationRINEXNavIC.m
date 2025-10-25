classdef (Hidden) gnssconstellationRINEXNavIC < nav.internal.gnss.gnssconstellationRINEX
%GNSSCONSTELLATIONRINEXNAVIC Satellite motion parameters from RINEX NavIC data
%
%   This class is for internal use only. It may be removed in the future.
%

%   Copyright 2023 The MathWorks, Inc.

%#codegen

    methods (Access = protected)
        function weekNum = weekNumber(~,orbitParams)
            weekNum = orbitParams.IRNWeek;
        end
    end
end