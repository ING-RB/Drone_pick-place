classdef(Sealed) DimensionsAndClassNameRepresentation < matlab.display.CompactDisplayRepresentation
    % DimensionsAndClassNameRepresentation Compact display representation
    % using the object array's dimensions and class name
    
    %   Copyright 2020-2024 The MathWorks, Inc.
    
    properties(SetAccess = immutable)
        %UseSimpleName - Set to true if the simple class name is used
        UseSimpleName = true;
    end
    
    properties(SetAccess = immutable, Hidden)
        ClassName (1,1) string
        DimensionsString (:,1) string
    end
    
    methods
        function obj = DimensionsAndClassNameRepresentation(containedObj, displayConfiguration, optionalParams)
            arguments
                containedObj matlab.mixin.CustomCompactDisplayProvider
                displayConfiguration (1,1) matlab.display.DisplayConfiguration
                optionalParams.UseSimpleName (1,1) logical = true
                optionalParams.Annotation (:,1) string {matlab.display.internal.compactdisplayvalidators.validateAnnotation(optionalParams.Annotation, containedObj, displayConfiguration)} = ""
                optionalParams.ClassName (1,1) string = class(containedObj)
            end
            import matlab.display.internal.getPaddedAnnotationValue;

            % Compute dimensions string
            dimstring = dimensionString(containedObj, displayConfiguration);         
            % Get full class name
            name = optionalParams.ClassName;
            if optionalParams.UseSimpleName
                % Use simple class name if UseSimpleName is set to true
                reg_expression = '[a-zA-Z_0-9]+\.';
                name = regexprep(name, reg_expression, '');
            end
            
            if(displayConfiguration.OmitDataDelimitersForDimensionsAndClassName)
                % Omit data delimiters
                paddedDisplayOutput = dimstring + displayConfiguration.PaddingBetweenDimensionsAndClassName + name;
            else
                % Construct dimensions and class name string
                % Include data delimiters araound dimensions and class name for
                % R2020b, as we currently use data delimiters around dimensions
                % and class name in struct display
                paddedDisplayOutput = displayConfiguration.DataDelimiters(1) + ...
                            dimstring + displayConfiguration.PaddingBetweenDimensionsAndClassName + name + ...
                            displayConfiguration.DataDelimiters(2);
            end
            
            % Compute padded annotation value
            [annotation, annotationWidth] = getPaddedAnnotationValue(optionalParams.Annotation, displayConfiguration);
            if all(annotationWidth > 0)
                % Append annotation value if it is not empty
                paddedDisplayOutput = paddedDisplayOutput + ...
                                        displayConfiguration.AnnotationPadding + ...
                                        annotation;
            end
            % Compute the character width
            characterWidth = characterWidthForStringArray(displayConfiguration, paddedDisplayOutput);
            obj@matlab.display.CompactDisplayRepresentation(annotation, characterWidth, paddedDisplayOutput);
            obj.UseSimpleName = optionalParams.UseSimpleName;
            obj.ClassName = name;
            obj.DimensionsString = dimstring;
        end
    end
end

function dimstring = dimensionString(obj, displayConfiguration)
% Compute the dimensions string based on the display layout
    arguments
        obj
        displayConfiguration (1,1) matlab.display.DisplayConfiguration
    end
    import matlab.display.internal.DisplayLayout;
    
    dimstring = matlab.internal.display.dimensionString(obj);
    sizeObj = size(obj);
    
    if (~isempty(obj) || sizeObj(1) > 1) && ~isrow(obj) && ...
            displayConfiguration.DisplayLayout == DisplayLayout.Columnar
        % If the object is not a row vector and the current layout is
        % 'Columnar', the dimensions string needs to be sliced per each of
        % the rows. For example, a 3x3 datetime array, would be displayed
        % as 1x3 datetime per each of the rows of the object.
        % The dimensions string also needs to be sliced for empty objects
        % that have multiple rows. For example, a 3x0 datetime array, is
        % displayed as 1x0 datetime on each row of the object
        rowSlicedSize = sizeObj;
        rowSlicedSize(1) = 1;
        rowSlicedObj = reshape(obj(1,:),rowSlicedSize); 
        dimstring = repmat(matlab.internal.display.dimensionString(rowSlicedObj), size(obj,1),1);
    end
end