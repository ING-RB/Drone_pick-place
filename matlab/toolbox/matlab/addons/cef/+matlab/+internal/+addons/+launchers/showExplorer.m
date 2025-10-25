 function showExplorer(entryPointIdentifier, varargin)
% showExplorer Open Add-on Explorer
%
%   1. matlab.internal.addons.launchers.showExplorer(ENTRYPOINTIDENTIFIER)
%      opens Add-on Explorer to the default landing page
%
%      ENTRYPOINTIDENTIFIER is a unique id used to track the entry point
%      for Add-On Explorer for usage data analytics
%
%      Example: Open Add-on Explorer to default landing page
%
%      matlab.internal.addons.launchers.showExplorer("unique-id-for-udc")
%
%   2. matlab.internal.addons.launchers.showExplorer(ENTRYPOINTIDENTIFIER, "addOnType", ADDONTYPE)
%      opens Add-on Explorer with a filtered view for the specified ADDONTYPE 
%
%      ADDONTYPE can be any one of {"APPS", "HARDWARE_SUPPORT", "TOOLBOX",
%      "PRODUCT", "COLLECTION", "FUNCTION"}
%      
%      Example: Open Add-on Explorer to filtered view for apps
%      matlab.internal.addons.launchers.showExplorer("unique-id-for-udc", "addOnType", "HARDWARE_SUPPORT")
%
%   3. matlab.internal.addons.launchers.showExplorer(ENTRYPOINTIDENTIFIER, "identifier", IDENTIFIER)
%      opens detail page for the add-on specified by IDENTIFIER in Add-on Explorer 
%      
%      Example: Open detail page for Simulink in Add-on Explorer
%      matlab.internal.addons.launchers.showExplorer("unique-id-for-udc", "identifier", "SL")
%
%   4. matlab.internal.addons.launchers.showExplorer(ENTRYPOINTIDENTIFIER, "identifiers", IDENTIFIERS)
%      opens filtered view of add-ons specified by their IDENTIFIERS as an array in Add-on Explorer 
%      
%      Example: Open filtered view for Simulink and MATLAB in Add-on Explorer
%      matlab.internal.addons.launchers.showExplorer("unique-id-for-udc", "identifiers", ["SL", "ML"])
%
%   5. matlab.internal.addons.launchers.showExplorer(ENTRYPOINTIDENTIFIER, "dependencies", IDENTIFIERS)
%      opens filtered view of add-ons with dependencies on add-ons specified by their IDENTIFIERS as an array in Add-on Explorer 
%      
%      Example: Open filtered view Support Packages that has dependencies
%      on Simulink and MATLAB
%      matlab.internal.addons.launchers.showExplorer("unique-id-for-udc", "dependencies", ["SL", "ML"], "addOnType", "hardware_support")
%
%   6. matlab.internal.addons.launchers.showExplorer(ENTRYPOINTIDENTIFIER, "identifier", IDENTIFIER, "focused", FUNCTIONAME)
%      opens detail page of the add-on in Add-on Explorer with the provided function/block displayed in the documentation tab 
%      
%      Example: Open the detail page of Image Processing Toolbox with
%      function "plot" focused
%      matlab.internal.addons.launchers.showExplorer("unique-id-for-udc", "identifier", "IP", "focused", "plot")
%
%   7. matlab.internal.addons.launchers.showExplorer(ENTRYPOINTIDENTIFIER, "productFamily", PRODUCT_FAMILY)
%      opens filtered view of all add-ons that belong to a specific product family identified by  PRODUCT_FAMILY
%      
%      Example: Open filtered view of all add-ons that belong to product
%      faimly Simulink
%      matlab.internal.addons.launchers.showExplorer("unique-id-for-udc", "productFamily", "Simulink")
%
%   8. matlab.internal.addons.launchers.showExplorer(ENTRYPOINTIDENTIFIER, "source", SOURCE)
%      opens filtered view showing add-ons belonging to a specific source. For Example, community or mathworks
%
%      Example: Open filtered view of all community add-ons
%      matlab.internal.addons.launchers.showExplorer("unique-id-for-udc", "source", "community")
%
%   9. matlab.internal.addons.launchers.showExplorer(ENTRYPOINTIDENTIFIER, "keyword", KEYWORD)
%      opens a search result view with the list of add-ons matching a specific keyword
%      
%      Example: opens a search result view with the list of add-ons matching keyword 'GUI'
%      matlab.internal.addons.launchers.showExplorer("unique-id-for-udc", "keyword", "GUI")
%
%   10. matlab.internal.addons.launchers.showExplorer(ENTRYPOINTIDENTIFIER, "recommended", recommended)
%      opens a recommended view in Add Ons explorer
%
%      Example: opens a recommended view
%      matlab.internal.addons.launchers.showExplorer("unique-id-for-udc", "recommended", true)
%
%   See also: matlab.internal.addons.launchers.showManager

