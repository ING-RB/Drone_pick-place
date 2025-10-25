classdef (Abstract) DocPageLauncher
    properties (Constant)
        DocPageNotifier = matlab.internal.doc.ui.DocPageNotifier;
    end

    properties (Access = protected)
        DocPage;
    end
    
    properties (Hidden, Access = protected)
        Handler (1,1);
    end
    
    properties (Dependent)
        Size
        Location
        Title
    end
    
    methods (Sealed)
        function success = openDocPage(obj)
            % Should DocPageLauncher have a property that can be used to
            % specify a location other than the default? We may not have
            % a use case for this yet.
            if isstring(obj.DocPage)
                success = showHtmlText(obj.Handler, obj.DocPage);
                obj.DocPageNotifier.htmlTextLaunched(obj.DocPage, success);
            else
                matlab.internal.doc.ui.DocPageLauncher.configureDocEnvironment;
                activePage = obj.DocPage.toActiveDocLocation;
                success = openBrowser(obj.Handler, getNavigationUrl(activePage));
                obj.DocPageNotifier.docPageLaunched(obj.DocPage, success);
            end
        end
    end

    methods (Access=protected)     
        function obj = DocPageLauncher(docPage)
            obj.DocPage = docPage;
            if isstring(obj.DocPage)
                obj.Handler = getHandlerForHtmlText(obj);
            else
                obj.Handler = getHandlerForDocPage(obj);
            end
        end
    end

    methods(Abstract)
        handler = getHandlerForDocPage(obj)
        handler = getHandlerForHtmlText(obj)
    end    
        
    methods (Static)
        function obj = getLauncherForDocPage(docPage)
            arguments
                docPage (1,1) matlab.internal.doc.url.DocPage
            end
            obj = matlab.internal.doc.ui.DocPageLauncher.getDocPageLauncher(docPage);

            propNames = string(fieldnames(docPage.DisplayOptions));
            for i = 1:length(propNames)
                propName = propNames(i);
                if isprop(obj.Handler, propName)
                    obj.Handler.(propName) = docPage.DisplayOptions.(propName);
                end
            end
        end

        function obj = getLauncherForHtmlText(htmlText)
            arguments
                htmlText (1,1) string = "";
            end
            obj = matlab.internal.doc.ui.DocPageLauncher.getDocPageLauncher(htmlText);
        end

        function l = addDocPageListener(listenerFcn)
            notifier = matlab.internal.doc.ui.DocPageLauncher.DocPageNotifier;
            l = listener(notifier, "DocPageLaunched", listenerFcn);
        end
    end

    methods
        function obj = set.Size(obj, size)
            if isprop(obj.Handler, "Size")
                obj.Handler.Size = size;
            end
        end
        
        function size = get.Size(obj)
            if isprop(obj.Handler, "Size")
                size = obj.Handler.Size;
            else
                size = [];
            end
        end

        function obj = set.Location(obj, location)
            if isprop(obj.Handler, "Location")
                obj.Handler.Location = location;
            end
        end
        
        function location = get.Location(obj)
            if isprop(obj.Handler, "Location")
                location = obj.Handler.Location;
            else
                location = [];
            end
        end
        
        function obj = set.Title(obj, title)
            if isprop(obj.Handler, "Title")
                obj.Handler.Title = title;
            end
        end
        
        function title = get.Title(obj)
            if isprop(obj.Handler, "Title")
                title = obj.Handler.Title;
            else
                title = "";
            end
        end
    end

    methods (Static, Access = private)
        function launcher = getDocPageLauncher(docPage)
            if matlab.internal.web.isMatlabMobile
                launcher = matlab.internal.doc.ui.MatlabMobileDocPageLauncher(docPage);
            elseif matlab.internal.web.isMatlabOnlineEnv
                launcher = matlab.internal.doc.ui.MatlabOnlineDocPageLauncher(docPage);
            else
                launcher = matlab.internal.doc.ui.DesktopDocPageLauncher(docPage);
            end
        end 

        function configureDocEnvironment
            if ~isempty(matlab.internal.doc.project.getCustomToolboxes) && matlab.internal.doc.ui.useSystemBrowser
                matlab.internal.doc.search.configureSearchServer;
            end
        end
    end
end

% Copyright 2021-2024 The MathWorks, Inc.
