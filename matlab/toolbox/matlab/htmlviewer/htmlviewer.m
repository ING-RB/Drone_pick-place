function viewerHandle = htmlviewer(input, options)
%HTMLVIEWER  Open a local HTML page in MATLAB
%   HTMLVIEWER(INPUT) opens the page specified by INPUT in the HTML Viewer
%   Editor. If the HTML Viewer is open already, the page displays in the
%   last active tab.
%
%   INPUT can be one of the following:
%       * A full or partial path to a local HTML file.
%       * HTML-formatted text using the 'text://' URL scheme. For example:
%            "text://<html><h1>Hello!</h1></html>".
%
%   HTMLVIEWER(INPUT, NEWTAB=true) displays the specified page in a new
%   HTML Viewer tab.
%
%   HTMLVIEWER(INPUT, SHOWTOOLBAR=false) displays the specified page
%   without showing the toolbar. If the HTML Viewer is already open, also
%   set the NEWTAB parameter to true. To display the specified page without
%   showing the toolbar when the HTML Viewer is already open, the NEWTAB
%   argument must also be set to TRUE.
%
%   V = HTMLVIEWER(...) returns a handle to the active HTML Viewer tab
%   specified as a matlab.htmlviewer.HTMLViewer object.
%
%   See also matlab.htmlviewer.HTMLViewer, WEB.

%   Copyright 2021-2024 The MathWorks, Inc.
    arguments
        input {mustBeTextScalar} = ""
        options.NewTab (1,1) logical {mustBeNumericOrLogical} = false
        options.ShowToolbar (1,1) logical {mustBeNumericOrLogical} = true
    end

    input = string(input);
    try
        if matlab.htmlviewer.internal.isHTMLViewer % If JSD, MO or if we force to use HTMLViewer using env flag
            viewer = matlab.htmlviewer.internal.HTMLViewerManager.getInstance().load(input, options);
            if nargout > 0
                % Called with at least one output argument. Assign the
                % viewer object to the output variable, viewerHandle.
                viewerHandle = viewer;
            end
        else
            productName = connector.internal.getProductNameByClientType;
            if isempty(productName)
                %  JAVA Desktop
                error(message('MATLAB:connector:Platform:FunctionNotSupported', 'htmlviewer'));
            else
                error(message('MATLAB:connector:Platform:FunctionNotSupportedForProduct','htmlviewer',productName));
            end
        end
    catch e
        throw(e)
    end
end