% Copyright 2019-2023 The MathWorks, Inc.

    narginchk(1,inf);

    inParser = inputParser;
    inParser.FunctionName = "showExplorer";
    inParser.PartialMatching = false;
    defaultValueEmpty = "";
    addRequired(inParser,"entryPointIdentifier", @(x)validateStringScalarInput("matlab.internal.addons.launchers.showExplorer", "entryPointIdentifier", x)); 
    
    % Add addOnType as an optional parameter
    parameterNameAddOnType = "addOnType";
    addOptional(inParser, parameterNameAddOnType, defaultValueEmpty, @(x) validateAddOnType(x));

    % Add recommended as an optional parameter
    parameterNameRecommended = "recommended";
    addOptional(inParser, parameterNameRecommended, defaultValueEmpty, @(x) validateRecommendedType(x));
    
    % Add identifier as optional parameter
    parameterNameIdentifier = "identifier";
    addOptional(inParser, parameterNameIdentifier, defaultValueEmpty, @(x)validateStringScalarInput("matlab.internal.addons.launchers.showExplorer", "identifier", x));
    
    % Add version as optional parameter
    parameterNameVersion = "version";
    addOptional(inParser, parameterNameVersion, defaultValueEmpty, @(x)validateStringScalarInput("matlab.internal.addons.launchers.showExplorer", "version", x));
    
    % Add identifiers as optional parameter
    parameterNameIdentifiers = "identifiers";
    addOptional(inParser, parameterNameIdentifiers, string.empty, @(x)validateIdentifierList(x));

    % Add dependencies as optional parameter
    parameterNameDependencies = "dependencies";
    addOptional(inParser, parameterNameDependencies, string.empty, @(x) validateDependenciesList(x));
    
    % Add focused as optional parameter
    parameterNameFocused = "focused";
    addOptional(inParser, parameterNameFocused, string.empty, @(x) validateStringScalarInput("matlab.internal.addons.launchers.showExplorer", "focused", x));
    
    % Add product-family as optional parameter
    parameterNameFocused = "productFamily";
    addOptional(inParser, parameterNameFocused, string.empty, @(x) validateStringScalarInput("matlab.internal.addons.launchers.showExplorer", "productFamily", x));
    
    % Add keyword as optional parameter
    parameterNameKeyword = "keyword";
    addOptional(inParser, parameterNameKeyword, string.empty, @(x) validateStringScalarInput("matlab.internal.addons.launchers.showExplorer", "keyword", x));

    % Add source as optional parameter
    parameterNameSource = "source";
    addOptional(inParser, parameterNameSource, string.empty, @(x) validateStringScalarInput("matlab.internal.addons.launchers.showExplorer", "source", x));

    parse(inParser, entryPointIdentifier, varargin{:});
    nameValuePairs = inParser.Results;
    
    connector.ensureServiceOn;

    navigationData = matlab.internal.addons.NavigationData;
    navigationData.entryPoint(nameValuePairs.entryPointIdentifier);
    
    if nargin > 1
        % parse name-value pairs
        
        if ~(isStringEmpty(nameValuePairs.identifier))
            navigationData.identifier(nameValuePairs.identifier);
        end
        
        if ~(isStringEmpty(nameValuePairs.version))
            navigationData.version(nameValuePairs.version);
        end
        
        if ~(isStringEmpty(nameValuePairs.focused))
            navigationData.focused(nameValuePairs.focused);
        end
        
        if ~(isStringEmpty(nameValuePairs.addOnType))
            navigationData.addOnType(nameValuePairs.addOnType);
        end
        

        if (islogical(nameValuePairs.recommended) && nameValuePairs.recommended)
            navigationData.recommended(nameValuePairs.recommended);
        end

        if ~(isStringEmpty(nameValuePairs.productFamily))
            navigationData.productFamily(nameValuePairs.productFamily);
        end
        
        if ~(isempty(nameValuePairs.identifiers))
            navigationData.identifiers(nameValuePairs.identifiers);
        end
        
        if ~isempty(nameValuePairs.dependencies)
            navigationData.dependencies(nameValuePairs.dependencies);
        end

        if ~isempty(nameValuePairs.keyword)
            navigationData.keyword(nameValuePairs.keyword);
        end

        if ~isempty(nameValuePairs.source)
            navigationData.source(nameValuePairs.source);
        end
        matlab.internal.addons.Explorer.getInstance.show(navigationData);
    
    else
        if matlab.internal.addons.Explorer.getInstance.windowExists
            matlab.internal.addons.Explorer.getInstance.bringToFront;
        else
            matlab.internal.addons.Explorer.getInstance.show(navigationData);
        end
    end
    
    function validateAddOnType(value)
        validateattributes(value,{'char', 'string'},{'scalartext'}, ...
            'matlab.internal.addons.launchers.showExplorer', 'ADDONTYPE')
        if ~any(strcmpi(["APPS", "HARDWARE_SUPPORT", "TOOLBOX", "PRODUCT", "COLLECTION", "FUNCTION"], value))
            error(message('matlab_addons:errors:invalidAddOnType', '{"APPS", "HARDWARE_SUPPORT", "TOOLBOX", "PRODUCT", "COLLECTION", "FUNCTION"}'));
        end
    end

    function validateRecommendedType(value)
        validateattributes(value,{'logical','cell'},{'nonempty'});
    end

    function validateIdentifierList(identifiers)
        if isscalar(identifiers)
            error(message('matlab_addons:errors:inputMustBeAnArray'));
        end
        validateattributes(identifiers,{'string','char','cell'},{'nonempty'});
        if ismember("", string(identifiers))
            error(message('matlab_addons:errors:identifiersListContainsEmptyString'));
        end
    end

    function validateDependenciesList(identifiers)
        if ~isscalar(identifiers)
            validateIdentifierList(identifiers);
        else
           validateattributes(identifiers,{'string','char'},{'nonempty'}); 
        end
    end
end