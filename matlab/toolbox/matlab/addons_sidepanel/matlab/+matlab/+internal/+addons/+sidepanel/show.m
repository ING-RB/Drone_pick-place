function show(entryPointIdentifier, varargin)
% show Open Add-Ons Panel
%
%   1.  matlab.internal.addons.sidepanel.show(ENTRYPOINTIDENTIFIER)
%       opens Add-Ons Panel
%       
%       ENTRYPOINTIDENTIFIER is a unique id used to track the entry point
%       for Add-Ons Panel for usage data analytics
%
%       Example: Open Add-Ons Panel with default view
%
%       matlab.internal.addons.sidepanel.show("unique-id-for-udc")
%
%   2.  matlab.internal.addons.sidepanel.show(ENTRYPOINTIDENTIFIER, "view", VIEW)
%       Open Add-Ons Panel with default view
%       Supported values for VIEW: 'default', 'updates'
%
%       Example: Show Add-Ons Panel with updates view
%
%       matlab.internal.addons.sidepanel.show(ENTRYPOINTIDENTIFIER, "view", "updates")
%
%   See also: matlab.internal.addons.launchers.showExplorer

%   Copyright 2024 The MathWorks, Inc.

    narginchk(1,inf);

    inParser = inputParser;
    inParser.FunctionName = "show";
    inParser.CaseSensitive = false;
    inParser.PartialMatching = false;
    addRequired(inParser,"entryPointIdentifier", @(x)validateStringScalarInput("matlab.internal.addons.sidepanel.show", "entryPointIdentifier", x)); 

    % Add view as optional parameter
    parameterNameView = "view";
    addParameter(inParser, parameterNameView, string.empty, @(x) validateStringScalarInput("matlab.internal.addons.sidepanel.show", "view", x));
    
    parse(inParser, entryPointIdentifier, varargin{:});
    
    nameValuePairs = inParser.Results;

    navigateTo = struct();
    navigateTo.entryPoint = nameValuePairs.entryPointIdentifier;

    if (nargin == 0) 
        error(message('matlab_addons:errors:provideEntryPointIdentifier'));
    end

    if nargin > 1
        % parse name-value pairs
        
        if ~(isStringEmpty(nameValuePairs.view))
            navigateTo.view = nameValuePairs.view;
        end
    end
    
    matlab.internal.addons.Sidepanel.getInstance.show(navigateTo);
    bringDesktopToFront();

    % FUNCTIONS
    function validateStringScalarInput(functionName, paramName, paramValue)
    try
        narginchk(3, 3);
        validateattributes(paramValue, {'char','string'}, {'nonempty', 'scalartext'}, functionName, paramName)
    catch ME
        throwAsCaller(ME);
    end
    end

    function val = isStringEmpty(x)
        val = isempty(x) || (isstring(x) && length(x) == 1 && strlength(x)==0);
    end

    function bringDesktopToFront()
        rootApp = matlab.ui.container.internal.RootApp.getInstance();
        rootApp.bringToFront();
    end
end