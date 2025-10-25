classdef units
%mlreportgen.utils.units Set of functions to convert from one unit to another.
%
%   units methods:
%
%       toPixels        - Convert to pixel units
%       toPoints        - Convert to point units
%       toInches        - Convert to inch units
%       toCentimeters   - Convert to centimeter units
%       toMillimeters   - Convert to millimeter units
%       toPicas         - Convert to pica units
%
%   See also: toPixels, toPoints, toInches, toCentimeters, toMillimeters, toPicas

     
    %  Copyright 2017-2020 The MathWorks, Inc.

    methods
        function out=units
        end

        function out=isValidDimensionString(~) %#ok<STOUT>
        end

        function out=toCentimeters(~) %#ok<STOUT>
            %toCentimeters  Convert to centimeter units
            %   value = mlreportgen.utils.units.toCentimeters(lengthUnits) converts 
            %   lengthUnits to a centimeter numeric length value. A lengthUnit has 
            %   two parts. The first part represents the numeric value, and the 
            %   second part represents the unit type of the lengthUnits.
            %
            %   value = mlreportgen.utils.units.toCentimeters(numericLength, ...
            %   stringUnits) converts a numeric value and a string unit type to a
            %   centimeter numeric value.
            %
            %   value = mlreportgen.utils.units.toCentimeters(numericLength, ...
            %   stringUnits, "DPI", dpi) converts a numeric value and a string unit 
            %   type to a centimeter numeric value. DPI is an optional parameter that 
            %   is the conversion factor for overriding MATLAB screen pixels to 
            %   inches.
            %
            %   A unit type can be one of the following:
            %
            %       Abbreviation    Units
            %       px              pixels
            %       cm              centimeters
            %       in              inches
            %       mm              millimeters
            %       pc              picas
            %       pt              points
            %
            %   Example:
            %
            %   value = mlreportgen.utils.units.toCentimeters("5pt");
            %   value = mlreportgen.utils.units.toCentimeters("5 pt");
            %   value = mlreportgen.utils.units.toCentimeters("5points");
            %   value = mlreportgen.utils.units.toCentimeters("5 points");
            %   value = mlreportgen.utils.units.toCentimeters("5point");
            %   value = mlreportgen.utils.units.toCentimeters("5 point");
            %
            %   value = mlreportgen.utils.units.toCentimeters(5, "pt");
            %   value = mlreportgen.utils.units.toCentimeters(5, "points");
            %
            %   value = mlreportgen.utils.units.toCentimeters("96px", "DPI", 96);
            %   value = mlreportgen.utils.units.toCentimeters(96, "pixels", "DPI", 96);
        end

        function out=toInches(~) %#ok<STOUT>
            %toInches   Convert to inch units
            %   value = mlreportgen.utils.units.toInches(lengthUnits) converts 
            %   lengthUnits to inch numeric value. A lengthUnit has two parts. The 
            %   first part represents the numeric length value, and the second part 
            %   represents the unit type of the lengthUnits.
            %
            %   value = mlreportgen.utils.units.toInches(numericLength, stringUnits) 
            %   converts a numeric value and a string unit type to an inch numeric 
            %   value.
            %
            %   value = mlreportgen.utils.units.toInches(numericLength, ...
            %   stringUnits, "DPI", dpi) converts a numeric value and a string unit 
            %   type to an inch numeric value. DPI is an optional parameter that is  
            %   the conversion factor for overriding MATLAB screen pixels to inches.
            %
            %   A unit type can be one of the following:
            %
            %       Abbreviation    Units
            %       px              pixels
            %       cm              centimeters
            %       in              inches
            %       mm              millimeters
            %       pc              picas
            %       pt              points
            %
            %   Example:
            %
            %   value = mlreportgen.utils.units.toInches("5pt");
            %   value = mlreportgen.utils.units.toInches("5 pt");
            %   value = mlreportgen.utils.units.toInches("5points");
            %   value = mlreportgen.utils.units.toInches("5 points");
            %   value = mlreportgen.utils.units.toInches("5point");
            %   value = mlreportgen.utils.units.toInches("5 point");
            %
            %   value = mlreportgen.utils.units.toInches(5, "pt");
            %   value = mlreportgen.utils.units.toInches(5, "points");
            %
            %   value = mlreportgen.utils.units.toInches("96px", "DPI", 96);
            %   value = mlreportgen.utils.units.toInches(96, "pixels", "DPI", 96);
        end

        function out=toMillimeters(~) %#ok<STOUT>
            %toMillimeters  Convert to millimeter units
            %   value = mlreportgen.utils.units.toMillimeters(lengthUnits) converts 
            %   lengthUnits to a millimeter numeric length value. A lengthUnit has 
            %   two parts. The first part represents the numeric value, and the 
            %   second part represents the unit type of the lengthUnits.
            %
            %   value = mlreportgen.utils.units.toMillimeters(numericLength, ...
            %   stringUnits) converts a numeric value and a string unit type to 
            %   a millimeter numeric value.
            %
            %   value = mlreportgen.utils.units.toMillimeters(numericLength, ...
            %   stringUnits, "DPI", dpi) converts a numeric value and a string unit 
            %   type to a millimeter numeric value. DPI is an optional parameter that 
            %   is the conversion factor for overriding MATLAB screen pixels to 
            %   inches.
            %
            %   A unit type can be one of the following:
            %
            %       Abbreviation    Units
            %       px              pixels
            %       cm              centimeters
            %       in              inches
            %       mm              millimeters
            %       pc              picas
            %       pt              points
            %
            %   Example:
            %
            %   value = mlreportgen.utils.units.toMillimeters("5pt");
            %   value = mlreportgen.utils.units.toMillimeters("5 pt");
            %   value = mlreportgen.utils.units.toMillimeters("5points");
            %   value = mlreportgen.utils.units.toMillimeters("5 points");
            %   value = mlreportgen.utils.units.toMillimeters("5point");
            %   value = mlreportgen.utils.units.toMillimeters("5 point");
            %
            %   value = mlreportgen.utils.units.toMillimeters(5, "pt");
            %   value = mlreportgen.utils.units.toMillimeters(5, "points");
            %
            %   value = mlreportgen.utils.units.toMillimeters("96px", "DPI", 96);
            %   value = mlreportgen.utils.units.toMillimeters(96, "pixels", "DPI", 96);
        end

        function out=toPicas(~) %#ok<STOUT>
            %toPicas    Convert to pica units
            %   value = mlreportgen.utils.units.toPicas(lengthUnits) converts 
            %   lengthUnits to a pica numeric value. A lengthUnit has two parts. 
            %   The first part represents the numeric length value, and the second 
            %   part represents the unit type of the lengthUnits.
            %
            %   value = mlreportgen.utils.units.toPicas(numericLength, stringUnits) 
            %   converts a numeric value and a string unit type to a pica numeric 
            %   value.
            %
            %   value = mlreportgen.utils.units.toPicas(numericLength, ...
            %   stringUnits, "DPI", dpi) converts a numeric value and a string unit 
            %   type to a pica numeric value. DPI is an optional parameter that is  
            %   the conversion factor for overriding MATLAB screen pixels to inches.
            %
            %   A unit type can be one of the following:
            %
            %       Abbreviation    Units
            %       px              pixels
            %       cm              centimeters
            %       in              inches
            %       mm              millimeters
            %       pc              picas
            %       pt              points
            %
            %   Example:
            %
            %   value = mlreportgen.utils.units.toPicas("5pt");
            %   value = mlreportgen.utils.units.toPicas("5 pt");
            %   value = mlreportgen.utils.units.toPicas("5points");
            %   value = mlreportgen.utils.units.toPicas("5 points");
            %   value = mlreportgen.utils.units.toPicas("5point");
            %   value = mlreportgen.utils.units.toPicas("5 point");
            %
            %   value = mlreportgen.utils.units.toPicas(5, "pt");
            %   value = mlreportgen.utils.units.toPicas(5, "points");
            %
            %   value = mlreportgen.utils.units.toPicas("96px", "DPI", 96);
            %   value = mlreportgen.utils.units.toPicas(96, "pixels", "DPI", 96);
        end

        function out=toPixels(~) %#ok<STOUT>
            %toPixels	Convert to pixel units
            %   value = mlreportgen.utils.units.toPixels(lengthUnits) converts 
            %   lengthUnits to a pixel numeric value. A lengthUnit has two parts.
            %   The first part represents the numeric length value, and  the second 
            %   part represents the unit type of the lengthUnits.
            %
            %   value = mlreportgen.utils.units.toPixels(numericLength, stringUnits) 
            %   converts a numeric value and a string unit type to a pixel numeric 
            %   value.
            %
            %   value = mlreportgen.utils.units.toPixels(numericLength, ...
            %   stringUnits, "DPI", dpi) converts a numeric value and a string unit 
            %   type to a pixel numeric value. DPI is an optional parameter that is  
            %   the conversion factor for overriding MATLAB screen pixels to inches.
            %
            %   A unit type can be one of the following:
            %
            %       Abbreviation    Units
            %       px              pixels
            %       cm              centimeters
            %       in              inches
            %       mm              millimeters
            %       pc              picas
            %       pt              points
            %
            %   Example:
            %
            %   value = mlreportgen.utils.units.toPixels("5in");
            %   value = mlreportgen.utils.units.toPixels("5 in");
            %   value = mlreportgen.utils.units.toPixels("5inches");
            %   value = mlreportgen.utils.units.toPixels("5 inches");
            %   value = mlreportgen.utils.units.toPoints("5inch");
            %   value = mlreportgen.utils.units.toPoints("5 inch");
            %
            %   value = mlreportgen.utils.units.toPixels(5, "in");
            %   value = mlreportgen.utils.units.toPixels(5, "inches");
            %
            %   value = mlreportgen.utils.units.toPixels("5inches", "DPI", 96);
            %   value = mlreportgen.utils.units.toPixels(5, "inches", "DPI", 96);
        end

        function out=toPoints(~) %#ok<STOUT>
            %toPoints   Convert to point units
            %   value = mlreportgen.utils.units.toPoints(lengthUnits) converts  
            %   lengthUnits to a point numeric value. A lengthUnit has two parts. 
            %   The first part represents the numeric length value, and the second 
            %   part represents the unit type of the lengthUnits.
            %
            %   value = mlreportgen.utils.units.toPoints(numericLength, stringUnits) 
            %   converts a numeric value and a string unit type to a point numeric 
            %   value.
            %
            %   value = mlreportgen.utils.units.toPoints(numericLength, ...
            %   stringUnits, "DPI", dpi) converts a numeric value and a string unit 
            %   type to a point numeric value. DPI is an optional parameter that is 
            %   the conversion factor for overriding MATLAB screen pixels to inches.
            %
            %   A unit type can be one of the following:
            %
            %       Abbreviation    Units
            %       px              pixels
            %       cm              centimeters
            %       in              inches
            %       mm              millimeters
            %       pc              picas
            %       pt              points
            %
            %   Example:
            %
            %   value = mlreportgen.utils.units.toPoints("5in");
            %   value = mlreportgen.utils.units.toPoints("5 in");
            %   value = mlreportgen.utils.units.toPoints("5inches");
            %   value = mlreportgen.utils.units.toPoints("5 inches");
            %   value = mlreportgen.utils.units.toPoints("5inch");
            %   value = mlreportgen.utils.units.toPoints("5 inch");
            %
            %   value = mlreportgen.utils.units.toPoints(5, "in");
            %   value = mlreportgen.utils.units.toPoints(5, "inches");
            %
            %   value = mlreportgen.utils.units.toPoints("5px", "DPI", 96);
            %   value = mlreportgen.utils.units.toPoints(5, "pixels", "DPI", 96);
        end

    end
end
