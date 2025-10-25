function newText = validateAnnotationText(text)
% Validates that the input is a row char, string scalar, or
% categorical scalar
%
% Same as validateText but also accepts categorical
%
% The guideline is to support categorical if the property is a
% form of annotation, text or label, where the user is likely
% to have a categorical array of values as input

if (iscategorical(text))
    text = string(text);
end

newText = matlab.ui.control.internal.model.PropertyHandling.validateText(text);
end