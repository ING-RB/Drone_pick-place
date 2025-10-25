%

%   Copyright 2023 The MathWorks, Inc.
classdef FileType
    % matlab.desktop.editor.internal.FileType represent matlab lexical types
    % (i.e. class, function, script).
    % NOTE: This file types must be kept exactly same to lexical types defined in
    % file_analysis_service/Constant.js

    properties (Constant)
        CLASS_TYPE = 'class'
        FUNCTION_TYPE = 'function'
        SCRIPT_TYPE = 'script'
        UNKOWN_TYPE = 'unknown'
    end
end
