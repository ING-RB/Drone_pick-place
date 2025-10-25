classdef Image< handle
%matlab.system.display.Image   System object display image
%   A = matlab.system.display.Image(P1,V1,...,PN,VN) creates an 
%   image on System object display.  You use
%   matlab.system.display.Image in getPropertyGroupsImpl to assign actions 
%   in property groups.
%
%   Inputs P1,V1,...,PN,VN are property name-value pair arguments 
%   for Label, Description, Placement, and File that you can specify
%   in any order.  
%
%  Image properties:
%      Label           - Image label
%      Description     - Image description
%      Placement       - Image placement

 
%   Copyright 2020 The MathWorks, Inc.

    methods
        function out=Image
            % Parse arguments given default values
        end

    end
    properties
        %Description   Image description
        %   Description of this image as a string.  The default value of 
        %   this property is an empty string.
        Description;

        %File   Image file
        %   File of this image as a string.  The file value cannot be 
        %   empty for the class.
        File;

        %Label   Image label
        %   Label of this image as a string.  The default value of this 
        %   property is an empty string.
        Label;

        %Placement   Image placement in property group
        %   Placement of this image in property group as 'first', 'last', 
        %   or the name of a property in the group.  If set to 'first', 
        %   image is placed above or before the properties.  If set to 
        %   'last', image is placed below or after the properties.  If set 
        %   to a property name, image is inserted before the named 
        %   property.  The default value of this property is 'last'.
        Placement;

    end
end
