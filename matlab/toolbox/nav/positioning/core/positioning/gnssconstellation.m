function [satPos, satVel, satIDs] = gnssconstellation(t, varargin)
%

%   Copyright 2020-2023 The MathWorks, Inc.

%#codegen

% Validate time input
validateattributes(t, {'datetime'}, {'scalar', 'finite'}, ...
            'gnssconstellation', 't', 1);

% Check the number of input arguments
narginchk(1,4);

% Parse the inputs
[gnssFileType, orbitParams] = parseInputs(varargin{:});

% Get respective object based on GNSS file type
orbitProp = GNSSConstellationObject(gnssFileType,orbitParams);

[satPos,satVel,satIDs] = propagate(orbitProp,t,orbitParams);
end

function [gnssFileType, orbitParams] = parseInputs(varargin)
% Parse the inputs
    if nargin == 1
        % Get the timetable input
        orbitParams = varargin{1};
        % Validate the timetable input
        validateattributes(orbitParams, {'timetable'}, {'nonempty'},...
                    'gnssconstellation', 'navData', 2); 
        % Set the gnss file type
        gnssFileType = "RINEX";
    elseif nargin == 3
        % Get the timetable input
        orbitParams = varargin{1};
        % Validate the timetable input
        validateattributes(orbitParams, {'timetable'}, {'nonempty'},...
                    'gnssconstellation', 'navData', 2); 
        % Validate the Parameter name
        validatestring(varargin{2}, "GNSSFileType", ...
            "gnssconstellation", "GNSSFileType", 3);
        % Validate and get the gnss file type
        gnssFileType = validatestring(varargin{3}, validGNSSFileTypes,...
            "gnssconstellation", "GNSSFileType", 4);
    elseif nargin == 2      % Old signature
        validatestring(varargin{1}, "RINEXData", ...
            "gnssconstellation", "RINEXData", 2);
        % Get the timetable input
        orbitParams = varargin{2};
        % Validate the timetable input
        validateattributes(orbitParams, {'timetable'}, {'nonempty'},...
                    'gnssconstellation', 'navData', 3); 
        % Set the gnss file type
        gnssFileType = "RINEX";
    else
        gnssFileType = "";
        orbitParams = timetable;
    end
end

function obj = GNSSConstellationObject(gnssFileType,orbitParams)
% GNSSCONSTELLATIONOBJECT Create object of respective file type
    switch gnssFileType
        case "RINEX"
            obj = RINEXPropagator(orbitParams);
        case "SEM"
            obj = nav.internal.gnss.gnssconstellationSEM(orbitParams);
        case "YUMA"
            obj = nav.internal.gnss.gnssconstellationYUMA(orbitParams);
        case "galalmanac"
            obj = nav.internal.gnss.gnssconstellationgalalmanac(orbitParams);
        otherwise
            obj = nav.internal.gnss.gnssconstellationCommon(orbitParams);
    end
end

function obj = RINEXPropagator(orbitParams)
varnames = orbitParams.Properties.VariableNames;

% To support code generation, loop through each variable name. If the
% corresponding "...Week" name is found, return the corresponding
% propagator. Otherwise, return the GLONASS/SBAS propagator.
for ii = 1:numel(varnames)
    varname = varnames{ii};
    if strcmp('GPSWeek',varname) % GPS or QZSS
        obj = nav.internal.gnss.gnssconstellationRINEX(orbitParams);
        return;
    elseif strcmp("GALWeek",varname)
        obj = nav.internal.gnss.gnssconstellationRINEXGalileo(orbitParams);
        return;
    elseif strcmp("BDTWeek",varname)
        obj = nav.internal.gnss.gnssconstellationRINEXBeiDou(orbitParams);
        return;
    elseif strcmp("IRNWeek",varname)
        obj = nav.internal.gnss.gnssconstellationRINEXNavIC(orbitParams);
        return;
    end
end
% GLONASS or SBAS
obj = nav.internal.gnss.gnssconstellationRINEXGLONASS(orbitParams);
end

function validGNSSFileTypes = validGNSSFileTypes()
    % This is a list of all the GNSS files currently supported
    validGNSSFileTypes = {'RINEX', 'SEM', 'YUMA', 'galalmanac'};
end
