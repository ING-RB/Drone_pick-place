function annotation = dimensionAndTypeAnnotation(obj, displayConfiguration)
% DIMENSIONANDTYPEANNOTATION Generates annotations for object dimensions and class name.
%
%   ANNOTATION = DIMENSIONANDTYPEANNOTATION(OBJ, DISPLAYCONFIGURATION) returns
%   a string array where each element is an annotation for the corresponding
%   row in OBJ. Each annotation includes the dimensions and class name of the
%   object in that row, formatted according to DISPLAYCONFIGURATION.
%
%   See also matlab.display.DimensionsAndClassNameRepresentation.

%   Copyright 2024 The MathWorks, Inc.

    import matlab.display.DimensionsAndClassNameRepresentation;

    numRows = size(obj, 1);
    annotation = strings(numRows, 1);
    for idx = 1:numRows   % Add text for each row
        dimAndClsName = DimensionsAndClassNameRepresentation(obj(idx, :), displayConfiguration);
        annotation(idx) = dimAndClsName.DimensionsString + " " + dimAndClsName.ClassName;
    end
end
