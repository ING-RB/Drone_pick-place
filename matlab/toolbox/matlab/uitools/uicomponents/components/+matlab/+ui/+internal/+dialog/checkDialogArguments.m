function fig = checkDialogArguments(fig)
    % checkDialogArguments Helper function to check passed arguments in
    % uiprintdlg/uiexportdlg
    %

    %  Copyright 2022-2023 The MathWorks, Inc.
    
    % Throws error if in -nojvm mode. 
    % Does not error for -nodisplay and -noFigureWindows modes
    matlab.ui.internal.utils.checkJVMError;
    
    % If there is no figure passed in, check to see if there is an already
    % existing figure object.
    if nargin == 0
        if (size(groot().CurrentFigure) == 0)
            ME = MException(message('MATLAB:uitools:uidialogs:NoArguments'));
            throwAsCaller(ME);
        else
            fig = gcf;
        end
    end
    
    % Check to see if the object is a figure class
    if ~isa(fig,'matlab.ui.Figure')
        ME = MException(message('MATLAB:uitools:uidialogs:InvalidClass'));
        throwAsCaller(ME);
    end
    
    % Check to see if the figure handle is valid
    if ~ishghandle(fig,'figure')
      ME = MException(message('MATLAB:uitools:uidialogs:InvalidOrDeletedFigure'));
      throwAsCaller(ME);
    end
    
    % The figure and uifigure are same class 'matlab.ui.Figure'. The following
    % check makes sure it's web-enabled. This is really just a sanity check
    % since the dialogs will be available in a release that does not have
    % Java-based figures available.
    if ~matlab.ui.internal.isUIFigure(fig)
        ME = MException(message('MATLAB:ui:uifigure:UnsupportedAppDesignerFunctionality', ...
            'figure'));
        throwAsCaller(ME);
    end
end
