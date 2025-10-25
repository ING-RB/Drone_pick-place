classdef CustomDocPage < matlab.internal.doc.url.DocContentPage
    methods
        function obj = CustomDocPage
            obj.IsValid = true;
            obj.SupportedLocations = "INSTALLED";
        end
    end

    methods (Access = protected)
        function url = buildNavigationUrl(obj)
            if matlab.internal.doc.ui.useSystemBrowser
                url = buildNavigationUrl@matlab.internal.doc.url.DocPage(obj);
                return;
            end
            
            if ~obj.IsValid
                url = matlab.net.URI;
                return;
            end

            % Build URL to 3pdoc.html page.
            url = obj.getDocRootUrl;             
            url.Path = [url.Path "customdoc" "3pdoc.html"];
        
            docRootUrl = obj.getDocRootUrl;
            docRootUrl.Query = [];

            relativePath = join(obj.RelativePath,"/");
            if ~strcmp(obj.Fragment, "")
                relativePath = strcat(relativePath, "#", obj.Fragment);
            end
            
            baseQuery = matlab.internal.doc.url.CustomDocPage.getBaseQuery(obj.Product.ContentType);
            queryForType = matlab.internal.doc.url.CustomDocPage.getQueryForType(obj.Product.ContentType, obj.Product.HelpLocation, docRootUrl, relativePath);
            queryForOtherType = [];
            if isfield(obj.Product,'OtherToolboxHelpLocation')
                queryForOtherType = matlab.internal.doc.url.CustomDocPage.getQueryForType(obj.Product.OtherToolboxHelpLocation.ContentType, obj.Product.OtherToolboxHelpLocation.HelpLocation, docRootUrl, obj.Product.OtherToolboxHelpLocation.LandingPage);
            end

            url.Query = [url.Query baseQuery queryForType queryForOtherType];
            url.Fragment = [url.Fragment obj.Fragment];
        end        
    end    

    methods (Static, Access = private)
        function query = getBaseQuery(contentType)
            query = [matlab.net.QueryParameter('pagetype',contentType)...
                     matlab.net.QueryParameter('pageexists',"true") ...
                     matlab.net.QueryParameter('3pdocurl',"true")];            
        end

        function queryForType = getQueryForType(contentType, helpLocation, docRootUrl, relativePath)
            switch contentType
               case 'doc'
                  queryForType = matlab.internal.doc.url.CustomDocPage.getDocQuery(helpLocation, docRootUrl, relativePath); 
               case 'example'
                  queryForType = matlab.internal.doc.url.CustomDocPage.getExampleQuery(helpLocation, docRootUrl, relativePath); 
               otherwise
                queryForType = [];
            end    
        end

        function query = getDocQuery(helpLocation, docRootUrl, relativePath)
            helpdir = matlab.internal.doc.url.CustomDocPage.getHelpLocation(helpLocation, docRootUrl); 
            query = [matlab.net.QueryParameter('helpdir',helpdir)...
                     matlab.net.QueryParameter('page',relativePath)];
        end
        
        function query = getExampleQuery(helpLocation, docRootUrl, relativePath)
            exampledir = matlab.internal.doc.url.CustomDocPage.getHelpLocation(helpLocation, docRootUrl);
            matlabResUrl = docRootUrl;
            matlabResUrl.Path = [matlabResUrl.Path '3ptoolbox'];
            query = [matlab.net.QueryParameter('exampledir',exampledir)...
                     matlab.net.QueryParameter('examplepage',relativePath)...
                     matlab.net.QueryParameter('productlink',getString(message('MATLAB:projectDoc:displayProjectDoc:productlink')))...
                     matlab.net.QueryParameter('mfile',getString(message('MATLAB:projectDoc:displayProjectDoc:mfile')))...
                     matlab.net.QueryParameter('mfiledesc',getString(message('MATLAB:projectDoc:displayProjectDoc:mfiledesc')))...
                     matlab.net.QueryParameter('model',getString(message('MATLAB:projectDoc:displayProjectDoc:model')))...
                     matlab.net.QueryParameter('modeldesc',getString(message('MATLAB:projectDoc:displayProjectDoc:modeldesc')))...
                     matlab.net.QueryParameter('video',getString(message('MATLAB:projectDoc:displayProjectDoc:video')))...
                     matlab.net.QueryParameter('videodesc',getString(message('MATLAB:projectDoc:displayProjectDoc:videodesc')))...
                     matlab.net.QueryParameter('mgui',getString(message('MATLAB:projectDoc:displayProjectDoc:mgui')))...
                     matlab.net.QueryParameter('mguidesc',getString(message('MATLAB:projectDoc:displayProjectDoc:mguidesc')))...
                     matlab.net.QueryParameter('uses',getString(message('MATLAB:projectDoc:displayProjectDoc:uses')))...  
                     matlab.net.QueryParameter('languageDir','')...  
                     matlab.net.QueryParameter('matlabroot',matlabroot)...  
                     matlab.net.QueryParameter('docroot',docroot)...  
                     matlab.net.QueryParameter('matlabres',matlabResUrl.string)];
        end

        function helpdir = getHelpLocation(helpLocation, docRootUrl)
            % Get the (absolute) path to the custom doc help location.
            helpDirUrl = docRootUrl;
            helpLocPath = split(helpLocation,"/");
            helpLocPath = helpLocPath';
            helpDirUrl.Path = horzcat(helpDirUrl.Path,helpLocPath);
            helpdir = string(helpDirUrl);
        end    
    end
end

% Copyright 2021-2024 The MathWorks, Inc.