function setJavaDesktopEnabled(isEnabled)
    % MATLAB API to enable/disable interaction with the 
    % Java Desktop Main Window
    % isEnabled (1,1) logical;
 
    com.mathworks.mde.desk.MLDesktop.getInstance().getMainFrame().setEnabled(isEnabled);
end