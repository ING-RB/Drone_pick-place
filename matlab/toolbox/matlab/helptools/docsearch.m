function docsearch(varargin)
%DOCSEARCH Help browser search.
%
%   DOCSEARCH opens the Help browser and displays the documentation home
%   page. If the Help browser is already open, but not visible, then
%   docsearch brings it to the foreground.
%
%   DOCSEARCH TEXT searches the documentation for pages with words that match 
%   the specified expression. To search third-party or custom documentation, 
%   you must first run the BUILDDOCSEARCHDB command to build a search database  
%   for the additional help files.
%
%   Examples:
%      docsearch plot
%      docsearch plot tools
%      docsearch('plot tools')
%
%   See also DOC.

%   Copyright 1984-2024 The MathWorks, Inc.

if nargin > 1
    text = deblank(sprintf('%s ', varargin{:}));    
elseif nargin == 1
    text = char(varargin{1});
else
    text = '';
end

docPage = matlab.internal.doc.url.DocSearchPage(text);    
launcher = matlab.internal.doc.ui.DocPageLauncher.getLauncherForDocPage(docPage);
launcher.openDocPage();
