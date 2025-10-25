function [annotation, annotationWidth] = getPaddedAnnotationValue(annotation, displayConfig)
% getPaddedAnnotationValue Compute padded annotation value
%   Append annotation delimiters and padding to annotation column vector and
%   align all values using padding so that all rows have the same width. If
%   the input annotation is empty or all elements are zero length strings,
%   this function returns scalar zero length string and sets the
%   annotationWidth to zero
%   
%   Copyright 2021 The MathWorks, Inc
    import matlab.display.internal.DisplayLayout;
    if ~isempty(annotation) && ~all(ismissing(annotation)) && ...
            ~all(strlength(annotation) == 0)
        if displayConfig.DisplayLayout == DisplayLayout.SingleLine
            % Append annotation if it is not set to empty
            annotation = displayConfig.AnnotationDelimiters(1) + annotation + ...
                displayConfig.AnnotationDelimiters(2);
            % Annotation width includes annotation delimiters
            annotationWidth = characterWidthForStringArray(displayConfig, annotation);
        elseif displayConfig.DisplayLayout == DisplayLayout.Columnar
            % Append annotation delimiters to values that are not missing
            % or mepty
            indices = ~ismissing(annotation) & strlength(annotation) > 0;
            annotation(indices) = displayConfig.AnnotationDelimiters(1) + annotation(indices) + ...
                displayConfig.AnnotationDelimiters(2);
            % Include additional padding to align annotation values in all
            % rows
            annotation = alignAnnotationValues(annotation, displayConfig);
            annotationWidth = characterWidthForStringArray(displayConfig, annotation);
        end
    else
        annotation = "";
        annotationWidth = 0;
    end
end

function annotation = alignAnnotationValues(annotation, displayConfig)
% Align input annotation array

    % Replace missing elements with ""
    missingElemIndices = ismissing(annotation);
    annotation(missingElemIndices) = "";
    
    % Compute width of each row in the annotation array
    annotationWidth = characterWidthForStringArray(displayConfig, annotation);
    % Find the widest annotation value
    maxAnnotationWidth = max(annotationWidth);
    
    for i = 1:numel(annotation)
        % Append spaces at the end of the annotation based on the widest
        % annotation value
        annotation(i) = annotation(i) + repmat(' ', 1, (maxAnnotationWidth - annotationWidth(i)));
    end
end