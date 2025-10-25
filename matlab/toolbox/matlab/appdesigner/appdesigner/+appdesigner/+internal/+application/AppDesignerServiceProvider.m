classdef AppDesignerServiceProvider < handle
    % AppDesignerServiceProvider holds all services currently active in App
    % Designer
    %
    % Each service is a property that can be set / retrieved.
    
    
    % Copyright 2019 The MathWorks, Inc.
    
    properties
        % Services and their defaults
        
        BrowserControllerFactory  appdesservices.internal.peermodel.BrowserControllerFactory = ...
            appdesservices.internal.peermodel.BrowserControllerFactory.CEF;     
        
        StartupStateProviderFactory appdesigner.internal.application.startup.StartupStateProviderFactory = ...
            appdesigner.internal.application.startup.DesktopStartupStateProviderFactory;
        
        FigureService appdesigner.internal.application.figure.FigureService = ...
            appdesigner.internal.application.figure.DesktopFigureService;
        
        ViewModelManagerFactory = ...
            appdesservices.internal.peermodel.PeerNodeProxyView.getViewModelManagerFactory('MF0ViewModel');
    end    
    
end

