classdef IconDataMixin < handle
     % Returns a struct with the following properties, which define the object browser icons:
     % shape:can be one of the following: rect, line, arrow, stem, contour,
     % errorbar, circle or marker styles
     % edgeColor: returns RGB values
     % faceColor: returns RGB values
    
    % Copyright 2021 The MathWorks, Inc.

    methods(Static,Abstract)
         getIconProperties()       
    end
end