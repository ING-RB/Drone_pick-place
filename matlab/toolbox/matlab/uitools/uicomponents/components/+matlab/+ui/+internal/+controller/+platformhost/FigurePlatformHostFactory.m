classdef FigurePlatformHostFactory < handle

    % FIGUREPLATFORMHOSTFACTORY is the factory class that creates a FigurePlatformHost instance
    %                           for the environment in which the FigureController is created.

    % Copyright 2016-2024 The MathWorks, Inc.

    methods (Access = public)

        % constructor
        function this = FigurePlatformHostFactory()
        end % constructor

        % createHost - create a FigurePlatformHost for the current platform
        function figurePlatformHost = createHost(this, controllerInfo, updatesFromClientImpl)
            
            % get the appropriate host class and instantiate it
            hostClass = this.getPlatformHostClass(controllerInfo);
            figurePlatformHost = hostClass(updatesFromClientImpl);
            
        end % createHost()

    end % public methods

    methods (Access = private)

        % getPlatformHostClass - detect the platform and
        %                        get the FigurePlatformHost class appropriate for it
        function platformHost = getPlatformHostClass(~, controllerInfo)
            import matlab.internal.capability.Capability;

            % BEGIN LEGACY JAVA IMPLEMENTATION
            if ~feature("webui")
                if isfield(controllerInfo, 'div')
                    % Div designation takes priority over all other conditions
                    platformHost = @matlab.ui.internal.controller.platformhost.DivFigurePlatformHost;
                elseif isfield(controllerInfo, 'embedded')
                    % Embedded designation takes priority over everything but div
                    platformHost = @matlab.ui.internal.controller.platformhost.EmbeddedFigurePlatformHost;            
                else
                    s = settings;
                    if s.matlab.ui.figure.ShowInMATLABOnline.ActiveValue
                        platformHost = @matlab.ui.internal.controller.platformhost.MOFigurePlatformHost;
                    else
                        platformHost = @matlab.ui.internal.controller.platformhost.CEFFigurePlatformHost;
                    end
                end
                return;
            end
            % END LEGACY JAVA IMPLEMENTATION
            
            % BEGIN LEGACY EMBEDDEDFIGURE IMPLEMENTATION
            if isfield(controllerInfo,"embedded")
                platformHost = @matlab.ui.internal.controller.platformhost.EmbeddedFigurePlatformHost;
                return;
            end
            % END LEGACY EMBEDDEDFIGURE IMPLEMENTATION

            % Handle embedded Figures
            if isfield(controllerInfo, "IsEmbedded")
                platformHost = @matlab.ui.internal.controller.platformhost.DivFigurePlatformHost;
                return;
            end
            
            % Handle isolated Figures
            if isfield(controllerInfo, "IsIsolatedRequested")
                if Capability.isSupported(Capability.LocalClient)
                    platformHost = @matlab.ui.internal.controller.platformhost.CEFFigurePlatformHost;
                    return;
                end
            end

            % Make sure to create a view for printing in situations where Figure windows don't appear on screen
            if ~(matlab.ui.internal.hasDisplay && matlab.ui.internal.isFigureShowEnabled)
                platformHost = @matlab.ui.internal.controller.platformhost.CEFFigurePlatformHost;
                return;
            end

            % Attempt Desktop Figure, fall back on isolated
            if matlab.ui.internal.getDesktopFigureReadyForLaunch
                platformHost = @matlab.ui.internal.controller.platformhost.DivFigurePlatformHost;
                return;
            elseif (~matlab.ui.internal.isDesktopAvailable || matlab.desktop.internal.webdesktop("-isExternal"))
                platformHost = @matlab.ui.internal.controller.platformhost.CEFFigurePlatformHost;
                return;
            end

            % Attempt to load the Desktop if needed
            if ~matlab.desktop.internal.webdesktop("-inuse")
                matlab.ui.container.internal.RootApp.getInstance();
            end

            % Wait for Figure infrastructure load or timeout.
            token = matlab.ui.internal.controller.platformhost.FigureReadyForLaunchToken;
            waitfor(token, "DoneWaiting", true);

            % Error if the Desktop or Figure/Desktop infrastructure failed to load within the timeout.
            if ~token.Loaded
                error(message("MATLAB:Figure:FigureInfrastructureNotLoaded"));
            end

            % Create Desktop Figure
            platformHost = @matlab.ui.internal.controller.platformhost.DivFigurePlatformHost;

        end % getPlatformHostClass()

    end % private methods

end
