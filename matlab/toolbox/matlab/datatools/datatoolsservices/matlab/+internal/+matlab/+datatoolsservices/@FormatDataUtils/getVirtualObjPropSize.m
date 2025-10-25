% Returns the size of a Virtual property of an object.  Objects with virtual
% properties implement the
% internal.matlab.variableeditor.VariableEditorPropertyProvider, and have a
% method to return the size of the property.

% Copyright 2015-2023 The MathWorks, Inc.

function val = getVirtualObjPropSize(obj, propName)
    s = obj.getVariableEditorSize(propName);
    s = reshape(s', 1, []); % make sure we get a row vector g3553330

    val = regexprep(char(num2str(s)), ' +', ...
        internal.matlab.datatoolsservices.FormatDataUtils.TIMES_SYMBOL);
end
