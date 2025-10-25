classdef (Hidden) gnssconstellationRINEXGalileo < nav.internal.gnss.gnssconstellationRINEX
%GNSSCONSTELLATIONRINEXGALILEO Satellite motion parameters from RINEX Galileo data
%
%   This class is for internal use only. It may be removed in the future.
%

%   Copyright 2023 The MathWorks, Inc.

%#codegen

    methods (Access = protected)
        function weekNum = weekNumber(~,orbitParams)
            weekNum = orbitParams.GALWeek;
        end
    end
end