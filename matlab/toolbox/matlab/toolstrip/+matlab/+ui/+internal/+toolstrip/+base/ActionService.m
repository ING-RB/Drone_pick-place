classdef (Sealed) ActionService < handle
    % Singleton message center handles communications between web browser
    % and MATLAB via connector messaging API.

    % Author(s): Rong Chen
    % Copyright 2013-2021 The MathWorks, Inc.

    properties (Access = private)
        % Cache the view model managers to avoid creating a new Connector channel 
        % each time a call is made to obtain a view model manager
        ViewModelManagerCache = containers.Map.empty;
    end

    properties (Constant, Access = private)
        Instance = matlab.ui.internal.toolstrip.base.ActionService;
    end

    methods (Static)

        function manager = get(channel)
            if matlab.ui.internal.toolstrip.base.ViewModelUtilities.isViewModelChannelForAS(channel)
                instance = matlab.ui.internal.toolstrip.base.ActionService.Instance;
                vmmCache = instance.ViewModelManagerCache;
                if vmmCache.isKey(channel) && isvalid(vmmCache(channel))
                    manager = vmmCache(channel);
                else
                    manager = viewmodel.internal.ViewModelManagerFactory.getViewModelManager(channel);
                    % View Model callbacks are made to be asynchronous as described in
                    % https://confluence.mathworks.com/display/MABIS/View+Model+Callbacks+Asynchronicity
                    % This is a temporary opt in mechanism that can be removed later when the View Model
                    % callbacks are async by default
                    if ismethod(manager, 'setAsyncFlag')
                        manager.setAsyncFlag(true);
                    end
                    addlistener(manager, 'ObjectBeingDestroyed', @(src, event) vmmCache.remove(channel));
                    vmmCache(channel) = manager;
                end
            else
                manager = com.mathworks.peermodel.PeerModelManagers.getInstance(channel);
            end
        end

        function manager = initialize(channel)
            if matlab.ui.internal.toolstrip.base.ViewModelUtilities.isViewModelChannelForAS(channel)
                manager = matlab.ui.internal.toolstrip.base.ActionService.get(channel);

                if ~manager.hasRoot()
                    manager.setRoot('Root');
                end
            else
                % get manager
                manager = com.mathworks.peermodel.PeerModelManagers.getInstance(channel);
                % ensure synchronized
                if ~manager.isSyncEnabled
                    manager.setSyncEnabled(true);
                end
                % add root if it does not exists
                if ~manager.hasRoot()
                    manager.setRoot('Root', java.util.HashMap);
                end
            end
        end

        function cleanup(channel)
            if matlab.ui.internal.toolstrip.base.ViewModelUtilities.isViewModelChannelForAS(channel)
                manager = matlab.ui.internal.toolstrip.base.ActionService.get(channel);
                if isvalid(manager)
                    manager.delete();
                end
            else
                com.mathworks.peermodel.PeerModelManagers.cleanup(channel);
            end
        end

        function reset(channel)
            if matlab.ui.internal.toolstrip.base.ViewModelUtilities.isViewModelChannelForAS(channel)
                manager = matlab.ui.internal.toolstrip.base.ActionService.get(channel);
                if isvalid(manager)
                    manager.delete();
                end

            else
                % get manager
                manager = com.mathworks.peermodel.PeerModelManagers.getInstance(channel);
                % remove all
                if manager.hasRoot()
                    manager.getRoot.remove();
                end
            end

            % initialize
            matlab.ui.internal.toolstrip.base.ActionService.initialize(channel);
        end
    end
end