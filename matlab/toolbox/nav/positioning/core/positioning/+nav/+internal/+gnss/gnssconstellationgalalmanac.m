classdef gnssconstellationgalalmanac < nav.internal.gnss.gnssconstellationCommon
%GNSSCONSTELLATIONGALALMANAC Satellite motion parameters from Galileo
%   almanac data
%
%   This class is for internal use only. It may be removed in the future.
%

%   Copyright 2023 The MathWorks, Inc.

%#codegen
    
    methods  (Static)
        function varnames = requiredVariableNames
            varnames = { ...
                'SVID', 'aSqRoot', 'ecc', 'deltai', 'omega0', ...
                'omegaDot', 'w', 'm0', 't0a', 'wna'};
        end

        function [gnssWeek, tow] = getGNSSTime(t)
        % GETGNSSTIME Get GNSS week number and time of week (tow) in
        % seconds from user input time, t
        % Note: Overriding this method here for Galileo constellation
            coder.extrinsic( ...
                'matlabshared.internal.gnss.GalileoTime.getGalileoTime');
            [gnssWeek, tow] = coder.const( ...
                @matlabshared.internal.gnss.GalileoTime.getGalileoTime, t);
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
            zeroVector  = zeros(numSatellites,1,'like',orbitParams.SVID);

            % Factor to convert parameters in Semicircles to Radian
            semicir2radFactor = pi;

            % Extract the orbital parameters from orbitParams
            weekNum     = orbitParams.wna;
            toe         = orbitParams.t0a;
            ARef        = (orbitParams.aSqRoot + sqrt(29600000)).^2;
            M0          = orbitParams.m0  * semicir2radFactor;
            e0          = orbitParams.ecc;
            omega0      = orbitParams.w  * semicir2radFactor;
            % i0 = 56 degree
            i0          = deg2rad(56).*ones(numSatellites, 1);
            iDel        = orbitParams.deltai  * semicir2radFactor;
            OmegaRefDot = orbitParams.omegaDot  * semicir2radFactor;
            Omega0      = orbitParams.omega0  * semicir2radFactor;
            satIDs      = orbitParams.SVID;

            % Set the remaining orbital parameters to 0
            [deltaA, ADot, deltan0, deltan0Dot, iDot, ...
             Cis, Cic, Crs, Crc, Cus, Cuc, ...
                  deltaOmegaDot] = deal(zeroVector);
        end
    end
end