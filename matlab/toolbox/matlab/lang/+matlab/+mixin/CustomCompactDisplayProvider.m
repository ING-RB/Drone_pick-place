classdef (HandleCompatible, Abstract) CustomCompactDisplayProvider < matlab.display.internal.CompactDisplayProvider
    % CustomCompactDisplayProvider Customize compact display of an object
    %   This class provides an interface for customizing object display under 
    %   limited space and/or shape constraints, such as when held within a 
    %   struct, cell array, or another container object.
    
    %   Copyright 2020-2024 The MathWorks, Inc.   
    
    methods  
        function rep = compactRepresentationForSingleLine(obj, displayConfiguration, width)
        % compactRepresentationForSingleLine Single-line display representation 
        % of an object
        arguments
            obj matlab.mixin.CustomCompactDisplayProvider
            displayConfiguration (1,1) matlab.display.DisplayConfiguration
            width (1,1) double
        end
            import matlab.display.DimensionsAndClassNameRepresentation;

            rep = DimensionsAndClassNameRepresentation(obj, displayConfiguration, 'UseSimpleName', true);
        end
        
        function rep = compactRepresentationForColumn(obj, displayConfiguration, width)
        % compactRepresentationForColumn Columnar display representation of 
        % an object
        arguments
            obj matlab.mixin.CustomCompactDisplayProvider
            displayConfiguration (1,1) matlab.display.DisplayConfiguration
            width (1,1) double
        end
            import matlab.display.DimensionsAndClassNameRepresentation;

            rep = DimensionsAndClassNameRepresentation(obj, displayConfiguration, 'UseSimpleName', true);
        end
    end
end