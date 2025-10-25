% Returns the value of a Virtual property of an object.  Objects with virtual
% properties implement the
% internal.matlab.variableeditor.VariableEditorPropertyProvider, and have a
% method to get its class name, as well as whether it is complex or sparse.

% Copyright 2015-2023 The MathWorks, Inc.

function val = getVirtualObjPropClass(obj, propName)
    import internal.matlab.datatoolsservices.FormatDataUtils;
    val = obj.getVariableEditorClassProp(propName);

    val = FormatDataUtils.addComplexSparseToClass(...
        val, ~obj.isVariableEditorComplexProp(propName), ...
        obj.isVariableEditorSparseProp(propName));
end
