function setupForHelpUI
%MATLAB.INTERNAL.DOC.UI.SETUPFORHELPUI Perform setup required before
%   launching a help UI.

%   Copyright 2021 The MathWorks, Inc.

persistent isInitalized;

if isempty(isInitalized)
    matlab.internal.doc.ui.java.initializeHelpSystem;
    isInitalized = true;
end

end