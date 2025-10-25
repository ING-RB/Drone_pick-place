function outputStruct = handleWebAppsFileIODialog(uigetputtype, dialog_filter, dialog_title, dialog_filename, dialog_pathname, dialog_multiselect)
%handleWebAppsFileIODialog creates file IO dialog in deployed web environment.
% uigetputtype - To identify uigetfile/uiputfile
% dialog_filter - Filters for file IO dialog
% dialog_title - Title for file IO dialog
% dialog_filename - FileName for file IO dialog
% dialog_pathname - PathName for file IO dialog
% dialog_multiselect - To enable/disable file multiselection
%
% outputStruct - Structure containing fileName, pathName, filterIndex and filterValue.

% Copyright 2018-2025 The MathWorks, Inc.

% get current uifigure
params.Figure = matlab.ui.internal.dialog.FileDialogHelper.getUIFigure();

% get figureID
[~, figureID] = matlab.ui.internal.dialog.DialogHelper.validateUIfigure(params.Figure);
params.FigureID = figureID;

% assign action based on the uigetputtype
if(uigetputtype == 0)
    params.Action = 'displayFileInputDialog';
else
    params.Action = 'displayFileOutputDialog';
end

% construct filter struct with value and description
initial_dialog_filter = matlab.ui.internal.dialog.FileDialogHelper.getFileExtensionFilters(dialog_filter, uigetputtype);
dialog_filter = fillEmptyFilterDescriptions(initial_dialog_filter);

% construct param structure
params.Title = dialog_title;
params.Filter = dialog_filter;
params.FileName = dialog_filename;
params.PathName = dialog_pathname;
params.MultiSelection = dialog_multiselect;
params.Theme = params.Figure.Theme;

% setup FileIO controller
fileIODialogController = matlab.ui.internal.dialog.FileDialogHelper.setupFileIODialogController();
controller = fileIODialogController(params);

% call show() after creating and initializing controller
controller.show();

% block MATLAB until fileName is updated
waitfor(controller,'FileName');

% return filename, pathanme and filter back
outputStruct.FileName = controller.FileName;
outputStruct.PathName = controller.PathName;
outputStruct.FilterIndex = controller.FilterIndex;
outputStruct.FileFilter = dialog_filter.FilterValue;
end

function final_dialog_filter = fillEmptyFilterDescriptions(initial_dialog_filter)
% FILLEMPTYFILTERDESCRIPTIONS update the FilterDescription property so that
% empty strings have a default description
    final_dialog_filter = initial_dialog_filter;
    % Iterate through the FilterDescription array. If a certain entry is
    % empty, fill it in with a default description
    for i = 1:length(initial_dialog_filter.FilterDescription)
        if isempty(initial_dialog_filter.FilterDescription{i})
            final_dialog_filter.FilterDescription{i} = ['(' initial_dialog_filter.FilterValue{i} ')'];
        end
    end
end