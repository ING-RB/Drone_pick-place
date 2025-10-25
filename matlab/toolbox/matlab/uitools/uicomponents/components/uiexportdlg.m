function varargout = uiexportdlg(varargin)
    %UIEXPORTDLG Figure Export Dialog
    %  UIEXPORTDLG launches a dialog to export the current figure
    %
    %  UIEXPORTDLG(FIG) creates a modal dialog box from which the figure
    %  window, FIG, can be exported.
    %
    %  See also: UIPRINTDLG

    %  Copyright 2022-2024 The MathWorks, Inc.
    
    % Check if supported in execution context
    matlab.ui.internal.utils.validateModalDialogsCapability();

    narginchk(0,1);

    % Check varargin
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
    
    exportDialogHandle = matlab.ui.internal.dialog.DialogHelper.setupExportDialogController();
    if isequal(exportDialogHandle, @matlab.ui.internal.dialog.ExportDialog)
        nargoutchk(0,0);
        exportDialogHandle(fig);
    else
        % Provide special handling of output argument
        varargout{1} = exportDialogHandle(fig);
    end

end
