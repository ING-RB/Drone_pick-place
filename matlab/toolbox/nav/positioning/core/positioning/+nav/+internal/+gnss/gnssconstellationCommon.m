classdef (Hidden) gnssconstellationCommon
% GNSSCONSTELLATIONCOMMON Common base class for gnssconstellation
%
%   This class is for internal use only. It may be removed in the future.
%

% Instructions to use this class: Inherit this class then
% 1) Override the requiredVariableNames method to return a cell array of
% character vectors with the required variable names for the input
% orbitParams (navData) timetable.
% 2a) If the GPS orbit propagator is used, override the
% extractOrbitParameters method to extract the required parameters from the
% orbitParams (navData) timetable.
% 2b) If a different orbit propagator is used, override the propagate
% method to return satellite positions, velocities, and IDs from the input
% time t and orbitParams (navData) timetable.
% 3) Override the method getGNSSTime if the time computation differs from 
% GPS time.

%   Copyright 2023 The MathWorks, Inc.

%#codegen

    methods
        function obj = gnssconstellationCommon(orbitParams)
            checkRequiredVariablesAvailability(obj, orbitParams);
        end

        function [satPos,satVel,satIDs] = propagate(obj,t,orbitParams)

            % Get Earth's gravitational constant and rotation rate.
            [~,~, mu, OmegaEDot] = fusion.internal.frames.wgs84ModelParams;

            % Get GNSS week number and time of week from the user given
            % time input.
            [gnssWeek, tow] = obj.getGNSSTime(t);

            % Extract the orbital parameters from the user given timetable
            % input.
            [weekNum, toe, ARef, deltaA, ADot, deltan0, ...
             deltan0Dot, M0, e0, omega0, i0, iDot, iDel, ...
             Cis, Cic, Crs, Crc, Cus, Cuc, OmegaRefDot, ...
             Omega0, deltaOmegaDot, satIDs] = ...
                                extractOrbitParameters(obj,orbitParams);

            % Add change in inclination angle to reference inclination
            % angle.
            i0 = i0 + iDel;

            % Compute position and velocity of the satellites.
            [satPos, satVel] ...
                = matlabshared.internal.gnss.orbitParametersToECEF( ...
                gnssWeek, tow, weekNum, toe, ARef, deltaA, ADot, ...
                mu, deltan0, deltan0Dot, M0, e0, omega0, i0, iDot, ...
                Cis, Cic, Crs, Crc, Cus, Cuc, ...
                OmegaEDot, OmegaRefDot, Omega0, deltaOmegaDot);
        end
    end

    methods (Static)
        % Override this method if the time computation differs from GPS 
        % time.
        function [gnssWeek, tow] = getGNSSTime(t)
        % GETGNSSTIME Get GNSS week number and time of week (tow) in
        % seconds from user input time, t
        % Note: Default implementation is for GPS constellation
            coder.extrinsic( ...
                        'matlabshared.internal.gnss.GNSSTime.getGNSSTime');
            [gnssWeek, tow] = coder.const( ...
                    @matlabshared.internal.gnss.GNSSTime.getGNSSTime, t);
        end

        % Provide the names of absolutely required parameters in a cell
        % array through this static method.
        function varnames = requiredVariableNames
            varnames = {};
        end
    end

    methods (Access = protected)
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
              coder.internal.errorIf( ...
                    ~any(matches(availableVarNames, reqVarName)), ...
              "nav_positioning:gnssconstellation:MissingOrbitParameter",...
              reqVarName);
            end
        end

        % Implement this method to extract the orbital parameters from the
        % input orbitParams timetable.
        %
        % Refer to matlabshared.internal.gnss.orbitParametersToECEF for
        % output parameter descriptions.
        function [weekNum, toe, ARef, deltaA, ADot, deltan0, ...
         deltan0Dot, M0, e0, omega0, i0, iDot, iDel, ...
         Cis, Cic, Crs, Crc, Cus, Cuc, OmegaRefDot, ...
         Omega0, deltaOmegaDot, satIDs] = ...
                                    extractOrbitParameters(obj,orbitParams) %#ok<INUSD>
            % Get the nominal orbital parameters
            [e0, i0, OmegaRefDot, ARef, Omega0, omega0, M0] ...
                    = matlabshared.internal.gnss.OrbitalParameters.nominal;

            % Set the remaining orbital parameters to 0
            [weekNum, toe, deltaA, ADot, ...
             deltan0, deltan0Dot, iDot, iDel, ...
             Cis, Cic, Crs, Crc, Cus, Cuc, deltaOmegaDot] = deal(0);

            % Set the satellite IDs to NaN
            satIDs = NaN;
        end
    end
end
