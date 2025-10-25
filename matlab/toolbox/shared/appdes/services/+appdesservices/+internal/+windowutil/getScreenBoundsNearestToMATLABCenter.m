function screenBounds = getScreenBoundsNearestToMATLABCenter()
    %GETSCREENBOUNDSNEARESTTOMATLABCENTER Get screen available bounds where MATLAB window stays,
    % taking into account OS decorations such as the system's task bar
    % Return [x y width height] - left-upper corner based bounds

    %    Copyright 2017 The MathWorks, Inc.
    
    try
        matlabMainFrame = com.mathworks.mde.desk.MLDesktop.getInstance().getMainFrame();
        matlabMainFrameBounds = matlabMainFrame.getBounds();
        matlabMainFrameCenterScreenPoint = java.awt.Point(matlabMainFrameBounds.x + matlabMainFrameBounds.width/2, matlabMainFrameBounds.y + matlabMainFrameBounds.height/2);
        screenBounds = com.mathworks.mwswing.WindowUtils.getScreenBoundsWithOrNearestToPoint(matlabMainFrameCenterScreenPoint);
    catch me
        % If can't get the MATLAB main frame, return the primary screen
        % bounds, which happens in BaT or no ui for MATLAB
        screenBounds = com.mathworks.mwswing.WindowUtils.getScreenBounds();
    end
    
    % Return MATLAB style screen bounds
    screenBounds = [screenBounds.x screenBounds.y screenBounds.width screenBounds.height];
end