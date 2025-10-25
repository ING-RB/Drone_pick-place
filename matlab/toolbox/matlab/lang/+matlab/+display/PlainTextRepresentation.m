classdef(Sealed) PlainTextRepresentation < matlab.display.CompactDisplayRepresentation
    % PlainTextRepresentation Plain-text representation of object data for 
    % compact display. Represent an object's compact display that shows all or a portion of 
    % the data contained in an object array.
    
    %   Copyright 2020-2024 The MathWorks, Inc.
    
    properties(SetAccess = immutable)
        %Representation - Text representation of the object data
        %   For single-line display, a scalar padded string represents the
        %   object data. For columnar display, each row represents the
        %   object data of the corresponding row in the object array.
        Representation (:,1) string;
    end
    
    methods
        function obj = PlainTextRepresentation(containedObj, dataRepresentation, displayConfiguration, optionalParams)
            arguments
                containedObj matlab.mixin.CustomCompactDisplayProvider
                dataRepresentation (:,1) string
                displayConfiguration (1,1) matlab.display.DisplayConfiguration
                optionalParams.Annotation (:,1) string {matlab.display.internal.compactdisplayvalidators.validateAnnotation(optionalParams.Annotation, containedObj, displayConfiguration)} = ""
                optionalParams.IsScalarObject (1,1) logical = isscalar(containedObj);
            end
            % Compact display helper functions
            import matlab.display.internal.getStringElements;
            import matlab.display.internal.getPaddedAnnotationValue;
            
            % Validate input dataRepresentation based on the display layout
            validateStringArrayShape(dataRepresentation, containedObj, displayConfiguration);
            % Replace empty or missing elements in dataRepresentation with 
            % string(missing)
            processedStringArray = getStringElements(dataRepresentation);
            if displayConfiguration.OmitDataDelimitersForScalars && optionalParams.IsScalarObject
                % Omit square delimiters for scalar objects if the consumer
                % requires it
                paddedDisplayOutput = processedStringArray;
            else
                % Append data delimiters
                paddedDisplayOutput = displayConfiguration.DataDelimiters(1) + processedStringArray + displayConfiguration.DataDelimiters(2);
            end
            % Compute padded annotation value
            [annotation, annotationWidth] = getPaddedAnnotationValue(optionalParams.Annotation, displayConfiguration);
            if all(annotationWidth > 0)
                % Append annotation value if it is not empty
                paddedDisplayOutput = paddedDisplayOutput + ...
                                        displayConfiguration.AnnotationPadding + ...
                                        annotation;
            end
            % Compute the character width for display string
            characterWidth = characterWidthForStringArray(displayConfiguration, paddedDisplayOutput);
            obj@matlab.display.CompactDisplayRepresentation(annotation, characterWidth, paddedDisplayOutput);
            obj.Representation = processedStringArray;
        end
    end
end

function validateStringArrayShape(stringArr, obj, displayConfiguration)
    import matlab.display.internal.compactdisplayvalidators.validateStringArray;
    import matlab.display.internal.DisplayLayout;

    % Validate input dataRepresentation based on the display layout
    validateStringArray(stringArr, obj, displayConfiguration);

    % For single line layouts, PlainTextRepresentation constructor requires
    % a scalar padded string array
    if displayConfiguration.DisplayLayout == DisplayLayout.SingleLine && ...
            ~isscalar(stringArr)
        error(message('MATLAB:display:StringArrayMustBeScalar'));
    end
end