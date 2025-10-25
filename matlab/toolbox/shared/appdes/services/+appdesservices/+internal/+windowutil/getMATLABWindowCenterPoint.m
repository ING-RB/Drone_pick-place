function matlabCenterPoint = getMATLABWindowCenterPoint()
    % Get MATLAB Window cener point
    % Return as a pf.display.Point

    %    Copyright 2023 The MathWorks, Inc.
    
    try
        if appdesservices.internal.util.MATLABChecker.isJavaDesktop()
            matlabMainFrame = com.mathworks.mde.desk.MLDesktop.getInstance().getMainFrame();
            frameBounds = matlabMainFrame.getBounds();
            matlabMainFrameBounds = pf.display.DisplayRect();
            matlabMainFrameBounds.x = frameBounds.x;
            matlabMainFrameBounds.y = frameBounds.y;
            matlabMainFrameBounds.width = frameBounds.width;
            matlabMainFrameBounds.height = frameBounds.height;

        else
            previousWarning = warning('off', 'MATLAB:desktop:desktopNotFoundCommandFailure');
            cleanupObj = onCleanup(@()warning(previousWarning));
            rootApp = matlab.ui.container.internal.RootApp.getInstance();
            matlabMainFrameBounds = appdesservices.internal.windowutil.convertArrayToDisplayRect(rootApp.WindowBounds);
        end
    catch me
        % If can't get the MATLAB main frame, return the primary screen
        % bounds, which happens in BaT or no ui for MATLAB
        primaryScreenConfig = pf.display.getConfig(pf.display.getPrimaryScreen());
        matlabMainFrameBounds = primaryScreenConfig.availableScreenSize;
    end

    matlabCenterPoint = pf.display.Point();
    matlabCenterPoint.x = matlabMainFrameBounds.x + matlabMainFrameBounds.width/2;
    matlabCenterPoint.y = matlabMainFrameBounds.y + matlabMainFrameBounds.height/2;
end

