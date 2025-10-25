function commandhistory
    %COMMANDHISTORY Open Command History window, or select it if already open
    %   COMMANDHISTORY Opens the Command History window or focuses the Command
    %   History window if it is already open.
    
    %   Copyright 1984-2023 The MathWorks, Inc. 
    import matlab.internal.capability.Capability;

    % if MATLAB Online or JSD
    if ~Capability.isSupported(Capability.LocalClient) || (feature('webui') && desktop('-inuse'))
        try 
            rootApp = matlab.ui.container.internal.RootApp.getInstance();
            if rootApp.hasPanel('commandHistory') 
                chPanel = rootApp.getPanel('commandHistory');
                if ~chPanel.Opened
                    chPanel.Opened = true;
                end
                chPanel.Selected = true;
                rootApp.bringToFront();
            else
                propertyChangedListener = addlistener(rootApp, 'PropertyChanged', @(event,data) selectCommandHistoryPanel(data));
                s = settings;
                activeDisplayMode = s.matlab.desktop.commandhistory.DisplayModeJSD.ActiveValue;
                if strcmp(activeDisplayMode,'popup') || strcmp(activeDisplayMode,'dockedAndPopup')
                    s.matlab.desktop.commandhistory.DisplayModeJSD.TemporaryValue = 'dockedAndPopup';
                else
                    s.matlab.desktop.commandhistory.DisplayModeJSD.TemporaryValue = 'docked';
                end
            end
        catch err
            error(message('MATLAB:cmdhist:CmdHistFailed'))
        end
    
    elseif feature('webui') && ~desktop('-inuse') % In JSD mode but JSD is not yet running
            error(message('MATLAB:desktop:desktopNotFoundCommandFailure'));
    else
        error(javachk('swing', mfilename));
        
        try
            % Launch Command History window
            com.mathworks.mde.desk.MLDesktop.getInstance.showCommandHistory;
        catch
            error(message('MATLAB:cmdhist:CmdHistFailed'));
        end
    end
    
    function selectCommandHistoryPanel(data)
        if data.PropertyName=="PanelLayout"
            chPanel = rootApp.getPanel('commandHistory');
            if ~chPanel.Opened
                chPanel.Opened = true;
            end
            chPanel.Selected = true;
            rootApp.bringToFront();
            delete(propertyChangedListener);
        end
    end
end
    
    
    