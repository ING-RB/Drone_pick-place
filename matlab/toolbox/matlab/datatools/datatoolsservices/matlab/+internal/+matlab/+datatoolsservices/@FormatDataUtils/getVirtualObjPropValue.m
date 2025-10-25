% Returns the value of a Virtual property of an object.  Objects with virtual
% properties implement the
% internal.matlab.variableeditor.VariableEditorPropertyProvider, and have a
% method to get its class size.  The virtual properties always display as "NxM
% datatype".

% Copyright 2015-2023 The MathWorks, Inc.

function val = getVirtualObjPropValue(obj, propName)
    import internal.matlab.datatoolsservices.FormatDataUtils;
    val = [FormatDataUtils.getVirtualObjPropSize(obj, propName) ...
        ' ' obj.getVariableEditorClassProp(propName)];
end
