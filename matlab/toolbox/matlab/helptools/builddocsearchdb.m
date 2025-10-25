function builddocsearchdb(helploc)
    %  BUILDDOCSEARCHDB Build documentation search database
    %    BUILDDOCSEARCHDB HELP_LOCATION builds a search database for MYTOOLBOX 
    %    documentation in HELP_LOCATION, which the Help browser uses to perform 
    %    searches that include the documentation for My Toolbox. Use 
    %    BUILDDOCSEARCHDB for My Toolbox HTML help files you add to the Help 
    %    browser via an INFO.XML file. BUILDDOCSEARCH creates a directory named
    %    HELPSEARCH in HELP_LOCATION. The HELPSEARCH directory works only with 
    %    the version of MATLAB used to create it.
    %
    %    Examples:
    %    builddocsearchdb([matlabroot '/toolbox/mytoolbox/help']) - builds the
    %    search database for the documentation found in the directory
    %    /toolbox/mytoolbox/help under the MATLAB root.
    %
    %    builddocsearchdb D:\Work\mytoolbox\help - builds the search database
    %    for the documentation files found at D:\Work\mytoolbox\help.

    %   Copyright 2006-2022 The MathWorks, Inc.

    helploc = sanitizeHelpLoc(helploc);    
    if (~exist(helploc,'file'))
        error('MATLAB:doc:CannotBuildSearchDb','%s',getString(message('MATLAB:doc:SpecifiedDirectoryDoesNotExist')));
    end

    if ~isHelpLocAvailable(helploc)
        error(message('MATLAB:doc:DocNotInstalled'));
    end
    success = matlab.internal.doc.project.customdocindexer.index(helploc);
    matlab.internal.doc.search.configureSearchServer(true);
    if ~success
        error('MATLAB:doc:CannotBuildSearchDb','%s',getString(message('MATLAB:doc:CouldNotWriteSearchDatabase')));
    end
    
    disp(getString(message('MATLAB:doc:CreatedSearchDatabase')));
end

% Handle the failure that if user try to build the doc 
% for a custom toolbox before the help system is notified that 
% the toolbox is on the path. 
function isDocInstalled = isHelpLocAvailable(helploc)
    isDocInstalled = 0;
    for counter = 1:10        
        if matlab.internal.doc.url.DocPageParser.isDocPage(helploc)
            isDocInstalled = 1;
            return;
        end
        pause(1);
    end
end

function helploc = sanitizeHelpLoc(helploc)
    % correct slashes
    helploc = fullfile(helploc);
    % remove trailing forward or back slash.
    helploc = erase(helploc,("\" | "/") + textBoundary('end'));
    % return char array
    if isstring(helploc)
        helploc = char(helploc);
    end
end

