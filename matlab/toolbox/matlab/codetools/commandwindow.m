function commandwindow
    %COMMANDWINDOW Open Command Window, or select it if already open
    %   COMMANDWINDOW Opens and focuses the Command Window or focuses the Command Window
    %   if it is already open.
    %
    %   See also DESKTOP.
    
    %   Copyright 1984-2025 The MathWorks, Inc.
    import matlab.internal.capability.Capability;

    % if MATLAB Online or JSD
    if ~Capability.isSupported(Capability.LocalClient) || (feature('webui') && desktop('-inuse'))
        try
            rootApp = matlab.ui.container.internal.RootApp.getInstance();
            rootApp.selectTool('commandWindow');
            commandWindowDocument = rootApp.getDocument('commandWindow', 'Command Window');

            if (isempty(commandWindowDocument) || commandWindowDocument.Docked)
                rootApp.bringToFront();
            end
        catch
            error(message('MATLAB:commandwindow:commandWindowFailed'));
        end
    elseif feature('webui') && ~desktop('-inuse') % In JSD mode but JSD is not yet running
            error(message('MATLAB:desktop:desktopNotFoundCommandFailure'));
    else
        try
            % Launch Java Command Window
            if usejava('desktop') %desktop mode
                % This means we are running the desktop so bring up MDE Java Command Window
                com.mathworks.mde.desk.MLDesktop.getInstance.showCommandWindow;    
            end
        catch
            % Failed. Bail
            error(message('MATLAB:commandwindow:commandWindowFailed'));
        end
    end
end
