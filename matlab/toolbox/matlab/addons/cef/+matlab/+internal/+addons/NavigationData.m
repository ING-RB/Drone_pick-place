classdef (Sealed = true, Hidden = true) NavigationData < handle
    %   NavigationData: Navigation data to be sent to Add-on Manager/Explorer
    %   Copyright: 2019-2023 The MathWorks, Inc.

%   Copyright 2019-2023 The MathWorks, Inc.

    properties (Access = private)
        
        navigationDataBody
    
    end
    
    methods (Access = public)
        
        function obj = NavigationData()
            obj.navigationDataBody = struct;
        end
        
        function  this = showTab(this, tabName)
            this.navigationDataBody.showTab = tabName;
        end
        
        function  this = entryPoint(this, entryPointIdentifier)
            this.navigationDataBody.entryPoint = entryPointIdentifier;
        end
        
        function this = loadApplicationUrl(this, applicationUrl)
            this.navigationDataBody.loadApplicationUrl = applicationUrl;
        end
        
        function this = identifier(this, id)
            this.navigationDataBody.identifier = id;
        end
        
        function this = identifiers(this, ids)
            if isscalar(string(ids))
                ids = {ids};
            end
            this.navigationDataBody.identifiers = ids;
        end
        
        % ToDo: Work with FX team to update the name of the field to
        % dependencies to make it generic
        function this = dependencies(this, identifiers)
             if isscalar(string(identifiers))
                 identifiers = {identifiers};
             end
            this.navigationDataBody.baseProducts = identifiers;
        end
        
        function this = version(this, addOnVersion)
            this.navigationDataBody.version = addOnVersion;
        end
        
        function this = name(this, addOnName)
            this.navigationDataBody.addOnName = addOnName;
        end
        
        function this = showDialog(this, dialogType)
            this.navigationDataBody.showDialog = dialogType;
        end
        
        function this = focused(this, functionName)
            this.navigationDataBody.focused = functionName;
        end
        
        function this = addOnType(this, addOnType)
            this.navigationDataBody.addOnType = addOnType;
        end

        function this = recommended(this, recommended)
            this.navigationDataBody.recommended = recommended;
        end
        
        function this = productFamily(this, productFamily)
            this.navigationDataBody.productFamily = lower(productFamily);
        end

        function this = source(this, source)
            this.navigationDataBody.source = source;
        end

        function this = keyword(this, keyword)
            this.navigationDataBody.keyword = keyword;
        end
        
        function navigationDataAsJson = getNavigationDataAsJson(this)
            navigationDataAsJson = jsonencode(this.navigationDataBody);
        end
        
        function navigationDataAsString = getNavigationDataAsString(this)
            navigationDataAsString = string(jsonencode(this.navigationDataBody));
        end

        function result = getNavigationDataBody(this)
            result = this.navigationDataBody;
        end
    end
end
