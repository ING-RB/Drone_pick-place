function [displayRep, numElemsUsed] = widthConstrainedDataRepresentation(obj, displayConfiguration, width, optionalParams)
% widthConstrainedDataRepresentation Build a text representation using some 
% or all elements of the array.
%
%   [rep, numElemsUsed] = widthConstrainedDataRepresentation(obj, displayConfig, 
%   width) returns a PlainTextRepresentation object rep for input array obj 
%   using the string converter method defined by the class of obj.  The 
%   resulting representation fits as many elements as possible given the 
%   input width value.  If not all elements fit, the resulting array will 
%   have an ellipsis appended to the end to indicate that the resulting 
%   representation describes a subset of the elements.  The number of 
%   elements described by the representation is returned in output numElemsUsed.
%   
%   [rep, numElemsUsed] = widthConstrainedDataRepresentation(..., 
%   StringArray = strArray) returns a PlainTextRepresentation object rep 
%   using the input string array.  Use this form of widthConstrainedDataRepresentation 
%   when obj does not have a string converter method or when the converter 
%   does not create a string array suitable for use as a compact display 
%   representation.  If the specified string array cannot fit in the given 
%   width, it will be truncated and an ellipsis appended to the display 
%   representation.
%   
%   [rep, numElemsUsed] = widthConstrainedDataRepresentation(...,
%   Annotation = annotation) appends the specified annotation to the display 
%   representation.
%   
%   [rep, numElemsUsed = widthConstrainedDataRepresentation(...,
%   MimimumElementsToDisplay = minElems) uses minElems as a limit on the 
%   number of elements from input array obj to include in the display 
%   representation. If it cannot fit at least minElems, a DimensionsAndClassNameRepresentation 
%   object is returned and numElemsUsed is 0.
%   
%   [rep, numElemsUsed] = widthConstrainedDataRepresentation(...,
%   AllowTruncatedDisplayForScalar = tf) uses AllowTruncatedDisplayForScalar to determine if
%   string scalars are truncated. When tf is set to true and obj is represented
%   as a string scalar (single-line layout) or a column vector of string
%   scalars (columnar layout), the method truncates the string scalars, if
%   necessary, to make them fit within the available width. It replaces the
%   removed characters from the tails of the string scalars with an
%   ellipsis symbol. When tf is set to false (the default), no truncation is 
%   applied to the string scalars. If the string scalars do not fit in the
%   available width, the method returns a DimensionsAndClassNameRepresentation 
%   object with numElemsUsed set to zero.
%
%   Examples:
%   
%   Example 1:
%   [rep, numElems] = widthConstrainedDataRepresentation(obj, 
%      displayConfiguration, 8, StringArray = ["dog" "cat" "bird"])
%
%   Example 2:
%   [rep, numElems] = widthConstrainedDataRepresentation(obj, 
%      displayConfiguration, 14, StringArray = ["dog "cat" "bird"])
% 
%   See also CompactDisplayProvider/partialDataRepresentation,
%   CompactDisplayProvider/fullDataRepresentation,
%   matlab.display.DimensionsAndClassNameRepresentation,
%   matlab.display.PlainTextRepresentation

%   Copyright 2020-2023 The MathWorks, Inc.
arguments
    obj matlab.display.internal.CompactDisplayProvider
    displayConfiguration (1,1) matlab.display.DisplayConfiguration
    width (1,1) double {mustBeReal, mustBePositive}
    % Optional parameters
    % Textual representation of the input object
    optionalParams.StringArray string = string(obj)
    % Optional description displayed alongside the object
    optionalParams.Annotation (:,1) string {matlab.display.internal.compactdisplayvalidators.validateAnnotation(optionalParams.Annotation, obj, displayConfiguration)} = ""
    % Allow scalar object display to be truncated if not enough
    % room to display it
    optionalParams.AllowTruncatedDisplayForScalar (1,1) logical
    % Allow scalar object display to be truncated if not enough
    % room to display it
    optionalParams.TruncateScalarObject (1,1) logical
    % Minimum number of elements that must be displayed before
    % defaulting to dimensions and class name
    optionalParams.MinimumElementsToDisplay (1,1) double {mustBeReal, mustBePositive, mustBeInteger} = 1;
end
import matlab.display.PlainTextRepresentation;
import matlab.display.DimensionsAndClassNameRepresentation;

% Internal display helper functions for compact display
import matlab.display.internal.compactdisplayvalidators.validateStringArray;
import matlab.display.internal.compactdisplayvalidators.canObjectBeTruncated;
import matlab.display.internal.compactdisplayvalidators.isObjectShapeValidForLayout;
import matlab.display.internal.getStringElements;
import matlab.display.internal.getStringArrayWidth;
import matlab.display.internal.getAlignedColumnStringArray;
import matlab.display.internal.getTruncatedStringArray;

if ~isfield(optionalParams, "AllowTruncatedDisplayForScalar")
    if isfield(optionalParams, "TruncateScalarObject")
        % If the input does not contain AllowTruncatedDisplayForScalar and
        % if a value is assigned to TruncateScalarObject parameter and assign
        % its value
        optionalParams.AllowTruncatedDisplayForScalar = optionalParams.TruncateScalarObject;
    else
        % If both AllowTruncatedDisplayForScalar and TruncateScalarObject
        % parameters are empty, set AllowTruncatedDisplayForScalar to the
        % default - false
        optionalParams.AllowTruncatedDisplayForScalar = false;
    end
end

if ~isempty(optionalParams.Annotation) && ~all(ismissing(optionalParams.Annotation)) && ...
        ~all(strlength(optionalParams.Annotation) == 0)
    % Compute annotation character width if it is set to
    % a non-empty string
    % Omit computing the width for missing elements as this
    % will result in an error
    nonMissingElementIndices = ~ismissing(optionalParams.Annotation);
    annotationWidth = characterWidthForStringArray(displayConfiguration, optionalParams.Annotation(nonMissingElementIndices));
    % Find the widest annotation value since this element will
    % determine the width of the entire annotation column
    maxAnnotationWidth = max(annotationWidth);
    annotationWidth = maxAnnotationWidth + ...
        characterWidthForStringArray(displayConfiguration, displayConfiguration.AnnotationPadding) + ...
        sum(characterWidthForStringArray(displayConfiguration, displayConfiguration.AnnotationDelimiters));
else
    annotationWidth = 0;
end

if ~isempty(obj) && isObjectShapeValidForLayout(obj, displayConfiguration)
    % Input object, obj, should be a row vector
    % with at least one element to display to
    % build a valid PlainTextRepresentation object
    
    % Error if 1) the input StringArray is empty and the input
    % object, obj, is not empty; 2) For columnar layouts, the
    % number of rows in obj does not match the number of rows
    % in StringArray
    validateStringArray(optionalParams.StringArray, obj, displayConfiguration);
    
    pad = displayConfiguration.InterElementDelimiter;
    padWidth = characterWidthForStringArray(displayConfiguration, pad);
    dataDelimitersWidth = sum(characterWidthForStringArray(displayConfiguration, displayConfiguration.DataDelimiters));
    ellipsisWithSpaces = displayConfiguration.Ellipsis + pad;
    ellipsisWithSpacesWidth = characterWidthForStringArray(displayConfiguration, ellipsisWithSpaces);
    numElemsUsed = 0;
    
    % Replace emtpy and missing elements with string(missing)
    processedStringArr = getStringElements(optionalParams.StringArray);
    
    % Compute width information of the object string array
    widthArray = getStringArrayWidth(processedStringArr, displayConfiguration, true);
    maxWidthPerColumn = max(widthArray, [], 1);
    
    % Determine if the object that is being displayed is scalar
    % to pass this information to PlaintTextRepresentation
    % class constructor
    isScalarObject = isscalar(optionalParams.StringArray);
    
    if optionalParams.AllowTruncatedDisplayForScalar && canObjectBeTruncated(obj, optionalParams.StringArray, displayConfiguration)
        % If the input object can be truncated and
        % AllowTruncatedDisplayForScalar flag is set to true, attempt to
        % truncate the string representation of the object to
        % fit as much as possible and append an ellipsis at the
        % end if the object string cannot be displayed in full
        
        % Attempt to fit the entire object in the available
        % width
        stringRep = getAlignedColumnStringArray(processedStringArr, widthArray, maxWidthPerColumn, displayConfiguration);
        displayRep = PlainTextRepresentation(obj, stringRep, displayConfiguration, "Annotation", optionalParams.Annotation, ...
            'IsScalarObject', isScalarObject);
        if displayRep.CharacterWidth > width
            % If the scalar object does not fit in available
            % width, attempt to truncate it
            ellipsisWidth = characterWidthForStringArray(displayConfiguration, displayConfiguration.Ellipsis);
            effectiveWidth = width - annotationWidth - ellipsisWidth - dataDelimitersWidth;
            if effectiveWidth > 0
                truncatedStringArr = getTruncatedStringArray(processedStringArr, effectiveWidth, displayConfiguration);
                
                % Compute width difference between string array that
                % contains full data vs the one that contains the truncated
                % data
                widthDiff = characterWidthForStringArray(displayConfiguration, processedStringArr) - characterWidthForStringArray(displayConfiguration, truncatedStringArr);
                % Append ellipsis only to rows that were truncated
                truncatedIndices = widthDiff > ellipsisWidth;
                truncatedStringArr(truncatedIndices) = truncatedStringArr(truncatedIndices) + displayConfiguration.Ellipsis;
                % Display full data for indices that fit in the available
                % width
                fullDataIndices = widthDiff == ellipsisWidth;
                truncatedStringArr(fullDataIndices) = processedStringArr(fullDataIndices);
                
                % Compute width information of the truncated string array
                widthArray = getStringArrayWidth(truncatedStringArr, displayConfiguration, true);
                maxWidthPerColumn = max(widthArray, [], 1);
                
                stringRep = getAlignedColumnStringArray(truncatedStringArr, widthArray, maxWidthPerColumn, displayConfiguration);
                numElemsUsed = 1;
                displayRep = PlainTextRepresentation(obj, stringRep, displayConfiguration, "Annotation", optionalParams.Annotation, ...
                    'IsScalarObject', isScalarObject);
            else
                % If there is not enough space to fit at least
                % one character of the object textual
                % representation, default to dimensions and
                % class name
                displayRep = DimensionsAndClassNameRepresentation(obj, displayConfiguration, "Annotation", optionalParams.Annotation);
            end
        end
    else
        % If the input object is not scalar or
        % AllowTruncatedDisplayForScalar is not set to true, attempt to fit as
        % many elements as possible of the array in the
        % available width without truncating any of them
        numColumns = size(optionalParams.StringArray, 2);
        
        if numColumns < optionalParams.MinimumElementsToDisplay
            % Error if the number of elements in StringArray is
            % less than the MinimumElementsToDisplay
            error(message('MATLAB:display:TooFewElementsInStringArray', "MinimumElementsToDisplay"));
        end
        
        widthOfFullArray = sum(maxWidthPerColumn,2) + padWidth*(numColumns-1);
        effectiveWidth = width - annotationWidth - dataDelimitersWidth;
        
        if widthOfFullArray <= effectiveWidth
            % The entire array fits in the available width, set
            % numElemsUsed to the number of columns in the string
            % array. 
            % This accounts for the edge case where the width of the
            % padded string that shows all the elements is less than
            % the width of the padded string that shows a sub-set of
            % the elements with an ellipsis at the end.
            numElemsUsed = numColumns;
        else
            % Not all elements in the string array fit in the 
            % available width. Iterate over each of the elements to
            % figure out how many elements can fit
            currentWidth = 0;
            for column = 1:numColumns
                if column == numColumns
                    % If we are at the last element, no ellipsis is
                    % required at the end of the output string
                    effectiveWidth = width - annotationWidth - dataDelimitersWidth;
                    currentWidth = currentWidth + maxWidthPerColumn(column);
                else
                    % If this is not the last element of the object
                    % string array, an ellipsis needs to be appended at
                    % the end of the output string
                    effectiveWidth = width - annotationWidth - dataDelimitersWidth - ellipsisWithSpacesWidth;
                    currentWidth = currentWidth + maxWidthPerColumn(column) + padWidth;
                end
                if currentWidth <= effectiveWidth
                    % If the width of the resulting display string
                    % is less than the available width
                    % continue iterating over the string
                    % array and update the number of elements that
                    % fit in the available width, numElemsUsed,
                    % accordingly
                    numElemsUsed = column;
                else
                    % If the width of the resulting display string
                    % has exceeded the available width stop the
                    % for loop
                    break;
                end
            end
        end
        
        if numElemsUsed < optionalParams.MinimumElementsToDisplay
            % Default to dimensions and class name if none of the
            % elements fit in the available width or the number of
            % elements fitting is less than the specified minimum
            displayRep = DimensionsAndClassNameRepresentation(obj, displayConfiguration, 'Annotation', optionalParams.Annotation);
        else
            stringRep = getAlignedColumnStringArray(processedStringArr, widthArray, maxWidthPerColumn, displayConfiguration, numElemsUsed);
            displayRep = PlainTextRepresentation(obj, stringRep, displayConfiguration, 'Annotation',optionalParams.Annotation, ...
                'IsScalarObject', isScalarObject);
        end
    end
else
    % If input object, OBJ, has more than 2 dimensions, or more
    % than one row, or is empty
    % partialDataRepresentation will default to
    % DimensionsAndClassNameRepresentation
    displayRep = DimensionsAndClassNameRepresentation(obj, displayConfiguration, 'Annotation',optionalParams.Annotation);
    numElemsUsed = 0;
end
end