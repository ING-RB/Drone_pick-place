function annotation = getDimensionsAndClassNameAnnotation(inputArr, options)
% Returns the dimensions and class name annotation of inputArr, including
% the padding the annotation requires. The user can specify the what
% padding they prefer to use, as well as if they are using regex (in which
% case the delimeters will have back-slashes)

% Copyright 2022 The MathWorks, Inc
arguments
    inputArr
    options.padding (1,:) {mustBeText} = " ";
    options.includeRegex (1,1) {mustBeNumericOrLogical} = false;
    options.excludeBrackets (1,1) {mustBeNumericOrLogical} = false;
end

openDelim = "";
closeDelim = "";
if ~options.excludeBrackets
    openDelim = "(";
    closeDelim = ")";
    if options.includeRegex
        openDelim = "\(";
        closeDelim = "\)";
    end
end

dimensions = matlab.internal.display.dimensionString(inputArr);
annotation = options.padding + openDelim + dimensions + " " + class(inputArr) + closeDelim;

end