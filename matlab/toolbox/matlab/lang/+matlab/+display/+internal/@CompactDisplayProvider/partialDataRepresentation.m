function displayRep =  partialDataRepresentation(obj, displayConfiguration, firstSubArray, secondSubArray, optionalParams)
% partialDataRepresentation Build a text representation from a portion of
% the data in the object array
%
%   rep = partialDataRepresentation(obj, displayConfiguration, s) returns a 
%   PlainTextRepresentation object using string array s, with an ellipsis 
%   appended to the end.  Use this syntax when creating a text representation 
%   of obj using a subset of its elements starting with the leading 
%   elements.
%    
%   rep = partialDataRepresentation(obj, displayConfiguration, s1, s2) returns 
%   a PlainTextRepresentation object using string arrays s1 and s2, 
%   concatentated together with an ellipsis between the two.  Use this 
%   syntax when creating a text representation of the object using leading and 
%   trailing elements of obj.
%   
%   rep = partialDataRepresentation(..., Annotation = annotation) returns a 
%   PlainTextRepresentation object with the specified annotation appended to 
%   the display string.
%
%   Examples:
%
%   Example 1:
%   rep = partialDataRepresentation(obj, displayConfiguration, 
%       ["cat" "dog"], ["rat"])
%
%   Example 2:
%   rep = partialDataRepresentation(obj, displayConfiguration, ["cat" "dog"])
%   
%   See also CompactDisplayProvider/fullDataRepresentation,
%   CompactDisplayProvider/widthConstrainedDataRepresentation,
%   matlab.display.PlainTextRepresentation

%   Copyright 2020-2021 The MathWorks, Inc.
arguments
    obj matlab.display.internal.CompactDisplayProvider
    displayConfiguration (1,1) matlab.display.DisplayConfiguration
    % Portion of the input object to display before the
    % ellipsis
    firstSubArray string
    % Portion of the input object to display after the ellipsis
    secondSubArray string = string.empty;
    % Optional description displayed alongside the object
    optionalParams.Annotation (:,1) string {matlab.display.internal.compactdisplayvalidators.validateAnnotation(optionalParams.Annotation, obj, displayConfiguration)} = ""
end

import matlab.display.PlainTextRepresentation;
import matlab.display.DimensionsAndClassNameRepresentation;

% Internal display helper functions for compact display
import matlab.display.internal.compactdisplayvalidators.validateStringArray;
import matlab.display.internal.compactdisplayvalidators.isObjectShapeValidForLayout;
import matlab.display.internal.getStringElements;

ellipsisWithSpaces = displayConfiguration.InterElementDelimiter + displayConfiguration.Ellipsis + displayConfiguration.InterElementDelimiter;

if ~isempty(obj) && isObjectShapeValidForLayout(obj, displayConfiguration)
    % Input object, OBJ, should meet shape constraints imposed
    % by the display layout in order to build a valid
    % PlainTextRepresentation object
    
    validateStringArray(firstSubArray, obj, displayConfiguration);
    % Replace empty and missing elements by string(missing)
    firstSubArray = getStringElements(firstSubArray);
    
    if ~isempty(secondSubArray)
        % If LAST is not empty, build the full data
        % representation of FIRST and LAST and concatenate them
        % together with an ellipsis in between
        
        validateStringArray(secondSubArray, obj, displayConfiguration);
        % Replace empty and missing elements by string(missing)
        secondSubArray = getStringElements(secondSubArray);
        
        firstRep = fullDataRepresentation(obj, displayConfiguration, 'StringArray', firstSubArray);
        lastRep = fullDataRepresentation(obj, displayConfiguration, 'StringArray', secondSubArray);
        
        stringRep = firstRep.Representation + ellipsisWithSpaces + lastRep.Representation;
    else
        % If LAST is empty, build full data representation for
        % FIRST and append an ellipsis at the end
        firstRep = fullDataRepresentation(obj, displayConfiguration, 'StringArray', firstSubArray);
        
        stringRep = firstRep.Representation + ellipsisWithSpaces;
    end
    displayRep = PlainTextRepresentation(obj, stringRep, displayConfiguration, 'Annotation',optionalParams.Annotation, ...
        'IsScalarObject', false);
else
    % If input object, OBJ, does not meet shape constraints for
    % display layout, default to dimensions and class name
    displayRep = DimensionsAndClassNameRepresentation(obj, displayConfiguration, 'Annotation',optionalParams.Annotation);
end
end