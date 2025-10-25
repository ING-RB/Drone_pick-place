classdef factorGPS < fusion.internal.UnitDisplayer
%FACTORGPS Create GPS factor
%
%   F = FACTORGPS(ID) returns a factorGPS object, F, with the node
%   identification number set to ID. The GPS factor adds a constraint to
%   the corresponding factor graph node using the GPS position measurement.
%
%   F = FACTORGPS(...,Name=Value) specifies properties using one or more
%   name-value arguments.
%
%   FACTORGPS methods:
%       nodeType          - Retrieve the node type
%
%   FACTORGPS properties:
%       NodeID            - ID of node to connect to in factor graph
%       Location          - Geodetic position measurement (deg, deg, m)
%       HDOP              - Horizontal dilution of precision
%       VDOP              - Vertical dilution of precision
%       ReferenceLocation - Reference location (deg, deg, m)
%       ReferenceFrame    - Reference frame 
%
%   Example:
%       % Create a factor graph and a factorGPS with ReferenceFrame  
%       % "NED" (North-East-Down).
%       G = factorGraph;
%       f = factorGPS(1, ReferenceFrame="NED");
%       % Add the factor to the factor graph. Since there is no node with 
%       % the ID corresponding to the factor, a new node is created and 
%       % added to the factor graph automatically.
%       addFactor(G, f);   
%       % Check the node type. The node that the GPS factor connects to is 
%       % type "POSE_SE3".
%       nodeType(G, 1);
%
%   See also factorGraph.

%   Copyright 2021-2023 The MathWorks, Inc.

%#codegen
    properties (Hidden, Constant)
        FactorType = "GPS_F";
    end

    properties
        %NODEID ID of node to connect to in factor graph
        %   Specify the node ID as an integer. This ID will be used to
        %   insert the factor into the factor graph.
        NodeID (1,1) {double, mustBeInteger, mustBeNonnegative};
        %LOCATION Geodetic position measurement (deg, deg, m)
        %   Specify the location measurement as a 3-element vector of
        %   geodetic coordinates (latitude, longitude, and altitude). The
        %   location is in [degrees, degrees, meters]. 
        %   
        %   Default: [0 0 0]
        Location (1,3) {mustBeValidGeodetic} = [0 0 0];
        %HDOP Horizontal dilution of precision
        %   Specify the horizontal dilution of precision as a positive
        %   scalar. 
        % 
        %   Default: 1
        HDOP (1,1) {double, mustBeReal, mustBeFinite, mustBePositive} = 1;
        %VDOP Vertical dilution of precision
        %   Specify the vertical dilution of precision as a positive
        %   scalar. 
        % 
        %   Default: 2
        VDOP (1,1) {double, mustBeReal, mustBeFinite, mustBePositive} = 2;
        %ReferenceLocation Reference location (deg, deg, m)
        %   Specify the origin of the local coordinate system as a 3-element
        %   vector in geodetic coordinates (latitude, longitude, and
        %   altitude). Altitude is the height above the reference ellipsoid
        %   model, WGS84. The reference location is in [degrees degrees
        %   meters]. 
        % 
        %   Default: [0 0 0]
        ReferenceLocation (1,3) {mustBeValidGeodetic} = [0 0 0];
        %ReferenceFrame Reference frame
        %   Specify the reference frame for the local coordinate system as
        %   "ENU" (East-North-Up) or "NED" (North-East-Down).
        %   
        %   Default: "ENU"
        ReferenceFrame {mustBeValidReferenceFrame} = "ENU";
    end

    properties (Hidden, Constant)
        LocationUnits = '[deg deg m]';
        ReferenceLocationUnits = '[deg deg m]'
    end
    
    methods
        function obj = factorGPS(varargin)
            narginchk(1, Inf);
            obj = matlabshared.fusionutils.internal.setProperties( ...
                obj, nargin, varargin{:}, "NodeID");
        end

        function type = nodeType(obj, id)
        %NODETYPE Retrieve the node type
        %
        %   Example:
        %       f = factorGPS(1);
        %       % Retrieve the node type without node ID
        %       nodeType(f)
        %       % Retrieve the node type for a specified node ID
        %       nodeType(f, 1)
            narginchk(1, 2);
            if nargin == 2
                nav.algs.internal.validation.validateNodeID_FactorQuery(id, obj.NodeID, 'factorGPS', 'id');
            end
            type = nav.internal.factorgraph.NodeTypes.SE3;
        end
    end

    % Methods for interacting with the factorGraph object.
    methods (Hidden)
        function [meas, infoMat] = factorGraphMeasurements(obj)
            if strcmp(obj.ReferenceFrame, "ENU")
                meas = lla2enu(obj.Location, obj.ReferenceLocation, ...
                "ellipsoid");
            else % strcmp(obj.ReferenceFrame, "NED")
                meas = lla2ned(obj.Location, obj.ReferenceLocation, ...
                "ellipsoid");
            end

            infoMat = inv(diag([obj.HDOP, obj.HDOP, obj.VDOP].^2));
        end
    end
end

function mustBeValidGeodetic(val)

validateattributes(val, {'numeric'}, ...
    {'vector', 'numel', 3, 'real', 'finite'});
validateattributes(val(1), {'numeric'}, ...
    {'>=',-90,'<=',90}, ...
    '', ...
    'Latitude');
validateattributes(val(2), {'numeric'}, ...
    {'>=',-180,'<=',180}, ...
    '', ...
    'Longitude');
end

function val = mustBeValidReferenceFrame(valIn)
val = validatestring(valIn, {'ENU', 'NED'}, 'factorGPS');
end
