classdef(Sealed) DisplayConfiguration
% DisplayConfiguration  Describes the display environment and settings
%   DisplayConfiguration provides environmental information required to build
%   an object's compact display.
%   
%   When an object is being displayed in a limited amount of space, such as 
%   when the object is held within a struct or cell array, MATLAB provides 
%   a DisplayConfiguration object to represent the current display environment.
%   The container (for example, struct or cell array) can modify some of the 
%   configuration properties before passing it to the object's implementations
%   of the CustomCompactDisplayProvider methods.
%   
%   DisplayConfiguration properties:
%       Ellipsis                                        - Ellipsis character for 
%                                                         displaying a portion
%                                                         of the data
%       AnnotationDelimiters                            - Delimiters used to wrap 
%                                                         the annotation
%       AnnotationPadding                               - Padding used to separate 
%                                                         the annotation from the 
%                                                         data
%       DefaultPadSize                                  - Default number of spaces 
%                                                         in between elements of
%                                                         the object
%       DefaultPaddingSizeBetweenDimensionsAndClassName - Default number of spaces
%                                                         in between dimensions 
%                                                         and class name
%       InterElementDelimiter                           - Inter-element delimiter 
%                                                         between elements of the 
%                                                         display string
%       PaddingBetweenDimensionsAndClassName            - Padding in between 
%                                                         dimensions and class
%                                                         name
%   DisplayConfiguration methods:
%       characterWidthForStringArray - Returns the character width of the input 
%                                      string
% 
%   See also matlab.mixin.CustomCompactDisplayProvider, 
%   matlab.display.CompactDisplayRepresentation
%

%   Copyright 2020-2021 The MathWorks, Inc. 

    properties
        %Ellipsis - Ellipsis character for displaying a portion of the data
        Ellipsis = getEllipsis();
    end
    properties(Constant)
        %AnnotationDelimiters - Delimiters used to wrap the annotation
        AnnotationDelimiters = ["(",")"];
        %AnnotationPadding - Padding used to separate the annotation from
        %the data
        AnnotationPadding = " ";

        %DefaultPadSize - Default number of spaces in between elements of 
        % the object
        DefaultPadSize = 4
        %DefaultPaddingSizeBetweenDimensionsAndClassName - Default number of 
        % spaces in between dimensions and class name
        DefaultPaddingSizeBetweenDimensionsAndClassName = 1
        %InterElementDelimiter - Inter-element delimiter between elements 
        % of the display string
        InterElementDelimiter  = string(repmat(' ', 1, matlab.display.DisplayConfiguration.DefaultPadSize))
        %PaddingBetweenDimensionsAndClassName - Padding in between
        % dimensions and class name
        PaddingBetweenDimensionsAndClassName = string(repmat(' ',1,matlab.display.DisplayConfiguration.DefaultPaddingSizeBetweenDimensionsAndClassName));
    end
    properties(Hidden)
        OmitDataDelimitersForDimensionsAndClassName = false;
        OmitDataDelimitersForScalars = false;
        DisplayLayout (1,1) matlab.display.internal.DisplayLayout = 'SingleLine'
        DataDelimiters (1,2) string = ["[", "]"];
    end
    properties(Dependent, Hidden)
        NumericDisplayFormat
        NewlineCharacter
        HyperlinksEnabled
    end
    
    methods
        function obj = DisplayConfiguration(displayLayout)
            arguments
                displayLayout (1,1) matlab.display.internal.DisplayLayout = 'SingleLine';
            end
            obj.DisplayLayout = displayLayout;
        end
        
        function value = get.NumericDisplayFormat(obj)
            value = matlab.internal.display.format;
        end
        
        function value = get.NewlineCharacter(obj)
            value = matlab.internal.display.getNewlineCharacter(newline);
        end
        
        function value = get.HyperlinksEnabled(obj)
            value = matlab.internal.display.isHot;
        end
        
        function width = characterWidthForStringArray(displayConfiguration, stringArray)
        % characterWidthForStringArray returns the character width of the 
        % input string
        %   width = characterWidthForStringArray(displayConfiguration, stringArray)
        %   determines the character width of the input string, stringArray.
        %   
        %   It returns a double array that matches the dimensions of
        %   the input stringArray.
        arguments
            displayConfiguration matlab.display.DisplayConfiguration
            stringArray string {mustBeMatrix(stringArray)}
        end
            numberOfRows = size(stringArray, 1);
            numberOfColumns = size(stringArray, 2);
            width = zeros(numberOfRows, numberOfColumns);
            for row = 1:numberOfRows
                for column = 1:numberOfColumns
                    width(row, column) = matlab.internal.display.wrappedLength(stringArray(row, column));
                end
            end
        end
    end
end

%Set the initial value of the continuation character
function el = getEllipsis
    if matlab.internal.display.isDesktopInUse
        % Unicode ellipsis character
        el = string(char(8230));
    else
        el = "...";
    end
end

function mustBeMatrix(stringArr)
    if ~ismatrix(stringArr)
        error(message('MATLAB:display:InvalidStringArrayDimensions'));
    end
end