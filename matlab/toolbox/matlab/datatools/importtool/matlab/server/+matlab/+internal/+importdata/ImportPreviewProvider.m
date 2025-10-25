% This class is unsupported and might change or be removed without notice in a
% future version.

% This class is the base class for importing file types which provide a preview.
% It contains an abstract method, showPreview, which must be implemented.

% Copyright 2020-2024 The MathWorks, Inc.

classdef ImportPreviewProvider < matlab.internal.importdata.ImportProvider
    properties(Hidden)
        PreviewPanel
    end

    methods(Abstract)
        showPreview(this, parent, vars, pos);
        previewHidden(this);
    end

    methods
        function this = ImportPreviewProvider(filename)
            arguments
                filename (1,1) string = "";
            end
            
            this = this@matlab.internal.importdata.ImportProvider(filename);
        end

        function setTaskState(task, state)
            if isfield(state, "importDataCheckBox")
                task.ImportDataCheckBox.Value = state.importDataCheckBox;
            else
                task.ImportDataCheckBox.Value = true;
            end
        end
    end
end
