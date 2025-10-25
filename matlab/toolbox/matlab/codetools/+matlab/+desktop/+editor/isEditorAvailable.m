function result = isEditorAvailable
%matlab.desktop.editor.isEditorAvailable Return true if MATLAB Editor is available.
%   STATUS = matlab.desktop.editor.isEditorAvailable returns logical TRUE
%   if MATLAB is running with sufficient support for the MATLAB
%   Editor. To use functions in the matlab.desktop.editor package,
%   matlab.desktop.editor.isEditorAvailable must return TRUE.
%
%   Example: Check matlab.desktop.editor.isEditorAvailable before opening
%   an Editor Document.
%
%      if (matlab.desktop.editor.isEditorAvailable)
%          fftPath = which('fft.m');
%          matlab.desktop.editor.openDocument(fftPath);
%      end

%   Copyright 2010-2025 The MathWorks, Inc.

    result = matlab.ui.internal.hasDisplay && (usejava('swing') || matlab.desktop.editor.internal.useJavaScriptBackEnd);
end