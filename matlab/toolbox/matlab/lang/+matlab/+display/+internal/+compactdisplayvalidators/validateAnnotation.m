function validateAnnotation(annotation, obj, displayConfiguration)
% Validate that annotation value based on display layout

% Copyright 2020 The MathWorks, Inc.
    import matlab.display.internal.DisplayLayout;
    if ~isempty(annotation) && ~all(ismissing(annotation)) && ...
            ~all(strlength(annotation) == 0)
        % Check shape constraints on annotation value only if it is not
        % empty or missing
        if displayConfiguration.DisplayLayout == DisplayLayout.SingleLine && ...
                ~isscalar(annotation)
            % For single line layouts, annotation value should be a scalar
            % string
            error(message('MATLAB:display:AnnotationMustBeScalar'));
        elseif displayConfiguration.DisplayLayout == DisplayLayout.Columnar && ...
                size(annotation,1) ~= size(obj,1)
            % For columnar layouts, the number of rows in the annotation
            % array should match the number of rows in the object
            objClassName = class(obj);
            error(message('MATLAB:display:AnnotationRowMismatch', objClassName));
        end
    end
end