classdef gnssconstellationYUMA < nav.internal.gnss.gnssconstellationCommon
%GNSSCONSTELLATIONYUMA Satellite motion parameters from YUMA almanac data
%
%   This class is for internal use only. It may be removed in the future.
%

%   Copyright 2023 The MathWorks, Inc.

%#codegen

    methods (Static)
        function varnames = requiredVariableNames
            varnames = { ...
                'Week', 'TimeOfApplicability', 'PRN', ...
                'SQRTA', 'MeanAnom', 'Eccentricity', ...
                'ArgumentOfPerigee', 'OrbitalInclination', ...
                'RateOfRightAscen', 'RightAscenAtWeek'};
        end
    end
    
    methods (Access = protected)
        function [weekNum, toe, ARef, deltaA, ADot, deltan0, ...
                  deltan0Dot, M0, e0, omega0, i0, iDot, iDel, ...
                  Cis, Cic, Crs, Crc, Cus, Cuc, OmegaRefDot, ...
                  Omega0, deltaOmegaDot, satIDs] = ...
                                    extractOrbitParameters(~,orbitParams)
        % EXTRACTORBITPARAMS Extract expected data from the user input
        % orbitParams (navData)

            % Get the number of satellites for which parameters are
            % available
            numSatellites = size(orbitParams,1);
            % Create a zero vector
            zeroVector    = zeros(numSatellites,1,'like',orbitParams.Week);

            % Extract the orbital parameters from orbitParams
            weekNum       = orbitParams.Week;
            toe           = orbitParams.TimeOfApplicability;
            ARef          = orbitParams.SQRTA.^2;
            M0            = orbitParams.MeanAnom;
            e0            = orbitParams.Eccentricity;
            omega0        = orbitParams.ArgumentOfPerigee;
            i0            = orbitParams.OrbitalInclination;
            OmegaRefDot   = orbitParams.RateOfRightAscen;
            Omega0        = orbitParams.RightAscenAtWeek;
            satIDs        = orbitParams.PRN;

            % Set the remaining orbital parameters to 0
            [deltaA, ADot, deltan0, deltan0Dot, iDot, iDel, ...
             Cis, Cic, Crs, Crc, Cus, Cuc, ...
                  deltaOmegaDot] = deal(zeroVector);
        end
    end
end

