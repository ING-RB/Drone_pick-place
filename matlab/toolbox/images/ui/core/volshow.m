function hVolume = volshow(varargin)
%

% Copyright 2018-2024 The MathWorks, Inc.

[parent, V, remainingInputs] = processParent(varargin{:});

if isempty(parent)
    % No parent provided
    fig = images.ui.graphics.internal.utilities.getPrewarmedFigure([]);
    viewer = images.ui.graphics.Viewer(fig);
    newViewer = true;
elseif isa(parent,'images.ui.graphics.Viewer')
    % Parent is an existing Viewer object
    viewer = parent;
    newViewer = false;
else
    error(message('imagesui:viewer:invalidViewer'));
end

viewer.Busy = true;

try
    if isa(V,'blockedImage')
        % blockedImage visualization should not be supported with MATLAB Online
        matlab.internal.capability.Capability.require(...
            matlab.internal.capability.Capability.LocalClient);
        obj = images.ui.graphics.BlockedVolume(viewer, remainingInputs{:}, 'Data', V);
    else
        obj = images.ui.graphics.Volume(viewer, remainingInputs{:}, 'Data', V);
        if ~feature('LiveEditorRunning')
            waitfor(viewer,'Busy',false);
        end
    end
catch ME
    if newViewer
        close(ancestor(viewer,'figure'));
    else
        viewer.Busy = false;
    end
    rethrow(ME);
end

if nargout > 0
    hVolume = obj;
end

end

function [parent, V, remainingInputs] = processParent(varargin)

V = [];

if ~isempty(varargin)

    if isnumeric(varargin{1}) || islogical(varargin{1}) || isa(varargin{1},'blockedImage')
        V = varargin{1};
        varargin(1) = [];
    end

end

[parent,remainingInputs] = images.ui.graphics.internal.utilities.processParent(varargin{:});

end
