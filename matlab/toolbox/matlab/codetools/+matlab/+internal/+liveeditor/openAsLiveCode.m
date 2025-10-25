function openAsLiveCode(plainCode)
% openAsLiveCode - Converts a string of plain MATLAB code to an unsaved 
% buffer in the Live Editor. Converts publishing markup to WYSIWYG. 
% Automatically indents the code according to the user's preferences. If 
% the Live Editor is not supported, defaults to opening the plain code.
%
%   Examples:
%
%       % Convert a file
%       sourceCode = fileread('myfunc.m');
%       matlab.internal.liveeditor.openAsLiveCode(sourceCode);
%
%       % Convert a character vector
%       sourceCode = ['%% A script' 10 'x = 123;'];
%       matlab.internal.liveeditor.openAsLiveCode(sourceCode);
%
%       % Convert a string
%       sourceCode = "x = 123" + char(10) + "y = 456";
%       matlab.internal.liveeditor.openAsLiveCode(sourceCode);
%
% See https://www.mathworks.com/help/matlab/matlab_prog/marking-up-matlab-comments-for-publishing.html
% for information on supported markup that will convert to rich text.

%   Copyright 2017-2021 The MathWorks, Inc.

assert(matlab.desktop.editor.isEditorAvailable, ...
        message('MATLAB:Editor:Document:NotAvailable'));

% Support strings
plainCode = convertStringsToChars(plainCode);

% Automatically indent the code
plainCode = indentcode(plainCode);

if matlab.desktop.editor.internal.useJavaScriptBackEnd
	data.source = plainCode;
	data.target = tempdir;
	data.sourceType = "content";
	data.writeToDisk = false;

	connector.ensureServiceOn;
	message.publish("/mlx/service/convertContentRequest_cpp", data);
    return;
end

% Check that Live Editor and live functions are enabled
if (com.mathworks.mde.liveeditor.LiveEditorApplication.isPlatformSupported)
    mf = com.mathworks.mlservices.MatlabDesktopServices.getDesktop().getMainFrame();
    com.mathworks.mde.liveeditor.LiveEditorApplication.getInstance().openAsLiveCode(mf, plainCode);
else
    % If not, open the plain code buffer
    matlab.desktop.editor.newDocument(plainCode);
end
