classdef gnssconstellationSEM < nav.internal.gnss.gnssconstellationCommon
%GNSSCONSTELLATIONSEM Satellite motion parameters from SEM almanac data
%
%   This class is for internal use only. It may be removed in the future.
%

%   Copyright 2023 The MathWorks, Inc.

%#codegen
    
    methods (Static)
        function varnames = requiredVariableNames
            varnames = { ...
               'GPSWeekNumber', 'GPSTimeOfApplicability', 'PRNNumber', ...
               'SqrtOfSemiMajorAxis', 'MeanAnomaly', 'Eccentricity', ...
               'ArgumentOfPerigee', 'InclinationOffset', ...
               'RateOfRightAscension','GeographicLongitudeOfOrbitalPlane'};
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
            zeroVector    = zeros(numSatellites,1,'like', ...
                                    orbitParams.GPSWeekNumber);

            % Factor to convert parameters in Semicircles to Radian
            semicir2radFactor = pi;

            % Extract the orbital parameters from orbitParams
            weekNum     = orbitParams.GPSWeekNumber;
            toe         = orbitParams.GPSTimeOfApplicability;
            ARef        = orbitParams.SqrtOfSemiMajorAxis.^2;
            M0          = orbitParams.MeanAnomaly * semicir2radFactor;
            e0          = orbitParams.Eccentricity;
            omega0      = orbitParams.ArgumentOfPerigee ...
                                                    * semicir2radFactor;
            % i0 = 54 degree
            i0          = deg2rad(54).*ones(numSatellites, 1);
            iDel        = orbitParams.InclinationOffset ...
                                                    * semicir2radFactor;
            OmegaRefDot = orbitParams.RateOfRightAscension ...
                                                    * semicir2radFactor;
            Omega0      = orbitParams.GeographicLongitudeOfOrbitalPlane ...
                                                    * semicir2radFactor;
            satIDs      = orbitParams.PRNNumber;

            % Set the remaining orbital parameters to 0
            [deltaA, ADot, deltan0, deltan0Dot, iDot, ...
             Cis, Cic, Crs, Crc, Cus, Cuc, ...
                  deltaOmegaDot] = deal(zeroVector);
        end
    end
end
