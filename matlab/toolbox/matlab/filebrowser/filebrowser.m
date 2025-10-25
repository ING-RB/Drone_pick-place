function filebrowser
%   FILEBROWSER Open Current Folder browser, or select it if already open
%   FILEBROWSER Opens and focuses the Current Folder browser or focuses the Current
%   Folder browser if it is already open.

%   Copyright 1984-2023 The MathWorks, Inc.

    import matlab.internal.capability.Capability;

    % if MATLAB Online or JSD
    if ~Capability.isSupported(Capability.LocalClient) || (feature('webui') && desktop('-inuse'))
        try 
            rootApp = matlab.ui.container.internal.RootApp.getInstance();
            if rootApp.hasPanel('cfb')
                cfbPanel = rootApp.getPanel('cfb');
                setPanelProperties(cfbPanel);
            else
                % wait for panel to become available
                rootAppListener = addlistener(rootApp, 'PropertyChanged', @(event, data)handleRootAppPropertyChange(data));
            end
            
    
        catch
            error(message('MATLAB:filebrowser:filebrowserFailed'));
        end
    
    elseif feature('webui') && ~desktop('-inuse') % In JSD mode but JSD is not yet running
        error(message('MATLAB:desktop:desktopNotFoundCommandFailure'));
    else
        err = javachk('mwt', 'The Current Folder Browser');
        if ~isempty(err)
            error(err);
        end
    
        try
            % Launch the Current Folder Browser
            hDesktop = com.mathworks.mde.desk.MLDesktop.getInstance;
            adapter = javaObject('com.mathworks.mde.desk.DesktopExplorerAdapterImpl', hDesktop);
            %javaMethod('createInstance', 'com.mathworks.mde.explorer.Explorer', adapter);
            
            classLoader = java.lang.ClassLoader.getSystemClassLoader();
            explorerClass = java.lang.Class.forName('com.mathworks.mde.explorer.Explorer', 1, classLoader);
            adapterClass = java.lang.Class.forName('com.mathworks.explorer.DesktopExplorerAdapter', 1, classLoader);
            
            paramtypes = javaArray('java.lang.Class', 1);
            paramtypes(1) = adapterClass;
            
            method = explorerClass.getMethod(java.lang.String('createInstance'), paramtypes);
            arglist = javaArray('java.lang.Object', 1);
            arglist(1) = adapter;
            
            com.mathworks.mwswing.MJUtilities.invokeLater(explorerClass, method, arglist);
            
            com.mathworks.mde.explorer.Explorer.invoke;    
        catch
            % Failed. Bail
            error(message('MATLAB:filebrowser:filebrowserFailed'));
        end
    end

    function handleRootAppPropertyChange(data)
        if data.PropertyName=="PanelLayout"
            cfbPanel = rootApp.getPanel('cfb');
            setPanelProperties(cfbPanel);
            delete(rootAppListener)
        end
    end

    function setPanelProperties(hPanel)
        if ~hPanel.Opened
            hPanel.Opened = true;
        end
        hPanel.Selected = true;
        rootApp.bringToFront();
    end

end
