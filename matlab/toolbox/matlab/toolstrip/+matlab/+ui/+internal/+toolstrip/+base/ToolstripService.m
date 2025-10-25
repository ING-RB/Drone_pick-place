classdef (Sealed) ToolstripService < handle
    %Common toolstrip server side service.
    
    % Author(s): Rong Chen
    % Copyright 2014-2020 The MathWorks, Inc.
    properties (Access = private)
        % Cache the view model managers to avoid creating a new Connector channel 
        % each time a call is made to obtain a view model manager
        ViewModelManagerCache = containers.Map.empty;
    end
    
    properties (Constant, Access = private)
        Instance = matlab.ui.internal.toolstrip.base.ToolstripService;
    end
    methods (Static)
        function manager = get(channel)
            if matlab.ui.internal.toolstrip.base.ViewModelUtilities.isViewModelChannel(channel)
                instance = matlab.ui.internal.toolstrip.base.ToolstripService.Instance;
                vmmCache = instance.ViewModelManagerCache;
                if vmmCache.isKey(channel) && isvalid(vmmCache(channel))
                    manager = vmmCache(channel);
                else
                    manager = viewmodel.internal.ViewModelManagerFactory.getViewModelManager(channel, struct('plugins', struct('moveEvent', true)));
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
            if matlab.ui.internal.toolstrip.base.ViewModelUtilities.isViewModelChannel(channel)
                % get manager
                manager = matlab.ui.internal.toolstrip.base.ToolstripService.get(channel);
                % toolstrip root must be the FIRST root node because of the
                % refreshing order is from LAST to FIRST as of today.  The
                % other utility roots such as popup and gallery must be
                % refreshed before the toolstrip root because of the
                % dependency.  Orphan should be the LAST root.
                % if has root, add toolstrip sub-roots when necessary
                if manager.hasRoot()
                    Root = manager.Root;
                    if isempty(manager.getByType('ToolstripRoot') )
                        Root.addChild('ToolstripRoot');
                    end
                    if isempty( manager.getByType('QABRoot') )
                        Root.addChild('QABRoot');
                    end
                    if isempty( manager.getByType('GalleryRoot') )
                        GalleryRoot = Root.addChild('GalleryRoot');
                        GalleryRoot.addChild('GalleryPopupRoot');
                        GalleryRoot.addChild('GalleryFavoriteCategoryRoot');
                    end
                    if isempty( manager.getByType('PopupRoot') )
                        Root.addChild('PopupRoot');
                    end
                    if isempty( manager.getByType('OrphanRoot') )
                        Root.addChild('OrphanRoot');
                    end
                    % otherwise, create root and toolstrip sub-roots
                else
                    Root = manager.setRoot('Root');
                    Root.addChild('ToolstripRoot');
                    Root.addChild('QABRoot');
                    GalleryRoot = Root.addChild('GalleryRoot');
                    GalleryRoot.addChild('GalleryPopupRoot');
                    GalleryRoot.addChild('GalleryFavoriteCategoryRoot');
                    Root.addChild('PopupRoot');
                    Root.addChild('OrphanRoot');
                end
            else
                
                
                % get manager
                manager = com.mathworks.peermodel.PeerModelManagers.getInstance(channel);
                % ensure synchronized
                if ~manager.isSyncEnabled
                    manager.setSyncEnabled(true);
                end
                % toolstrip root must be the FIRST root node because of the
                % refreshing order is from LAST to FIRST as of today.  The
                % other utility roots such as popup and gallery must be
                % refreshed before the toolstrip root because of the
                % dependency.  Orphan should be the LAST root.
                % if has root, add toolstrip sub-roots when necessary
                if manager.hasRoot()
                    Root = manager.getRoot();
                    if manager.getByType('ToolstripRoot').isEmpty
                        Root.addChild('ToolstripRoot');
                    end
                    if manager.getByType('QABRoot').isEmpty
                        Root.addChild('QABRoot');
                    end
                    if manager.getByType('GalleryRoot').isEmpty
                        GalleryRoot = Root.addChild('GalleryRoot');
                        GalleryRoot.addChild('GalleryPopupRoot');
                        GalleryRoot.addChild('GalleryFavoriteCategoryRoot');
                    end
                    if manager.getByType('PopupRoot').isEmpty
                        Root.addChild('PopupRoot');
                    end
                    if manager.getByType('OrphanRoot').isEmpty
                        Root.addChild('OrphanRoot');
                    end
                    % otherwise, create root and toolstrip sub-roots
                else
                    Root = manager.setRoot('Root');
                    Root.addChild('ToolstripRoot');
                    Root.addChild('QABRoot');
                    GalleryRoot = Root.addChild('GalleryRoot');
                    GalleryRoot.addChild('GalleryPopupRoot');
                    GalleryRoot.addChild('GalleryFavoriteCategoryRoot');
                    Root.addChild('PopupRoot');
                    Root.addChild('OrphanRoot');
                end
                
            end
        end
        
        function cleanup(channel)
            if matlab.ui.internal.toolstrip.base.ViewModelUtilities.isViewModelChannel(channel)
                manager = matlab.ui.internal.toolstrip.base.ToolstripService.get(channel);
                if isvalid(manager)
                    manager.delete();
                end
            else
                com.mathworks.peermodel.PeerModelManagers.cleanup(channel);
            end
        end
        
        function manager = reset(channel)
            if matlab.ui.internal.toolstrip.base.ViewModelUtilities.isViewModelChannel(channel)
                manager = matlab.ui.internal.toolstrip.base.ToolstripService.get(channel);
                if isvalid(manager)
                    manager.delete();
                end
            else
                % get manager
                manager = com.mathworks.peermodel.PeerModelManagers.getInstance(channel);
                % remove all
                types = {'OrphanRoot';'PopupRoot';'QABRoot';'GalleryRoot';'ToolstripRoot'};
                if manager.hasRoot()
                    for ct=1:length(types)
                        node = manager.getByType(types{ct});
                        if ~node.isEmpty
                            node.get(0).destroy();
                        end
                    end
                    manager.getRoot.remove();
                end
            end
            % initialize
            manager = matlab.ui.internal.toolstrip.base.ToolstripService.initialize(channel);
        end
        
    end
        
end