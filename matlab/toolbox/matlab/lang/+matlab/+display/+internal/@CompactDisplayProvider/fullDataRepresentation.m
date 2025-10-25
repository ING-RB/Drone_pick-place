function displayRep = fullDataRepresentation(obj, displayConfiguration, optionalParams)
% fullDataRepresentation Build a text representation from all data in the
% object array using its string converter method
%
%   rep = fullDataRepresentation(obj, displayConfiguration) builds the text 
%   representation for the input object obj, using the string converter method
%   defined by the class of obj. It concatenates all of the elements of the
%   resulting string array into a final text representation of the array.
% 
%   rep = fullDataRepresentation(..., StringArray = strArr) builds the text
%   representation for the input object obj, using the input string strArr,
%   concatenating the results into a final text representation of the
%   array.
%   
%   rep = fullDataRepresentation(..., Annotation = annotation) builds the 
%   text representation for the input object obj, and appends an
%   annotation next to the data.
%   
%   See also CompactDisplayProvider/partialDataRepresentation,
%   CompactDisplayProvider/widthConstrainedDataRepresentation,
%   matlab.display.PlainTextRepresentation

%   Copyright 2020-2021 The MathWorks, Inc.
arguments
    obj matlab.display.internal.CompactDisplayProvider
    displayConfiguration (1,1) matlab.display.DisplayConfiguration
    % Optional parameters
    % Textual representation of the input object
    optionalParams.StringArray string = string(obj)
    % Optional description displayed alongside the object
    optionalParams.Annotation (:,1) string {matlab.display.internal.compactdisplayvalidators.validateAnnotation(optionalParams.Annotation, obj, displayConfiguration)} = ""
end

import matlab.display.PlainTextRepresentation;
import matlab.display.DimensionsAndClassNameRepresentation;

% Internal display helper functions for compact display
import matlab.display.internal.compactdisplayvalidators.validateStringArray;
import matlab.display.internal.compactdisplayvalidators.isObjectShapeValidForLayout;
import matlab.display.internal.getStringElements;
import matlab.display.internal.getStringArrayWidth;
import matlab.display.internal.getAlignedColumnStringArray;

if ~isempty(obj) && isObjectShapeValidForLayout(obj, displayConfiguration)
    % Input object, OBJ, should meet shape constraints imposed
    % by the display layout in order to build a valid
    % PlainTextRepresentation object
    
    % Error if 1) the input StringArray is empty and the input
    % object, OBJ, is not empty; 2) For columnar layouts, the
    % number of rows in OBJ does not match the number of rows
    % in StringArray
    validateStringArray(optionalParams.StringArray, obj, displayConfiguration);
    
    % Replace empty and missing elements in StringArray by
    % string(missing)
    processedStringArray = getStringElements(optionalParams.StringArray);
    % Get the character widht of each of the elements of the
    % input StringArray
    widthArray = getStringArrayWidth(processedStringArray, displayConfiguration);
    maxWidthPerColumn = max(widthArray, [], 1);
    % Get padded and aligned string array to build
    % PlainTextRepresentation object
    stringRep = getAlignedColumnStringArray(processedStringArray, widthArray, maxWidthPerColumn, displayConfiguration);
    
    displayRep = PlainTextRepresentation(obj, stringRep, displayConfiguration, 'Annotation',optionalParams.Annotation, ...
        'IsScalarObject', isscalar(optionalParams.StringArray));
else
    % If input object, OBJ, is not a row vector, or is empty
    % fullDataRepresentation will default to
    % DimensionsAndClassNameRepresentation
    displayRep = DimensionsAndClassNameRepresentation(obj, displayConfiguration, 'Annotation',optionalParams.Annotation);
end
end