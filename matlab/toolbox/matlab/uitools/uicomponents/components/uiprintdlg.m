function varargout = uiprintdlg(varargin)
    %UIPRINTDLG  Print dialog box.
    %  UIPRINTDLG prints the current figure.
    %
    %  UIPRINTDLG(FIG) creates a modal dialog box from which the figure
    %  window, FIG, can be printed. Note that UI components do not print.
    %
    %  See also: PRINTPREVIEW
    
    %  Copyright 2022-2024 The MathWorks, Inc.

    % Check if supported in execution context
    matlab.ui.internal.utils.validateModalDialogsCapability();

    % Check arguments
    narginchk(0,1);
    
    % Check that the input is valid
    if nargin == 0
        fig = matlab.ui.internal.dialog.checkDialogArguments();
    else
        fig = varargin{1};
        matlab.ui.internal.dialog.checkDialogArguments(fig);
    end

    matlab.ui.internal.UnsupportedInUifigure(fig);
    
    % Do a last minute sanity check on whether the figure is being closed
    if fig.BeingDeleted==1 || ~ishandle(fig)
        error(message('MATLAB:uitools:uidialogs:InvalidOrDeletedFigure'));
    end
    
    % If the figure has UI components, display a print error message
    if matlab.graphics.internal.mlprintjob.containsUIElements(fig)
        error(message('MATLAB:uitools:uidialogs:PrintUIComponents'));
    end

    printDialogHandle = matlab.ui.internal.dialog.DialogHelper.setupPrintDialogController();
    if isequal(printDialogHandle, @matlab.ui.internal.dialog.PrintDialog)
        nargoutchk(0,0);
        printDialogHandle(fig);
    else
        % Provide special handling of output argument
        varargout{1} = printDialogHandle(fig);
    end

end