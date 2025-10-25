classdef InspectorRegistrationManager < handle
    % This class is unsupported and might change or be removed without
    % notice in a future version.

    % This class is the using during build time for managing the registration of
    % proxy views for the Property Inspector

    % Copyright 2018-2022 The MathWorks, Inc.

    properties
        ProxyViewMap = containers.Map; %#ok<*MCHDP>
        ProxyViewMapJSON = containers.Map;
        RenderedDataMap = containers.Map;
    end

    properties(Access = private)
        TempInspector
        getHelpSearchTerm
        Initialized logical = false
    end

    methods
        % Constructor, creates an InspectorRegistrationManager.  Initializes the
        % ProxyViewMap and ProxyViewMapJSON to empty Maps.
        function this = InspectorRegistrationManager()
        end

        function init(this)
            if ~this.Initialized
                % Create a temporary inspector for use internally, using a unique
                % channel name generated from the tempname filename
                [~, n, ~] = fileparts(tempname);
                provider = internal.matlab.variableeditor.peer.MF0ViewModelVEProvider(['/' n]);

                this.TempInspector = ...
                    internal.matlab.inspector.peer.PeerInspectorManager(n, provider);

                this.ProxyViewMap = containers.Map;
                this.ProxyViewMapJSON = containers.Map;
                this.RenderedDataMap = containers.Map;
                this.Initialized = true;
            end
        end

        % Called by an InspectorRegistrator class to register a class.
        % className - the class name to register
        % application - the application to register this with
        % propertySheet - the property sheet class name for the class
        % defaultObj - an instance of the class name being registered
        function registerInspectorView(this, className, application, propertySheet, defaultObj, helpSearchTerm)
            arguments
                this;
                className = 'default';
                application = 'default';
                propertySheet = [];
                defaultObj = [];
                helpSearchTerm = [];
            end

            this.init();
            this.getHelpSearchTerm = helpSearchTerm;

            if isempty(application)
                application = 'default';
            end
            disp("registerInspectorView, class: " +  className)

            if ~isKey(this.ProxyViewMap, application)
                this.ProxyViewMap(application) = containers.Map;
                this.ProxyViewMapJSON(application) = containers.Map;
                this.RenderedDataMap(application) = containers.Map;
            end

            % Get the class name maps
            map = this.ProxyViewMap(application);
            if isKey(map, className)
                return;
            end

            if isempty(propertySheet)
                % Get the class name maps
                map = this.ProxyViewMap(application);
                jsonMap = this.ProxyViewMapJSON(application);
                renderedDataMap = this.RenderedDataMap(application);

                % Update classname maps
                map(className) = [];
                jsonMap(className) = '';
                renderedDataMap(className) = '';

                % Store changes back
                this.ProxyViewMap(application) = map;
                this.ProxyViewMapJSON(application) = jsonMap;
                this.RenderedDataMap(application) = renderedDataMap;
                return;
            end

            if ~isa(propertySheet, 'internal.matlab.inspector.InspectorProxyMixin') &&...
                    ~ischar(propertySheet)
                %TODO: put this in the message catalog
                error('Property Sheet must extend internal.matlab.inspector.InspectorProxyMixin');
            end

            % If a default object is not passed in attempt to create an
            % instance of one of the passed in classes
            if isempty(defaultObj) && ...
                    ~isa(propertySheet, 'internal.matlab.inspector.InspectorProxyMixin')
                defaultObj = [];

                % try to create an instance of the class
                if ~strcmp(className, 'default')
                    try
                        defaultObj = eval([className '()']);
                        if ismember('matlab.graphics.Graphics', superclasses(className))
                            drawnow('nocallbacks');
                        end
                    catch
                    end
                end
            end

            % Try to create an instance of the proxy object
            [jsonData, proxyObject, renderedData] = this.getJSONDataForObject(...
                application, className, propertySheet, this.TempInspector, defaultObj);

            % Update the client mapping
            this.updateProxyClassMapping(className, application, class(proxyObject), jsonData, renderedData);
        end

        % Returns the JSON data for a given object.  This is done by inspecting
        % the object with the given propertySheet proxy view class, and getting
        % its rendered data.
        function [jsonData, proxyObject, renderedData] = getJSONDataForObject(this, application, className, propertySheet, TempInspector, defaultObj)
            s = struct('application', application, 'className', className);

            proxyObject = propertySheet;
            renderedData = '';
            if ~isa(propertySheet, 'internal.matlab.inspector.InspectorProxyMixin')
                proxyObject = eval([propertySheet '(defaultObj)']);

                if ~isa(proxyObject, 'internal.matlab.inspector.InspectorProxyMixin')
                    error('Property Sheet must extend internal.matlab.inspector.InspectorProxyMixin');
                end
            end
            
            if ~isempty(defaultObj)
                % Create a temporary inspector and get the rendered data for it.
                % Don't use a try/catch here -- we want errors to break the
                % build if they occur
                TempInspector.inspect(proxyObject);
                rows = TempInspector.Documents(1).ViewModel.getSize();
                rows = rows(1);

                % Delete the cached data.  It may will have been cached by the
                % inspect() call above.  This typically isn't a problem --
                % unless the help search term is different, which is being set
                % below.  This can change the tooltip, which wouldn't be picked
                % up if we use the cache data.
                remove(TempInspector.Documents.ViewModel.DataModel.getData.ObjRenderedData, ...
                    keys(TempInspector.Documents.ViewModel.DataModel.getData.ObjRenderedData));

                % Set the Help Search Term, and save it to the struct so it
                % makes it to the MAT file.
                helpSearchTerm = class(proxyObject.OriginalObjects);
                if ~isempty(this.getHelpSearchTerm)
                    TempInspector.Documents(1).ViewModel.getHelpSearchTerm = this.getHelpSearchTerm;
                    try
                        helpSearchTerm = this.getHelpSearchTerm(proxyObject.OriginalObjects);
                    catch
                    end
                end
                rd = TempInspector.Documents(1).ViewModel.getRenderedData(1,rows,1,1);
                s.defaults = strcat(rd{:});
                s.helpSearchTerm = char(helpSearchTerm);
                renderedData = rd;
            end
            jsonData = jsonencode(s);

            TempInspector.closeAllVariables();
        end

        function updateProxyClassMapping(this, className, application, proxyClass, proxyJSON, renderedData)
            arguments
                this
                className
                application
                proxyClass = [];
                proxyJSON = '';
                renderedData = '';
            end

            if ~isKey(this.ProxyViewMap, application)
                this.ProxyViewMap(application) = containers.Map;
                this.ProxyViewMapJSON(application) = containers.Map;
                this.RenderedDataMap(application) = containers.Map;
            end

            % Get the class name maps
            map = this.ProxyViewMap(application);
            jsonMap = this.ProxyViewMapJSON(application);
            renderedDataMap = this.RenderedDataMap(application);

            % Update classname maps
            map(className) = proxyClass;
            jsonMap(className) = proxyJSON;
            renderedDataMap(proxyClass) = renderedData;

            % Store changes back
            this.ProxyViewMap(application) = map;
            this.ProxyViewMapJSON(application) = jsonMap;
            this.RenderedDataMap(application) = renderedDataMap;
        end
    end
end