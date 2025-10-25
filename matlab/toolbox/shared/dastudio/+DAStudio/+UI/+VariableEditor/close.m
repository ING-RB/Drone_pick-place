function close(variableEditorObj)
    if isvalid(variableEditorObj) && ~isempty(variableEditorObj.Parent) && ~isempty(variableEditorObj.Parent.Parent)
        close(variableEditorObj.Parent.Parent);
    end
end