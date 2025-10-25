classdef (Hidden) gnssconstellationRINEXBeiDou < nav.internal.gnss.gnssconstellationRINEX
%GNSSCONSTELLATIONRINEXBEIDOU Satellite motion parameters from RINEX BeiDou data
%
%   This class is for internal use only. It may be removed in the future.
%

%   Copyright 2023 The MathWorks, Inc.

%#codegen

    methods (Access = protected)
        function weekNum = weekNumber(~,orbitParams)
            weekNum = orbitParams.BDTWeek;
        end
    end
end