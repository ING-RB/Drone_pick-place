function out = containedDisplay(data, width, optionalParams)
    % This function returns the contained representation of the input data,
    % in the specified width. The data can be any valid datatype in MATLAB.
    % It returns a string, which is a representation of the contained
    % display, for the given data. The returned string is non-empty only if
    % the data has a contained representation thet can be fit in the given
    % width
    %
    % In also takes in a set of optional Name-Value pairs that provide 
    % additional information for processing the data. These additional 
    % inputs are:
    %
    % 'Format': This specifies the numeric display format. It can be one of
    % these - +, bank, hex, long, longE, longEng, longG, rat short, shortE,
    % shortEng, shortG. The default is the current format.
    %
    % 'CommaDelimiter' - This is a boolean flag which represents the
    % delimiter added between row elements of the data. If it is true, we
    % add commas to delineate the elements in a row vector and we do not
    % add any padding spaces. If it is false, we add space to delineate the
    % elements in a row vector and we pad 4 of them. The defautl value is
    % false
    
    % Copyright 2017-2021 The MathWorks, Inc.
    arguments
        data
        width (1,1) double {mustBeReal, mustBeFinite, mustBeNonNan, mustBeNonnegative}
        optionalParams.CommaDelimiter (1,1) logical = false;
        optionalParams.Format (1,:) char {mustBeNonempty} = matlab.internal.display.format
    end
    
    out = matlab.internal.display.containedDisplayHelper(...
        data, width, optionalParams);
end