classdef FigureLifecycleController < handle

    % FIGURELIFECYCLECONTROLLER Meta controller object for
    % matlab.ui.Figure webfigures of any type
    %
    % It manages server side lifecycle related figure operations that may
    % occur outside of the lifecycle of the individual figure server side
    % object itself.
    %
    % This class is not a singleton, but is managed as a singleton by
    % FigureLifecycleControllerManager.m

    % Copyright 2021-2023 The MathWorks, Inc.

    properties (GetAccess = {?tFigureLifecycleController, ?drooltypes.FigureDrool})
        PlatformHostMap;
        MasterChannel
        SubscriptionId;
        ActiveLaunches
        PendingItems
    end

    properties(Constant, GetAccess = ?tFigureLifecycleController)
        % We understand it to be a limit that the maximum number of
        % available HTTP connections is 6.  As such, we will by convention
        % prevent more than 6 Figures from launching views simultaneously.
        MAX_NUM_SIMULTANEOUS_FIGURE_LAUNCHES = 6;
    end

    methods(Access=public)
        function this = FigureLifecycleController(masterChannel)
            narginchk(1,1);
            this.PendingItems = {};
            this.ActiveLaunches = containers.Map;

            this.MasterChannel = masterChannel;
            this.PlatformHostMap = containers.Map;

            % subscribe on the channel to handle messages coming from the client
            this.SubscriptionId = message.subscribe(this.MasterChannel, @(data)this.handleMessage(data));
        end

        function delete(this)
            % Delete everything in Figure map to avoid leaking references
            delete(this.PlatformHostMap);

            if (~isempty(this.SubscriptionId))
                message.unsubscribe(this.SubscriptionId);
            end
        end

        function addFigure(this, uuid, platformHost)
            narginchk(3,3);

            this.PlatformHostMap(uuid) = platformHost;
        end

        function throttledFigureViewLaunch(this, uuid, figLaunchFunction)
            narginchk(3,3);

            if(this.ActiveLaunches.Count < this.MAX_NUM_SIMULTANEOUS_FIGURE_LAUNCHES)
                this.ActiveLaunches(uuid) = true;
                figLaunchFunction();
            else
                storedFig.uuid = uuid;
                storedFig.figLaunchFunction = figLaunchFunction;
                this.PendingItems{end+1} = storedFig;
            end
        end

        function removeFigure(this, uuid)
            narginchk(2,2);

            if this.PlatformHostMap.isKey(uuid)

                platformHost = this.PlatformHostMap(uuid);

                removedUUID = platformHost.getWindowUUID();
                checkWindowUUIDLife(this,uuid, removedUUID, 1)

                this.PlatformHostMap.remove(uuid);
            end

            % Remove the Figure from the active and pending launches.
            % If the client side asynchronously appears after the
            % Figure has been removed on the model side, then the
            % clean up code in handleFevalMessage will publish a
            % windowClosed message to clean up the view.
            if this.ActiveLaunches.isKey(uuid)
               this.ActiveLaunches.remove(uuid);
            end
            for i = 1:length(this.PendingItems)
                if this.PendingItems{i}.uuid == uuid
                    this.PendingItems(i) = [];
                    break;
                end
            end
        end

        function bool = isKnownFigure(this, uuid)
            bool = this.PlatformHostMap.isKey(uuid);
        end
    end

    methods(Access = 'private')

        function checkWindowUUIDLife(this, figureUUID, alteredWindowUUID, countToNotifyOn)
            % Goes over all window IDs comparing them to the window being
            % closed
            %
            % If there is exactly 1 instance of a Figure using a Window ID,
            % that means when that figure is destroyed the window will have
            % no figures in it, and we can signal that window is closed.

            allWindowUUIDs = this.PlatformHostMap.keys;
            numberOfWindowsUsingNotifiedUUID = sum(strcmp(string(allWindowUUIDs), alteredWindowUUID));

            if(numberOfWindowsUsingNotifiedUUID == countToNotifyOn)
                platformHost = this.PlatformHostMap(figureUUID);
                notifyWindowUUIDClosed(platformHost);
            end
        end
    end

    methods
        % handleMessage() - handle messages sent by client
        function handleMessage(this, data)

            if strcmpi(data.eventType, 'clientReady')
                if ~this.PlatformHostMap.isKey(data.uuid)
                    % Client is ready - negative path
                    %
                    % The Window loaded but while doing so the MATLAB side
                    % was removed
                    message.publish(data.stcChannel, struct('eventType', 'windowClosed'));
                end
            end

            if(strcmp(data.eventType, 'windowUUIDClientCreated'))

                % Window UUID has been created

                platformHost = this.PlatformHostMap(data.figureUUID);
                windowUUID = data.WindowUUID;
                oldWindowUUID = platformHost.getWindowUUID();

                if(~isempty(oldWindowUUID))
                    % the platform host had an old ID, it was likely
                    % being undocked or re-docked
                    %
                    % If there was exactly 1 window using this ID, then
                    %  likely this was an undocked window being
                    %  re-docked
                    checkWindowUUIDLife(this, data.figureUUID, oldWindowUUID, 1)
                end

                % Update to the new UUID
                platformHost.setWindowUUID(windowUUID);

                eventData.eventType = 'windowUUIDServerReady';
                eventData.figureUUID = data.figureUUID;
                eventData.WindowUUID = data.WindowUUID;
                message.publish(this.MasterChannel, eventData);
            end
        end

        % handleMessage() - handle messages sent by client
        function handleFevalMessage(this, uuid, returnChannel, eventData)

            if strcmpi(eventData.eventType, 'clientReady')
                if matlab.ui.internal.hasFigureViewRequest(uuid)
                    matlab.ui.internal.completeFigureView(uuid);
                end

                if isKey(this.ActiveLaunches,uuid)
                    remove(this.ActiveLaunches,uuid);
                end

                if(~isempty(this.PendingItems) && this.ActiveLaunches.Count < this.MAX_NUM_SIMULTANEOUS_FIGURE_LAUNCHES)
                    figToLaunch = this.PendingItems{1};
                    if length(this.PendingItems) > 1
                        this.PendingItems = this.PendingItems(2:end);
                    else
                        this.PendingItems = {};
                    end

                    this.ActiveLaunches(figToLaunch.uuid) = true;
                    figToLaunch.figLaunchFunction();
                end
            end

            if ~this.PlatformHostMap.isKey(uuid)
                % If the key is not in the map, but we are still getting
                % view events for the given uuid, then the figure model has
                % been deleted and the view is out of sync with that
                % deletion; therefore, close the view.
                message.publish(returnChannel, struct('eventType', 'windowClosed'));
                return;
            end
            if(strcmp(eventData.eventType, 'windowUUIDClientCreated'))
                this.handleMessage(eventData)
                return;
            end

            % Otherwise, let the platform host handle it
            platformHost = this.PlatformHostMap(uuid);
            platformHost.handleMessage(eventData);
        end
    end
end
