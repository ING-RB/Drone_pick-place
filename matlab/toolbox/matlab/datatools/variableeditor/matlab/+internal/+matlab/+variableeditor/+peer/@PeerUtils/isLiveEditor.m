% Returns true if the context is the Live Editor

% Copyright 2014-2024 The MathWorks, Inc.

function context = isLiveEditor(usercontext)
    context = ~isempty(usercontext) && (contains(usercontext, 'liveeditor') || ...
        contains(usercontext, 'VariableEditorContainerView') || contains(usercontext, 'commandwindow'));
end
