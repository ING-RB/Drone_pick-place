function opendocid(currentEx,docId)
% This function can be used for resolving the "docid:"
% links in examples:
% When a user clicks on a "docid:" link in the Editor, it
% opens the target doc page.

% Input arguments:
% (1) currentEx: the current example's file location, 
% like /MATLAB Drive/Examples/R2022a/matlab/intro/intro.mlx
% or
% C:\Users\username\Documents\MATLAB\Examples\R2022a\matlab\intro\intro.mlx 
% or
% /MATLAB Drive/Examples/R2022a/matlab/intro
%
% This is always the location the file is opened from, when openExample is used.
%
% (2) docID: the string next to "docid:" in the link inside the current example

%   Copyright 2021-2023 The MathWorks, Inc.

arguments
    currentEx {mustBeTextScalar,mustBeNonzeroLengthText}
    docId {mustBeTextScalar,mustBeNonzeroLengthText}
end

[exFilePath,exName,ext] = fileparts(currentEx);

if isempty(exName)
    error(message("MATLAB:examples:InvalidArgument", currentEx));
end

strArray = split(exFilePath, filesep);
if (ext == "")
    % The file name is not included at the end; so in exFilePath, the
    % string *after* the last filesep is the example component name.
    exComponent = strArray(end);
else
    % The file name is included at the end; so in exFilePath, the
    % string *before* the last filesep is the example component name.
    exComponent = strArray(end-1);
end
exampleId = exComponent + "-" + exName;

% Get example data, including its docid links.
exampleData = matlab.internal.example.api.FindExampleData(exampleId);
if isempty(exampleData)
    error(message('MATLAB:opendocid:unknownExample', currentEx));
end

% An example can occur on multiple doc pages in multiple products.
% The link target is the same, so take first exampleData item.
exampleData = exampleData(1);
docidLinks = exampleData.DocIDLinks;
docids = string([docidLinks.DocID]);

docidToFind = replace(docId,".","#"); % Normalize separator.
% Get target of docid link that matches docidToFind. Target is the
% same if there are multiple matches, so take the first one.
matchIdx = find(docids == docidToFind,1,'first');
if isempty(matchIdx)
    error(message('MATLAB:opendocid:unknownId', docId));
end

% Display the doc page.
docPage = matlab.internal.doc.url.MwDocPage;
docPage.Product = exampleData.HelpLocation;
docPage.RelativePath = docidLinks(matchIdx).Target;
launcher = matlab.internal.doc.ui.DocPageLauncher.getLauncherForDocPage(docPage);
launcher.openDocPage;

end
