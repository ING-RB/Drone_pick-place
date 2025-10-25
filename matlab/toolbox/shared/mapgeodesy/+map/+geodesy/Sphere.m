classdef (Hidden) Sphere < map.geodesy.Spheroid
%map.geodesy.Sphere Spheroid object for perfect sphere
%
%   obj = map.geodesy.Sphere returns a default map.geodesy.Sphere object,
%   with Radius = 1 (a unit sphere).
%
%   A spheroid object representing a sphere having a specific radius,
%   and can be used in map projections and other geodetic operations. It
%   has the following properties:
%
%   map.geodesy.Sphere properties:
%      Radius - Radius of sphere
%
%   map.geodesy.Sphere properties (read-only):
%      SemimajorAxis - Equatorial radius of sphere, a = Radius
%      SemiminorAxis - Distance from center of sphere to pole, b = Radius
%      InverseFlattening - Reciprocal of flattening, 1/f = Inf
%      Eccentricity - First eccentricity of sphere, ecc = 0
%      Flattening - Flattening of sphere, f = 0
%      ThirdFlattening - Third flattening of sphere, n = 0
%      MeanRadius - Mean radius of sphere
%      SurfaceArea - Surface area of sphere
%      Volume - Volume of sphere
%
%   The first 7 read-only properties are provided to ensure that
%   map.geodesy.Sphere objects can be used interchanged with other spheroid
%   types in most contexts. These properties are omitted when an object
%   is displayed on the command line. The last 2 properties, SurfaceArea
%   and Volume, are also omitted, because their values are only needed in
%   certain cases.
%
%   Examples
%   --------
%   % Construct a spheroid that models the Earth as a sphere with
%   % radius 6,371,000 meters, then compute its surface area (in
%   % square meters) and volume (in cubic meters).
%   s = map.geodesy.Sphere;
%   s.Radius = 6371000
%   s.SurfaceArea
%   s.Volume
%
%   See also oblateSpheroid, referenceEllipsoid, referenceSphere

% Copyright 2019-2020 The MathWorks, Inc.

%#codegen
 
    properties (Dependent = true)
        %Radius Radius of reference sphere
        %
        %   Positive, finite scalar.
        %   Default value: 1
        Radius (1,1) double {mustBePositive, mustBeFinite}
    end
    
    properties (Dependent = true, SetAccess = private)
        %SemimajorAxis Equatorial radius of sphere
        %
        %   Positive, finite scalar. Its value is equal to Radius
        %   and cannot be set.
        SemimajorAxis
        
        %SemiminorAxis Distance from center of sphere to pole
        %
        %   Positive, finite scalar. Its value is equal to Radius
        %   and cannot be set.
        SemiminorAxis
    end
    
    properties (Constant = true)
        %InverseFlattening Reciprocal of flattening
        %
        %   This property is provided for consistency with the oblate
        %   spheroid class. Its value is always Inf.
        InverseFlattening = Inf;
        
        %Eccentricity First eccentricity of sphere
        %
        %   This property is provided for consistency with the oblate
        %   spheroid class. Its value is always 0.
        Eccentricity = 0;
        
        %Flattening Flattening of sphere
        %
        %   This property is provided for consistency with the oblate
        %   spheroid class. Its value is always 0.
        Flattening = 0;
        
        
        %ThirdFlattening Third flattening of sphere
        %
        %   This property is provided for consistency with the oblate
        %   spheroid class. Its value is always 0.
        ThirdFlattening = 0;
    end
    
    properties (Dependent = true)
        %MeanRadius Mean radius of sphere
        %
        %   This property is provided for consistency with the oblate
        %   spheroid class. Its value is always equal to Radius.
        MeanRadius
        
        %SurfaceArea Surface area of sphere
        %
        %   Surface area of the sphere in units of area consistent with the
        %   LengthUnit property value. For example, if LengthUnit is
        %   'kilometer' then SurfaceArea is in square kilometers.
        SurfaceArea
        
        %Volume Volume of sphere
        %
        %   Volume of the sphere in units of volume consistent with the
        %   LengthUnit property value. For example, if LengthUnit is
        %   'kilometer' then Volume is in cubic kilometers.
        Volume
    end
    
    properties (SetAccess = protected, Hidden = true)
        a (1,1) double = 1;   % Stores value of Radius
    end
    
    properties (Constant, Hidden, Access = protected)
        % Control the display of map.geodesy.Sphere objects.

        DerivedProperties = {'SemimajorAxis','SemiminorAxis', ...
            'InverseFlattening','Eccentricity','Flattening', ...
            'ThirdFlattening','MeanRadius','SurfaceArea','Volume'};
        
        DisplayFormat = '';   % Always use the current setting.
    end
    
    %--------------------------- Get methods ------------------------------
    
    methods
        function radius = get.Radius(obj)
            radius = obj.a;
        end
        
        function a = get.SemimajorAxis(obj)
            a = obj.a;
        end
        
        function b = get.SemiminorAxis(obj)
            b = obj.a;
        end
        
        function radius = get.MeanRadius(obj)
            radius = obj.a;
        end
        
        function surfarea = get.SurfaceArea(obj)
            surfarea = 4 * pi * obj.a^2;
        end
        
        function vol = get.Volume(obj)
            vol = (4*pi/3) * obj.a^3;
        end
    end
    
    %---------------------------- Set method -----------------------------
    
    methods
        function obj = set.Radius(obj, radius)
            obj.a = radius;
        end
    end
end
