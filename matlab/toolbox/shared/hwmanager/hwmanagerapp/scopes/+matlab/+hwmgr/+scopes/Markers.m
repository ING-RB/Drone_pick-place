classdef Markers < double
%Markers   Marker types of LineProperties in Hardware Manager scopes
%
%   See also LineProperties

%   Copyright 2019-2020 The MathWorks, Inc.
    
    enumeration
        %None - No markers
        None (0)
        
        %Plus - Plus sign
        Plus (1)
        
        %Circle - Circle
        Circle (2)
        
        %Point - Point
        Point (3)
        
        %Cross - Cross
        Cross (4)
        
        %Square - Square
        Square (5)
        
        %TriangleDown - Downward-pointing triangle
        TriangleDown (6)
        
        %TriangleUp - Upward-pointing triangle
        TriangleUp (7)
        
        %TriangleRight - Right-pointing triangle
        TriangleRight (8)
        
        %TriangleLeft - Left-pointing triangle
        TriangleLeft (9)
        
        %Diamond - Diamond
        Diamond (10)
        
        %Pentagram - Five-pointed star (pentagram)
        Pentagram (11)
        
        %Hexagram - Six-pointed star (hexagram)
        Hexagram (12)        
    end
end