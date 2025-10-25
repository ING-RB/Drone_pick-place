%   pointCloudArray Class Hold the data of array of pointClouds
%   for codegen generation

% Copyright 2020 The MathWorks, Inc.
%#codegen

classdef(Hidden) pointCloudArray
    
    properties
        Location
        Normal
        Color
        Intensity
    end
    
    methods
        %==================================================================
        % Constructor
        %==================================================================
        function this = pointCloudArray(varargin)
            narginchk(1,1);
            
            pc = varargin{1};
            this.Location  = pc.Location;
            this.Normal    = pc.Normal;
            this.Color     = pc.Color;
            this.Intensity = pc.Intensity;
        end
    end
end

