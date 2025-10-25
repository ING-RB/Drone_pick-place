function exportGUIDEApp(varargin)
%EXPORTGUIDEAPP - Export a GUIDE App to a MATLAB File

%   This function is intentionally undocumented.
%   Its behavior may change, or it may be removed, in a future release.

% Copyright 2023 The MathWorks, Inc.

narginchk(0, 2)

if nargin == 0
    % If there were no input arguments, launch the GUIDEAppMaintenanceOptions
    % app such that there is no specified FIG file and the app opens to the
    % 'export' tab.
    guide.internal.launchGUIDEAppMaintenanceOptions([], 'export');
    return
end

validatedFullMFileName = [];
    
if nargin == 2
    % If there was two input arguments, the second input is file to which 
    % to save the exported app.
    inputtedMFileName = varargin{2};
    fileExtension = '.m';
    
    % Obtain the full absolute file path of the MATLAB File specified by
    % the user and validate the folder.
    validatedFullMFileName = appdesigner.internal.application.getValidatedFile(inputtedMFileName, fileExtension);
    
    appdesigner.internal.application.validateFolderForWrite(validatedFullMFileName);
end

inputtedFigFile = varargin{1};
originalDirectory = cd;

[figureHandle, figureVisibility] = prepareForExport(inputtedFigFile);

% Execute a cleanup function when the export finishes.
cleanupObj = onCleanup(@() cleanupFcn(figureHandle, originalDirectory));

% Export the GUIDE App with no specified target MATLAB File
showExportWarning = false;
[~, exportmfile] = guidefunc('export', figureHandle, validatedFullMFileName, showExportWarning, figureVisibility);


% log export info in ddux
if ~strcmp(exportmfile,'Cancelled')
    data = struct();
    data.guidefileName = inputtedFigFile;
    data.figure = figureHandle;
    data.exportmfileName = exportmfile;
    logExportAppInfo(data);
end
end

function cleanupFcn(figureHandle, originalDirectory)
% CLEANUPFCN - complete cleanup operations after export.

% Close the opened fig file on cleanup.
close(figureHandle);

% After export is complete, change the directory back to the original directory
cd(originalDirectory);

end

function [figureHandle, figureVisibility] = prepareForExport(figFile)
% PREPAREFOREXPORT - complete preparation for the export process.  This
% includes:
% 1. Validating input
% 2. Opening the FIG file as invisible and modifying the appdata in
% preparation for export.

% Step 1: Validate input
normalizedfullFileName = appdesigner.internal.application.validateGUIDEApp(figFile);

[filepath]=fileparts(normalizedfullFileName);

% To avoid openfig errors, cd into the directory of the fig file.
cd(filepath);

% Step 2: Figures must be open in order for the export to proceed.
figureHandle = openfig(normalizedfullFileName);
% Record the correct Visible property value then turn visibility off.  This
% ensures that the figure only 'flashes' on the screen, rather than being
% visible during the entire export process.
figureVisibility = figureHandle.Visible;
figureHandle.Visible = 'off';

% Set Fig File app data in order to avoid errors in guidefunc.
GUIDELayoutEditor = struct('isDirty', false, 'getFrame', false);
setappdata(figureHandle, 'GUIDELayoutEditor', GUIDELayoutEditor);

end


function logExportAppInfo(data)
    try
        dataToLog = struct();

        % guide fig Filename hash value
        digestBytes = matlab.internal.crypto.BasicDigester("DeprecatedSHA1");
        guideUint8Digest = digestBytes.computeDigest(data.guidefileName);
        guideFileNameHash = sprintf('%2.2x', double(guideUint8Digest));
        dataToLog.guideFileNameHash = guideFileNameHash;

        % guide fig Filename hash value
        exportMFileUint8Digest = digestBytes.computeDigest(data.exportmfileName);
        exportMFileNameHash = sprintf('%2.2x', double(exportMFileUint8Digest));
        dataToLog.exportMFileNameHash = exportMFileNameHash;

        % App's characteristics, numberOfComponents,
        componentsList = findall(data.figure, '-not', 'Type', 'AnnotationPane', '-not', 'Type', 'Text');
        dataToLog.numberOfComponents = num2str(numel(componentsList));

        sendDDUXData(dataToLog);
    catch
        % no-op. Catch exception to avoid breaking export tool
    end
end

function sendDDUXData(dataToLog)
    % send export info to ddux
    % prepare ddux Identification with all standard fields used for both main event and any additional events
    uiEventID = matlab.ddux.internal.UIEventIdentification( ...
        'MATLAB', ...                                   % Product
        'GUIDE to App Designer Migration Tool', ...     % Scope
        matlab.ddux.internal.EventType.OPENED, ...      % Event Type
        matlab.ddux.internal.ElementType.DOCUMENT, ...  % Element Type
        "GUIDEAppExporter" ...                          % Element ID
        );

    matlab.ddux.internal.logUIEvent(uiEventID, dataToLog);
end