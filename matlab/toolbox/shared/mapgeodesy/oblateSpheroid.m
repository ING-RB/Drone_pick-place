classdef (Hidden) oblateSpheroid < map.geodesy.Spheroid
%

% Copyright 2011-2023 The MathWorks, Inc.

%#codegen

%   The values of the following four geometric properties can be reset:
%   SemimajorAxis, SemiminorAxis, InverseFlattening, or Eccentricity.
%   However, only two parameters are actually needed to fully characterize
%   an oblate spheroid, so updates to these parameters are not independent.
%   Instead, they adhere to the following self-consistent rules:
%
%    1. The only way to change the SemimajorAxis property is to set it
%       directly.
%
%    2. If the SemimajorAxis property is reset, the SemiminorAxis
%       property is updated as needed to preserve the aspect of the
%       spheroid. The values of the InverseFlattening and Eccentricity
%       properties are unchanged.
%
%    3. If any of the following three properties, SemiminorAxis,
%       InverseFlattening, or Eccentricity, are reset, then the values of
%       the other two properties are adjusted to match the new aspect.
%       The value of the SemimajorAxis property is unchanged.
%
%   In other words, given an oblate spheroid s,
%
%       s.SemimajorAxis = a        updates semimajor and semiminor axes,
%                                  a and b
%
%       s.SemiminorAxis = b,       updates the semiminor axis, b, 
%       s.InverseFlatting = 1/f,   the eccentricity, ecc, and the inverse
%       or s.Eccentricity = ecc    flattening, 1/f

    %------------------- Properties: Public + visible --------------------
    
    properties (Dependent = true, Access = public)
        SemimajorAxis
        SemiminorAxis
        InverseFlattening
        Eccentricity
    end
    
    properties (GetAccess = public, SetAccess = private)
        Flattening = 0;
        ThirdFlattening = 0;
    end
    
    properties (Dependent = true, SetAccess = private)
        MeanRadius
        SurfaceArea
        Volume
    end
    
    %-------------------------- Hidden properties -------------------------
    
    % Because of their interdependence, the 4 settable properties have to
    % be implemented as dependent properties. Their values are actually
    % stored in the following 4 hidden (and non-dependent) properties,
    % which are updated carefully by the set methods to ensure consistency
    % (both mutual consistency and consistency with the Flattening and
    % ThirdFlattening properties, as well).

    % The default values given below, together with the defaults for the
    % Flattening and ThirdFlattening properties, imply that the default
    % oblate sphere is the units sphere.  (An explicit constructor is not
    % needed and is omitted.)
    
    properties (Hidden = true, SetAccess = protected)
        a = 1;        % Stores value of SemimajorAxis
    end
    
    properties (Hidden = true, Access = protected)
        b = 1;        % Stores value of SemiminorAxis
        invf = Inf;   % Stores value of InverseFlattening
        ecc = 0;      % Stores value of Eccentricity
    end
    
    properties (Constant, Hidden, Access = protected)
        % Control the display of oblateSpheroid objects.
        
        DerivedProperties = {'Flattening','ThirdFlattening',...
            'MeanRadius','SurfaceArea','Volume'};
        
        DisplayFormat = 'longG';
    end
    
    %--------------------------- Get methods ------------------------------
    
    methods
        
        function a = get.SemimajorAxis(obj)
            a = obj.a;
        end
        
        function b = get.SemiminorAxis(obj)
            b = obj.b;
        end
        
        function invf = get.InverseFlattening(obj)
            invf = obj.invf;
        end
        
        function ecc = get.Eccentricity(obj)
            ecc = obj.ecc;
        end
        
        function radius = get.MeanRadius(obj)
            radius = (2*obj.a + obj.b) / 3;
        end
        
        function surfarea = get.SurfaceArea(obj)
            e = obj.ecc;
            if e < 1e-10
                % Sphere (or nearly spherical ellipsoid)
                surfarea = 4 * pi * obj.a^2;
            elseif e < 1
                % Intermediate
                s = (log((1+e)/(1-e))/e)/2;
                surfarea = 2 * pi * (obj.a^2 + s * obj.b^2);
            else
                % Flat, two-sided disk
                surfarea = 2 * pi * obj.a^2;
            end
        end
        
        function vol = get.Volume(obj)
            vol = (4*pi/3) * obj.b * obj.a^2;
        end
        
    end
    
    %---------------------------- Set methods -----------------------------
    
    methods
        
        function obj = set.SemimajorAxis(obj, a)
            validateattributes(a, ...
                {'double'}, {'real','positive','finite','scalar'}, ...
                '', 'SemimajorAxis');
            obj.a = a;
            obj.b = (1 - obj.Flattening) * a;
        end
        
        
        function obj = set.SemiminorAxis(obj, b)
            validateattributes(b, ...
                {'double'}, {'real','nonnegative','finite','scalar'}, ...
                '', 'SemiminorAxis');
            a_ = obj.a;
            coder.internal.errorIf(b > a_,'geodesy:spheroid:ExpectedShorterSemiminorAxis')
            obj.b = b;            
            obj.ecc = sqrt(a_^2 - b^2) / a_;
            f = (a_ - b) / a_;
            obj.invf = 1/f;
            obj.Flattening = f;
            obj.ThirdFlattening = f / (2 - f);
        end
        
        
        function obj = set.InverseFlattening(obj, invf)
            validateattributes(invf, {'double'}, ...
                {'real','scalar','>=',1},'','InverseFlattening');
            f  = 1 / invf;
            obj.ecc  = sqrt((2 - f) * f);
            obj.invf = invf;
            obj.Flattening = f;
            obj.ThirdFlattening = f / (2 - f);
            obj.b = (1 - obj.Flattening) * obj.a;
        end
        
        
        function obj = set.Eccentricity(obj, ecc)
            validateattributes(ecc, {'double'}, ...
                {'real','nonnegative','scalar','<=',1},'','Eccentricity');
            obj.ecc = ecc;
            e2 = ecc ^ 2;
            % The obvious formula for converting eccentricity to flattening
            % is f = 1 - sqrt(1 - e2), but the following is equivalent
            % algebraically and provides better numerical precision:
            f = e2 / (1 + sqrt(1 - e2));
            obj.b = (1 - f) * obj.a;
            obj.invf = 1 / f;
            obj.Flattening = f;
            obj.ThirdFlattening = f / (2 - f);
        end
    end
end
