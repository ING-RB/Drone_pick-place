classdef (Hidden) gnssconstellationRINEX < nav.internal.gnss.gnssconstellationCommon
%GNSSCONSTELLATIONRINEX Satellite motion parameters from RINEX GPS data
%
%   This class is for internal use only. It may be removed in the future.
%

%   Copyright 2023 The MathWorks, Inc.

%#codegen

    methods (Static)
        function varnames = requiredVariableNames
            varnames = { ...
               'Toe', 'sqrtA', 'Delta_n', 'M0', ...
               'Eccentricity', 'omega', 'i0', 'IDOT', ...
               'Cis', 'Cic', 'Crs', 'Crc', 'Cus', 'Cuc', ...
               'OMEGA_DOT', 'OMEGA0', 'SatelliteID'};
        end
    end

    methods (Access = protected)
        function weekNum = weekNumber(obj,orbitParams) %#ok<INUSD>
            weekNum = orbitParams.GPSWeek;
        end

        function checkRequiredVariablesAvailability(obj, orbitParams)
        % CHECKREQUIREDVARIABLESAVAILABILITY Check if absolutely required
        % parameters are available in orbitParams (navData) or not

            % Get the names of required parameters
            requiredVarNames = obj.requiredVariableNames;
            % Get the names of parameters available in orbitParams
            availableVarNames = orbitParams.Properties.VariableNames;
            % Check availability of each required variable in the available
            % parameters
            for count = 1:numel(requiredVarNames)
              reqVarName = requiredVarNames{count};
              % Error out if it is not there
              navmsgstr = newline + "<a href=""matlab:help('nav.internal.rinex.NavFileContents.GPSRecordEntries')"">GPS Navigation Message</a>" ...
                  + newline + "<a href=""matlab:help('nav.internal.rinex.NavFileContents.GalileoRecordEntries')"">Galileo Navigation Message</a>" ...
                  + newline + "<a href=""matlab:help('nav.internal.rinex.NavFileContents.GLONASSRecordEntries')"">GLONASS Navigation Message</a>" ...
                  + newline + "<a href=""matlab:help('nav.internal.rinex.NavFileContents.BeiDouRecordEntries')"">BeiDou Navigation Message</a>" ...
                  + newline + "<a href=""matlab:help('nav.internal.rinex.NavFileContents.NavICRecordEntries')"">NavIC/IRNSS Navigation Message</a>" ...
                  + newline + "<a href=""matlab:help('nav.internal.rinex.NavFileContents.QZSSRecordEntries')"">QZSS Navigation Message</a>" ...
                  + newline + "<a href=""matlab:help('nav.internal.rinex.NavFileContents.SBASRecordEntries')"">SBAS Navigation Message</a>";
              coder.internal.errorIf( ...
                    ~any(matches(availableVarNames, reqVarName)), ...
              "nav_positioning:gnssconstellation:MissingOrbitParameterRINEX",...
              reqVarName, navmsgstr);
            end
        end
        
        function [weekNum, toe, ARef, deltaA, ADot, deltan0, ...
                  deltan0Dot, M0, e0, omega0, i0, iDot, iDel, ...
                  Cis, Cic, Crs, Crc, Cus, Cuc, OmegaRefDot, ...
                  Omega0, deltaOmegaDot, satIDs] = ...
                                    extractOrbitParameters(obj,orbitParams)
        % EXTRACTORBITPARAMS Extract expected data from the user input
        % orbitParams (navData)

            weekNum = weekNumber(obj,orbitParams);

            % Get the number of satellites for which parameters are
            % available
            numSatellites = size(orbitParams,1);
            % Create a zero vector
            zeroVector  = zeros(numSatellites, 1, 'like', weekNum);

            % Extract the orbital parameters from orbitParams and set
            % remaining parameters to 0
            toe           = orbitParams.Toe;
            ARef          = orbitParams.sqrtA.^2;
            deltaA        = zeroVector;
            ADot          = zeroVector; 
            deltan0       = orbitParams.Delta_n;
            deltan0Dot    = zeroVector;
            M0            = orbitParams.M0;
            e0            = orbitParams.Eccentricity;
            omega0        = orbitParams.omega;
            i0            = orbitParams.i0;
            iDot          = orbitParams.IDOT;
            iDel          = zeroVector;
            Cis           = orbitParams.Cis;
            Cic           = orbitParams.Cic;
            Crs           = orbitParams.Crs;
            Crc           = orbitParams.Crc;
            Cus           = orbitParams.Cus;
            Cuc           = orbitParams.Cuc;
            OmegaRefDot   = orbitParams.OMEGA_DOT;
            Omega0        = orbitParams.OMEGA0;
            deltaOmegaDot = zeroVector;
            satIDs        = orbitParams.SatelliteID;
        end
    end
end
