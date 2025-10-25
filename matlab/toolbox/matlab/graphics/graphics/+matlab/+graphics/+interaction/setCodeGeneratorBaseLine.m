function setCodeGeneratorBaseLine(hObj)
% An API to establish the baseline for the Live Editor Code Generation mechanism

%   Copyright 2023 The MathWorks, Inc.
matlab.graphics.interaction.generateLiveCode(hObj, matlab.internal.editor.figure.ActionID.ESTABLISH_BASELINE);
end

