function arg = modifyShape(arg)

% assign corresponding string values to shape
if(numel(arg.Shape) == 1)
    if(iscell(arg.Shape))
        arg.Shape = arg.Shape{1};
    end
    if isa(arg.Shape,"internal.mwAnnotation.ShapeKind")
        switch(arg.Shape)
            case internal.mwAnnotation.ShapeKind.Array
                arg.Shape = "array";
            case internal.mwAnnotation.ShapeKind.NullTerminated
                arg.Shape = "nullTerminated";
            case internal.mwAnnotation.ShapeKind.Scalar
                arg.Shape = 1;
            case internal.mwAnnotation.ShapeKind.Undefined
                arg.Shape = "undefined";
        end
    end
end
% Modifies shape to "scalar" for all storage types when shape is literal "1"
% when storage is pointer or array shape should be "array" except
% when shape is 'nullTerminated' text

if numel(arg.Shape) == 1 && ((isnumeric(arg.Shape) && arg.Shape == 1) || ...
        (iscell(arg.Shape) && isnumeric(arg.Shape{1}) && arg.Shape{1} == 1))
    % need clarification
    if (arg.Storage == "array" || ...
       (arg.Storage == "pointer" && startsWith(arg.MATLABType(1), "clib.array.")))
        arg.Shape = "array";
    else
        arg.Shape = "scalar";
    end
elseif arg.Storage == "array" || arg.Storage == "pointer"
    if (ischar(arg.Shape) && strcmp(arg.Shape, 'nullTerminated')) || ...
            (numel(arg.Shape) == 1 && ...
            (isstring(arg.Shape) && strcmp(arg.Shape, "nullTerminated")) || ...
            (iscell(arg.Shape) && strcmp(arg.Shape{1}, "nullTerminated")))
        arg.Shape = "nullTerminated";
    else
        arg.Shape = "array";
    end
end
end