classdef PreferencePanelManager < handle
    % PreferencePanelManager MATLAB backend that maintains the creation and
    % deletion of Preference Panels. It is also responsible for calling
    % certain APIs defined in the Preference Panels authored by downstream
    % teams that saves the preferences when the user tries to click on "OK"
    % or "Apply" buttons in the front end (Preferences dialog).

    properties (Constant)
        PREF_PANEL_CHANNEL = '/Preferences/PrefPanel';
    end

    methods (Static)
        function initializeAndReturnInitialState(metaData)
            % Subscribes to the preference panel channel to be able to
            % receive messages from the front end.
            import matlab.ui.internal.preferences.PreferencePanelManager;
            mlock;
            persistent MessageSubscription;
            if isempty(MessageSubscription)
                MessageSubscription = message.subscribe(PreferencePanelManager.PREF_PANEL_CHANNEL,...
                @(msg) PreferencePanelManager.handleReceivedMessage(msg));
            end
            PreferencePanelManager.getDisplayStateAndPanelLabels(metaData);
            PreferencePanelManager.readMessageCatalog(metaData);
        end

        function handleReceivedMessage(msg)
            % Handles the received message from the front end.
            import matlab.ui.internal.preferences.PreferencePanelManager;

            switch msg.type
                case 'PanelRequest'
                    PreferencePanelManager.createPanel(msg.id, msg.source);
                case 'Destroy'
                    PreferencePanelManager.destroy();
                case 'Commit'
                    PreferencePanelManager.commit(msg.dataToBeValidated);
                case 'PanelDisplayStateAndReadMessageCatalog'
                    PreferencePanelManager.getDisplayStateAndPanelLabels(msg.metaData);
                    PreferencePanelManager.readMessageCatalog(msg.metaData);
            end
        end

        function createPanel(panelId, panelSource)
            % Instantiates the given panel and puts it into a store.
            import matlab.ui.internal.preferences.PreferencePanelManager;

            store = PreferencePanelManager.getStore();
            enableGUIBuildingFeatures();

            try
                panel = eval(['matlab.ui.internal.preferences.preferencePanels.'...
                    panelSource '();']);

                % Theme figure
                matlab.graphics.internal.themes.figureUseDesktopTheme(panel.UIFigure);

                % Perform custom setting on the figure as suggested by GBT team.
                panel.UIFigure.Internal = true;

                % Get the figure packet from the figure service. This will
                % be forwarded to the front end.
                figureData = matlab.ui.internal.FigureServices.getDivFigurePacket(panel.UIFigure);

                % Store the panel instance
                store(panelId) = panel;

                data.figure = figureData;
            catch ME
                % Make sure we set the flag back if there's an error happening
                % during the instantiation.
                disableGUIBuildingFeatures();
                data.errorMessage = ME.message;
                data.figure = {};
            end

            disableGUIBuildingFeatures();

            data.type = 'PanelResponse';
            data.id = panelId;

            % Send the data to front end.
            message.publish(PreferencePanelManager.PREF_PANEL_CHANNEL, data);
        end

        function returnArray = getDisplayStateAndPanelLabels(metaData)
            % Determines whether the panels are configured to be hidden
            import matlab.ui.internal.preferences.PreferencePanelManager;

            returnArray = struct;

            for i = 1:numel(metaData)
                % Check if shouldShow method is defined on the panel
                try
                    m = methods(['matlab.ui.internal.preferences.preferencePanels.'...
                        metaData(i).source]);
                    index = find(strcmp(m, 'shouldShow'));
                    if index > 0
                        displayState = matlab.ui.internal.preferences.preferencePanels.(metaData(i).source).shouldShow();
                    else
                        displayState = true;
                    end
                catch exception
                    displayState = false;
                    returnArray(i).errorMessage = exception.message;
                end

                if displayState
                    try
                        labelKey = strcat(metaData(i).path, ':PanelLabel');
                        returnArray(i).label = getString(message(labelKey));
                    catch
                        % Do Nothing
                        returnArray(i).label = '';
                    end
                end
                try
                    returnArray(i).id = metaData(i).id;
                catch exception
                    returnArray(i).id = '';
                    displayState = false;
                    returnArray(i).errorMessage = exception.message;
                end
                returnArray(i).displayState = displayState;
            end

            data.type = 'DisplayStateAndPanelLabelResponse';
            data.message = returnArray;

            % Send the data to front end.
            message.publish(PreferencePanelManager.PREF_PANEL_CHANNEL, data);
        end

        function destroy()
            % Destroys all the panels by calling their delete method.
            import matlab.ui.internal.preferences.PreferencePanelManager;

            store = PreferencePanelManager.getStore();

            panelIds = keys(store);

            for i = 1:numel(panelIds)
                if isKey(store, panelIds{i})
                    % Remove the panel from the store. This will also
                    % destroy the panel by calling its delete method.
                    store.remove(panelIds{i});
                end
            end
        end

        function commit(dataToBeValidated)
            % Validates and commits all the preferences
            import matlab.ui.internal.preferences.PreferencePanelManager;

            store = PreferencePanelManager.getStore();

            data.type = "CommitResponse";

            if isempty(fieldnames(dataToBeValidated))
                % No validation required since a MATLAB authored panel is not currently selected
                PreferencePanelManager.commitAllPreferences();
            else
                % MATLAB authored panel is currently selected. Validate it first before committing
                % all the preferences.
                try
                    commitResults = PreferencePanelManager.commitAllPreferences();
                    data.commitSuccess = commitResults.commitSuccess;
                catch ME
                   data.commitSuccess = false;
                   data.commitErrorMessage = ME.message;
                end

                % Send the data to front end.
                message.publish(PreferencePanelManager.PREF_PANEL_CHANNEL, data);
            end
        end

        function toReturn = createRelativePath(l10n)
            toReturn = strcat(matlabroot, "/resources");
            pathWords = split(l10n, ":");
            pathLength = length(pathWords);
            for i = 1: pathLength
                if i == 2
                    toAdd = strcat('/en/', pathWords(i));
                    toReturn = strcat(toReturn, toAdd);
                else
                    toAdd = strcat('/', pathWords(i));
                    toReturn = strcat(toReturn, toAdd);
                end
                if i == pathLength
                    toReturn = strcat(toReturn, '.xml');
                end
            end
        end

        function returnArray = readMessageCatalog(paths)
            import matlab.ui.internal.preferences.PreferencePanelManager;
            data.type = "ReadMessageCatalogResponse";

            returnArray = struct;
            searchIndex = struct([]);
            pathLength = length(paths);
            for i = 1: pathLength
                if (isfield(paths(i), "id") == 1)
                    if (isfield(paths(i), "path") == 1)
                        l10n = paths(i).path;
                        if (isempty(l10n) == 0)
                            relativePath = PreferencePanelManager.createRelativePath(l10n);
                            toReturn = "";
                            try
                                import matlab.io.xml.dom.*;
                                xmlFile = fullfile(relativePath);
                                DOMnode = parseFile(Parser,xmlFile);
                                entries = DOMnode.getElementsByTagName('entry');
                                entryLength = entries.getLength-1;
                                for j = 0:entryLength
                                    %if the message is an error message we
                                    %don't want it in the searchData map
                                    if (entries.item(j).hasAttribute('error') == 0)
                                        key  = char(entries.item(j).getAttribute('key'));
                                        % must be able to pass in the intro path
                                        newL10n = strcat(l10n, ":");
                                        messageID = message(strcat(newL10n, key));
                                        try
                                            value = getString(messageID);
                                            index = length(searchIndex) + 1;
                                            searchIndex(index).icon = "settings";
                                            searchIndex(index).text = value;
                                            searchIndex(index).panelId = paths(i).id;
                                            toReturn = strcat(toReturn, value);
                                            toReturn = strcat(toReturn, " ");
                                        catch
                                            toReturn = strcat(toReturn, "");
                                        end
                                    end
                                end
                            catch
                                toReturn = "";
                            end
                        else
                            toReturn = "";
                        end
                    else
                        toReturn = "";
                    end
                    if (i == 1)
                        returnArray(end).id = paths(i).id;
                        returnArray(end).value = toReturn;
                    else
                        returnArray(end+1).id = paths(i).id;
                        returnArray(end).value = toReturn;
                    end
                end
            end
            data.message = returnArray;
            data.searchIndex = searchIndex;
            message.publish(PreferencePanelManager.PREF_PANEL_CHANNEL, data);
        end

        function result = commitAllPreferences()
            % Commits all the preferences
            import matlab.ui.internal.preferences.PreferencePanelManager;

            store = PreferencePanelManager.getStore();

            panelIds = keys(store);

            try
                for i = 1:numel(panelIds)
                    eval(['store(''' panelIds{i} ''').commit();']);
                end

                result.commitSuccess = true;
            catch ME
                result.commitSuccess = false;
                result.commitErrorMessage = ME.message;
            end
        end

        function store = getStore()
            % Returns the store
            mlock
            persistent map

            if isempty(map)
                map = containers.Map();
            end
            store = map;
        end
    end
end

function enableGUIBuildingFeatures()
    % Utility method that enables certain features for creating the panel.
    s = settings;

    % Enables the embedded figure. Before it's disabled, UIFigure
    % created in between will be embedded figure instead of the one that
    % pops out a window.
    s.matlab.ui.figure.ShowEmbedded.TemporaryValue = 1;
end

function disableGUIBuildingFeatures()
    % Utility method that disables certain features for the panel.
    s = settings;

    s.matlab.ui.figure.ShowEmbedded.TemporaryValue = 0;
end
