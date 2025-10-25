function showExample(arg)
% 

%   Copyright 2017-2023 The MathWorks, Inc.

[docPage, source] = matlab.internal.examples.getExamplePageForId(arg);
if ~isempty(docPage)
    launcher = matlab.internal.doc.ui.DocPageLauncher.getLauncherForDocPage(docPage);
    launcher.openDocPage;
    return;
elseif ~isempty(source)
    error(message('MATLAB:showExample:NotFound',source));
end

error(message("MATLAB:examples:InvalidArgument", arg));
