function textDisplay = convertObjectToStringForDisplay(objToDisplay, objElemsVisibleToDisplay)
% convertObjectToStringForDisplay returns the display text for the input object
    arguments(Input)
        objToDisplay matlab.mixin.internal.MatrixDisplay {mustBeNonempty}
        objElemsVisibleToDisplay (:,:) matlab.mixin.internal.MatrixDisplay {mustBeNonempty} = objToDisplay
    end
    arguments(Output)
        textDisplay (:,:) string
    end
    textDisplay = string(objElemsVisibleToDisplay);

    % Make sure STRING method output contains a string array or a MISSING 
    % array matching the dimensions of the input object array
    validateStringMethodOutput(textDisplay, objElemsVisibleToDisplay);
    
    % Make sure that missing elements are replaced
    % with the appropriate text
    missingIndices = ismissing(textDisplay);

    % Make sure GETMISSINGTEXTDISPLAY returns a scalar string
    validateMissingTextOutput(getMissingTextDisplay(objElemsVisibleToDisplay));
    missingTextDisp = getMissingTextDisplay(objElemsVisibleToDisplay);
    if all(missingIndices)
        textDisplay = repmat(missingTextDisp, size(textDisplay));
    else
        textDisplay(missingIndices) = missingTextDisp;
    end

    % Check if resulting string array contains: newline, tab or
    % carriage return
    specialCharacterPattern = string([char(9); char(13); newline]);
    specialCharacterIndex = contains(textDisplay, specialCharacterPattern);

    % If resulting text display contains special characters (e.g.
    % tab), replace them with their unicode character versions
    % using truncateLine
    if(any(specialCharacterIndex))
        textDispWithSpecialChars = textDisplay(specialCharacterIndex);
        for index = 1:numel(textDispWithSpecialChars)
            textDispWithSpecialChars(index) = matlab.internal.display.truncateLine(textDispWithSpecialChars(index), intmax);
        end
        textDisplay(specialCharacterIndex) = textDispWithSpecialChars;
    end
end

function validateStringMethodOutput(textDisplay, objArr)
methodName = "string";
if ~(isstring(textDisplay) || all(ismissing(textDisplay))) || ~isequal(size(textDisplay), size(objArr))
    error(message("MATLAB:display:StringMethodMustReturnStringOrMissing", methodName));
end
end

function validateMissingTextOutput(missingText)
methodName = "getMissingTextDisplay";
if ~isstring(missingText) || ~isscalar(missingText)
    error(message("MATLAB:display:MissingTextMustBeStringScalar", methodName));
end
end
