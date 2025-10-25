function assertEditorAvailable (varargin)
%assertEditorAvailable Assert that the MATLAB Editor is available for a given environment.

% Copyright 2010-2024 The MathWorks, Inc.

    p = inputParser;
    addParameter(p, 'Visible', matlab.lang.OnOffSwitchState.on, @validateOnOffSwitchState);

    function validateOnOffSwitchState(val)
        matlab.lang.OnOffSwitchState(val);
    end

    p.KeepUnmatched = true;
    parse(p, varargin{:});

    isVisible = matlab.lang.OnOffSwitchState(p.Results.Visible);

    try
        isEditorAvailable = ~isVisible || matlab.desktop.editor.isEditorAvailable;
        assert(isEditorAvailable, message('MATLAB:Editor:Document:NotAvailable'));
    catch ex
        throwAsCaller(ex);
    end

end