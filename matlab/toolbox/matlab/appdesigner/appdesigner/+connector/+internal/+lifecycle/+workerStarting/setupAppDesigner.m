function setupAppDesigner()
% Called when being used in a connector environment (ex: MO)
%
% Updates App Designer to use whatever configuration it needs to run in
% MATLAB Online

% Copyright 2018 The MathWorks, Inc.

serviceProvider = appdesigner.internal.application.getAppDesignerServiceProvider();        

% Install relevant services
serviceProvider.BrowserControllerFactory = appdesservices.internal.peermodel.BrowserControllerFactory.MATLABOnline;
serviceProvider.StartupStateProviderFactory = appdesigner.internal.application.startup.OnlineStartupStateProviderFactory;
serviceProvider.FigureService =  appdesigner.internal.application.figure.OnlineFigureService; 
end

