function modeKeyReleaseFcn(fig)
%   Copyright 2021-2023 The MathWorks, Inc.


import matlab.graphics.interaction.keyboardinteraction.generateLiveCode;
import matlab.graphics.interaction.keyboardinteraction.keyboardUndoRedoFcn;

generateLiveCode(fig);
keyboardUndoRedoFcn(fig);

end
