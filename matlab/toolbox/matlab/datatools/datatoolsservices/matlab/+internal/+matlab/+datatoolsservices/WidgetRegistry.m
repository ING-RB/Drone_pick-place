classdef WidgetRegistry < handle
%WIDGETREGISTRY Web Widget Registration
%

% Copyright 2013-2023 The MathWorks, Inc.

% Property Definitions:

    properties (Constant)
        UnknownView = 'variableeditor/views/UnknownView';
        SearchPaths = ["internal.matlab.datatoolsservices.widgetregistry",...
                       "datatoolsservices.internal.widgetregistry"];
    end

    % Map
    properties (SetObservable=true, SetAccess='protected', GetAccess='public', Dependent=false, Hidden=false)
        % Map Property
        Map;
    end %properties

    properties (Access=private)
        SearchMap;
    end

    methods(Access='private')
        function this = WidgetRegistry
        % private constructor
        end

        function [keyset, valueset] = loadRegistrator(this, registratorClass)
            try
                instance = eval(registratorClass);
                filePath = instance.getWidgetRegistrationFile();
                mapping = this.getDefaultsFromFile(filePath);
                keyset = repmat(string.empty,1,length(mapping));
                valueset = cell(1,length(mapping));
                index = 0;
                for i=1:length(mapping)
                    default = mapping(i);
                    if iscell(mapping)
                        default = mapping{i};
                    end

                    keys = this.getDefaultValueFromStruct(default, 'Keyset');
                    container = this.getDefaultValueFromStruct(keys, 'Container');
                    datatype = this.getDefaultValueFromStruct(keys, 'Datatype');
                    context = this.getDefaultValueFromStruct(keys, 'Context');
                    dataAttributes = this.getDefaultValueFromStruct(keys, 'DataAttributes');

                    vals = this.getDefaultValueFromStruct(default, 'Valueset');

                    key = internal.matlab.datatoolsservices.WidgetRegistry.createKey(container, datatype, context, dataAttributes);
                    for j=1:length(key)
                        index = index+1;
                        if any(strcmp(keyset,key(j)))
                            warning('Key already exists, previous value will be overriden: %s', key(j));
                        end
                        keyset(index) = key(j);
                        valueset{index} = vals;
                    end
                end
            catch registrationException
                internal.matlab.datatoolsservices.logDebug("datatoolsservices::widgetregistry", registrationException.message);
            end
        end

        function createWidgetRegistryMap(this)
            import internal.matlab.datatoolsservices.WidgetRegistry;

            keyset = string.empty;
            valueset = cell.empty;

            for idx = 1:length(WidgetRegistry.SearchPaths)
                try
                    % Get all registrators for this search path
                    regisratorMetaClasses = internal.findSubClasses(char(WidgetRegistry.SearchPaths(idx)), ...
                                                                    'internal.matlab.datatoolsservices.WidgetRegistrator', true);

                    % Because multiple registrators may be found in the
                    % same package (but in different directories), need to
                    % loop over them individually
                    for jdx = 1:length(regisratorMetaClasses)
                        [ks, vs] = this.loadRegistrator(regisratorMetaClasses{jdx}.Name);
                        keyset = [keyset ks]; %#ok<AGROW>
                        valueset = [valueset vs]; %#ok<AGROW>
                    end
                catch registrationException
                    if ~strcmp(registrationException.identifier,...
                               'testmeaslib:findSubClasses:unknownNamespace')
                        internal.matlab.datatoolsservices.logDebug("datatoolsservices::widgetregistry", registrationException.message);
                    end
                end
            end

            if ~isempty(keyset) && ~isempty(valueset)
                this.Map = dictionary(string.empty, struct.empty);
                for k = 1:length(keyset)
                    key = keyset{k};
                    value = valueset{k};
                    this.Map(key) = value;
                end
                this.SearchMap = dictionary(string.empty, struct.empty);
            end
        end

        function val = getDefaultValueFromStruct(~, s, field)
            val = "";
            if ~isempty(s) && isstruct(s) && isfield(s, field)
                val = s.(field);
            end
        end

        function defaults = getDefaultsFromFile(~, filepath)
            A = fileread(filepath);
            defaults = jsondecode(A);
        end

        function addSearchMatch(this, searchKey, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes)
            previousMatch = struct;
            previousMatch.widgets = widgets;
            previousMatch.matchedPeerClass = matchedPeerClass;
            previousMatch.matchedVariableClass= matchedVariableClass;
            previousMatch.matchedContext = matchedContext;
            previousMatch.matchedDataAttributes = matchedDataAttributes;

            this.SearchMap(searchKey) = previousMatch;
        end
    end

    % Public Methods
    methods(Static, Access='public')
        % getInstance
        function obj = getInstance(forceUpdate)
            arguments
                forceUpdate (1,1) logical = false
            end
            persistent managerInstance;
            mlock;
            if isempty(managerInstance) || forceUpdate
                managerInstance = internal.matlab.datatoolsservices.WidgetRegistry;
                managerInstance.createWidgetRegistryMap();
            end
            obj = managerInstance;

        end

        % get DataAttributes returns the apprrpriate data attributes for
        % provided data/metaData from the dataAttributesProvider.
        function [dataAttributes, validAttributes] = getDataAttributes(varargin)
            dataAttributesProvider = internal.matlab.datatoolsservices.DefaultDataAttributesProvider.getInstance();
            dataAttributes = dataAttributesProvider.getDataAttributes(varargin{:});
            fields = fieldnames(dataAttributes);
            validAttributes = string.empty;
            for i=1:numel(fields)
                if (dataAttributes.(fields{i}))
                    validAttributes(end+1) = string(fields{i});
                end
            end
            validAttributes = sort(validAttributes);
        end

        % createKey
        function key=createKey(peerClass,variableClass,context,dataAttributes)
            if nargin < 1 || isempty(peerClass)
                peerClass = "";
            end
            peerClass = string(peerClass);
            if nargin < 2 || isempty(variableClass)
                variableClass = "";
            end
            variableClass = string(variableClass);
            if nargin < 3 || isempty(context)
                context = "";
            end
            if nargin < 4 || isempty(dataAttributes)
                dataAttributes = "";
            end

            context = string(context);
            sizeP = size(peerClass, 1);
            sizeV = size(variableClass, 1);
            sizeC = size(context, 1);
            sizeD = size(dataAttributes, 1);
            totalSize = sizeP*sizeV*sizeC*sizeD;
            if totalSize > 1
                key = repmat(string.empty, 1, totalSize);
                index = 0;
                for p=1:sizeP
                    for v=1:sizeV
                        for c=1:sizeC
                            for d=1:sizeD
                                index = index+1;
                                key(index) = char(peerClass(p) + "/" + variableClass(v) + "/" + context(c) + "/" + dataAttributes(d));
                            end
                        end
                    end
                end
            else
                key = "";
                key(1) = char(peerClass(1) + "/" + variableClass(1) + "/" + context(1) + "/" + dataAttributes(1));
            end
        end

        % createWidgetStruct
        function s=createWidgetStruct(editor,inPlaceEditor,cellRenderer,editorConverter)
            if nargin<4
                editorConverter = '';
            end
            s=struct('Editor',editor,'InPlaceEditor',inPlaceEditor,'CellRenderer',cellRenderer,'EditorConverter',editorConverter);
        end
    end

    % Public Methods
    methods(Access='public')

        % getWidgets
        function [widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes] = ...
                getWidgets(this, peerClass, variableClass, context, dataAttributes, doGenericObjectCheck)
            arguments
                this
                peerClass
                variableClass
                context = ""
                dataAttributes = ""
                doGenericObjectCheck (1,1) logical = false
            end

        % The logic for getWidgets prioritizes lookups on the variable
        % class over the peer class.  Here is the strategy of the
        % lookups:
        %
        % 1. Exact match for peerClass and variableClass
        % 2. peerClass exact match, match superclass for variableClass
        % 3. Match superclass for peerClass, variable class exact match
        % 4. Match superclass for peerClass, superclass variableClass
        % 5. Match empty peerClass, variableClass exact match
        % 6. Match empty peerClass, superclass for variableClass
        % 7. Exact match for peerClass, empty variableClass
        % 8. Match superclass for peerClass, empty variableClass

            % 1. First look for exact peer/variable class mapping            
            % check for exact match with DataAttributes
            matchedContext = [];
            dataAttributes = sort(dataAttributes);
            key = this.createKey(peerClass,variableClass,context, dataAttributes);
            if isKey(this.Map, key)
                widgets = this.Map(key);
                matchedPeerClass = peerClass;
                matchedVariableClass = variableClass;
                matchedContext = context;
                matchedDataAttributes = dataAttributes;
                return;
            end

            % Exact match not found, see if we've searched for this entry
            % before
            searchKey = key;
            if isKey(this.SearchMap, searchKey)
                previousMatch = this.SearchMap(searchKey);
                widgets = previousMatch.widgets;
                matchedPeerClass = previousMatch.matchedPeerClass;
                matchedVariableClass = previousMatch.matchedVariableClass;
                matchedContext = previousMatch.matchedContext;
                matchedDataAttributes = previousMatch.matchedDataAttributes;
                return;
            end

            % check for exact match with dataAttributes
            matchedContext = [];
            [foundMatch, ~, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes] = this.findKey(peerClass,variableClass,context,dataAttributes);
            if foundMatch
                this.addSearchMatch(searchKey, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes);
                return;
            end
            
            % Now match with just peerClass and variableClass and
            % dataAttributes
            [foundMatch, ~, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes] = this.findKey(peerClass,variableClass,'',dataAttributes);
            if foundMatch
                this.addSearchMatch(searchKey, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes);
                return;
            end

            % check for match without dataAttributes
            [foundMatch, ~, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes] = this.findKey(peerClass,variableClass,context);
            if foundMatch
                this.addSearchMatch(searchKey, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes);
                return;
            end

            % check for match without context or dataAttributes
            [foundMatch, ~, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes] = this.findKey(peerClass,variableClass);
            if foundMatch
                this.addSearchMatch(searchKey, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes);
                return;
            end

            sclistPeer = {};
            if ~isempty(variableClass)
                % Next try superclasses of the variable class with the peer
                % class
                sclistVar = superclasses(variableClass);
                if ~isempty(peerClass)
                    for i=1:length(sclistVar)
                        [foundMatch, ~, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes] = this.findKey(peerClass,sclistVar{i},context,dataAttributes);
                        if foundMatch
                            this.addSearchMatch(searchKey, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes);
                            return;
                        end
                        [foundMatch, ~, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes] = this.findKey(peerClass,sclistVar{i},'',dataAttributes);
                        if foundMatch
                            this.addSearchMatch(searchKey, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes);
                            return;
                        end
                        [foundMatch, ~, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes] = this.findKey(peerClass,sclistVar{i},context);
                        if foundMatch
                            this.addSearchMatch(searchKey, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes);
                            return;
                        end
                        [foundMatch, ~, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes] = this.findKey(peerClass,sclistVar{i});
                        if foundMatch
                            this.addSearchMatch(searchKey, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes);
                            return;
                        end
                    end
                end

                if ~isempty(peerClass)
                    % Next try only superclasses of the peer class
                    sclistPeer = string(superclasses(peerClass));
                    if doGenericObjectCheck
                        sclistPeer(end+1) = "object";
                    end
                    sclistPeer = sclistPeer(ne(sclistPeer, "internal.matlab.legacyvariableeditor.peer.PeerVariableNode"));
                    for i=1:length(sclistPeer)
                        [foundMatch, ~, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes] = this.findKey(sclistPeer{i},variableClass,context,dataAttributes);
                        if foundMatch
                            this.addSearchMatch(searchKey, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes);
                            return;
                        end
                        [foundMatch, ~, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes] = this.findKey(sclistPeer{i},variableClass,'',dataAttributes);
                        if foundMatch
                            this.addSearchMatch(searchKey, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes);
                            return;
                        end
                        [foundMatch, ~, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes] = this.findKey(sclistPeer{i},variableClass,context);
                        if foundMatch
                            this.addSearchMatch(searchKey, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes);
                            return;
                        end
                        [foundMatch, ~, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes] = this.findKey(sclistPeer{i},variableClass);
                        if foundMatch
                            this.addSearchMatch(searchKey, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes);
                            return;
                        end
                    end
                end

                % Try superclasses of both the peer class and the
                % variable class
                if ~isempty(peerClass)
                    if isempty(sclistPeer)
                        sclistPeer = string(superclasses(peerClass));
                        if doGenericObjectCheck
                            sclistPeer(end+1) = "object";
                        end
                    end
                    if ~isempty(sclistVar) && ~isempty(sclistPeer)
                        for i=1:length(sclistPeer)
                            for j=1:length(sclistVar)
                                [foundMatch, ~, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes] = this.findKey(sclistPeer{i},sclistVar{j},context,dataAttributes);
                                if foundMatch
                                    this.addSearchMatch(searchKey, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes);
                                    return;
                                end
                                [foundMatch, ~, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes] = this.findKey(sclistPeer{i},sclistVar{j},'',dataAttributes);
                                if foundMatch
                                    this.addSearchMatch(searchKey, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes);
                                    return;
                                end
                                [foundMatch, ~, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes] = this.findKey(sclistPeer{i},sclistVar{j},context);
                                if foundMatch
                                    this.addSearchMatch(searchKey, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes);
                                    return;
                                end
                                [foundMatch, ~, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes] = this.findKey(sclistPeer{i},sclistVar{j});
                                if foundMatch
                                    this.addSearchMatch(searchKey, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes);
                                    return;
                                end
                            end
                        end
                    end
                end

                % Next try to match just the variable class
                [foundMatch, ~, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes] = this.findKey('',variableClass,context,dataAttributes);
                if foundMatch
                    this.addSearchMatch(searchKey, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes);
                    return;
                end
                [foundMatch, ~, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes] = this.findKey('',variableClass,'',dataAttributes);
                if foundMatch
                    this.addSearchMatch(searchKey, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes);
                    return;
                end
                [foundMatch, ~, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes] = this.findKey('',variableClass,context);
                if foundMatch
                    this.addSearchMatch(searchKey, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes);
                    return;
                end
                [foundMatch, ~, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes] = this.findKey('',variableClass);
                if foundMatch
                    this.addSearchMatch(searchKey, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes);
                    return;
                end

                % Next try only superclasses of the variable class
                for i=1:length(sclistVar)
                    [foundMatch, ~, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes] = this.findKey('',sclistVar{i},context,dataAttributes);
                    if foundMatch
                        this.addSearchMatch(searchKey, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes);
                        return;
                    end
                    [foundMatch, ~, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes] = this.findKey('',sclistVar{i},'',dataAttributes);
                    if foundMatch
                        this.addSearchMatch(searchKey, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes);
                        return;
                    end
                    [foundMatch, ~, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes] = this.findKey('',sclistVar{i},context);
                    if foundMatch
                        this.addSearchMatch(searchKey, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes);
                        return;
                    end
                    [foundMatch, ~, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes] = this.findKey('',sclistVar{i});
                    if foundMatch
                        this.addSearchMatch(searchKey, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes);
                        return;
                    end
                end
            end

            if ~isempty(peerClass)
                % Next try to match just the peer class
                [foundMatch, ~, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes] = this.findKey(peerClass,'',context,dataAttributes);
                if foundMatch
                    this.addSearchMatch(searchKey, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes);
                    return;
                end
                [foundMatch, ~, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes] = this.findKey(peerClass,'','',dataAttributes);
                if foundMatch
                    this.addSearchMatch(searchKey, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes);
                    return;
                end
                [foundMatch, ~, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes] = this.findKey(peerClass,'',context);
                if foundMatch
                    this.addSearchMatch(searchKey, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes);
                    return;
                end
                [foundMatch, ~, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes] = this.findKey(peerClass,'');
                if foundMatch
                    this.addSearchMatch(searchKey, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes);
                    return;
                end

                % Next try only superclasses of the peer class
                if isempty(sclistPeer)
                    sclistPeer = string(superclasses(peerClass));
                    if doGenericObjectCheck
                        sclistPeer(end+1) = "object";
                    end
                end
                for i=1:length(sclistPeer)
                    [foundMatch, ~, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes] = this.findKey(sclistPeer{i},'',context,dataAttributes);
                    if foundMatch
                        this.addSearchMatch(searchKey, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes);
                        return;
                    end
                    [foundMatch, ~, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes] = this.findKey(sclistPeer{i},'','',dataAttributes);
                    if foundMatch
                        this.addSearchMatch(searchKey, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes);
                        return;
                    end
                    [foundMatch, ~, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes] = this.findKey(sclistPeer{i},'',context);
                    if foundMatch
                        this.addSearchMatch(searchKey, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes);
                        return;
                    end
                    [foundMatch, ~, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes] = this.findKey(sclistPeer{i},'');
                    if foundMatch
                        this.addSearchMatch(searchKey, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes);
                        return;
                    end
                end
            end

            % Finally default to Unsupported mapping
            key = this.createKey('','');
            widgets = this.Map(key);
            matchedPeerClass = '';
            matchedVariableClass = '';

            this.addSearchMatch(searchKey, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes);
        end

        function [foundMatch, key, widgets, matchedPeerClass, matchedVariableClass, matchedContext, matchedDataAttributes] = findKey(this,peerClass,variableClass,context,dataAttributes)
            arguments
                this
                peerClass = ""
                variableClass = ""
                context = ""
                dataAttributes = ""
            end
            dataAttributes = sort(dataAttributes);
            key = this.createKey(peerClass,variableClass,context,dataAttributes);
            foundMatch = isKey(this.Map, key);
            matchedPeerClass = string.empty;
            matchedVariableClass = string.empty;
            matchedContext = string.empty;
            matchedDataAttributes = string.empty;
            widgets = struct.empty;
            if foundMatch
                widgets = this.Map(key);
                matchedPeerClass = peerClass;
                matchedVariableClass = variableClass;
                matchedContext = context;
                matchedDataAttributes = dataAttributes;
                this.SearchMap(key) = widgets;
                return;
            end
        end

        % getEditor
        function editor=getEditor(this, peerClass, variableClass)
            editor = [];
            widgets = this.getWidgets(peerClass, variableClass);
            if ~isempty(widgets)
                editor = widgets.Editor;
            end
        end

        % getInPlaceEditor
        function editor=getInPlaceEditor(this, peerClass, variableClass)
            editor = [];
            widgets = this.getWidgets(peerClass, variableClass);
            if ~isempty(widgets)
                editor = widgets.InPlaceEditor;
            end
        end

        % getCellRenderer
        function renderer=getCellRenderer(this, peerClass, variableClass)
            renderer = [];
            widgets = this.getWidgets(peerClass, variableClass);
            if ~isempty(widgets)
                renderer = widgets.CellRenderer;
            end
        end

        function converter=getEditorConverter(this, peerClass, variableClass)
            converter = [];
            widgets = this.getWidgets(peerClass, variableClass);
            if ~isempty(widgets)
                converter = widgets.EditorConverter;
            end
        end

        % registerWidgets
        function registerWidgets(this, peerClass, variableClass, editor, inPlaceEditor, renderer, converter)
            if nargin<7
                converter = '';
            end
            key = this.createKey(peerClass, variableClass);
            this.Map(key) = this.createWidgetStruct(editor, inPlaceEditor, renderer, converter);

            % Empty out the search map
            this.SearchMap = this.SearchMap.remove(keys(this.SearchMap));
        end

        % registerEditor
        function widgets = registerEditor(this, peerClass, variableClass, editor)
            key = this.createKey(peerClass, variableClass);
            widgets = this.getWidgets(peerClass, variableClass);
            widgets.Editor = editor;
            this.Map(key) = widgets;

            % Empty out the search map
            this.SearchMap = this.SearchMap.remove(keys(this.SearchMap));
        end

        % registerInPlaceEditor
        function widgets = registerInPlaceEditor(this, peerClass, variableClass, inPlaceEditor)
            key = this.createKey(peerClass, variableClass);
            widgets = this.getWidgets(peerClass, variableClass);
            widgets.InPlaceEditor = inPlaceEditor;
            this.Map(key) = widgets;

            % Empty out the search map
            this.SearchMap = this.SearchMap.remove(keys(this.SearchMap));
        end

        % registerCellRenderer
        function widgets = registerCellRenderer(this, peerClass, variableClass, cellRenderer)
            key = this.createKey(peerClass, variableClass);
            widgets = this.getWidgets(peerClass, variableClass);
            widgets.CellRenderer = cellRenderer;
            this.Map(key) = widgets;

            % Empty out the search map
            this.SearchMap = this.SearchMap.remove(keys(this.SearchMap));
        end

        function widgets = registerEditorConverter(this, peerClass, variableClass, converter)
            key = this.createKey(peerClass, variableClass);
            widgets = this.getWidgets(peerClass, variableClass);
            widgets.EditorConverter = converter;
            this.Map(key) = widgets;

            % Empty out the search map
            this.SearchMap = this.SearchMap.remove(keys(this.SearchMap));
        end

        % deregisterWidgets
        function deregisterWidgets(this, peerClass, variableClass)
            key = this.createKey(peerClass, variableClass);
            this.Map = this.Map.remove(key);

            % Empty out the search map
            this.SearchMap = this.SearchMap.remove(keys(this.SearchMap));
        end

        function b = isUnknownView(this, val)
            b = strcmp(val, this.UnknownView);
        end
    end
end
