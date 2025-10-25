function varargout = print( varargin )
%   PRINT Print or save a figure or model.
%     A subset of the available options is presented below.
%
%     PRINT, by itself, prints the current figure to your default printer.
%     Use the -s option to print the current model instead of the current figure.
%       print         % print the current figure to the default printer
%       print -s      % print the current model to the default printer
%
%     PRINT(filename, formattype) saves the current figure to a file in the
%     specified format. Vector graphics, such as PDF ('-dpdf'), and encapsulated
%     PostScript ('-depsc'), as well as images such as JPEG ('-djpeg') and PNG ('-dpng')
%     can be created. Use '-d' to specify the formattype option
%       print(fig, '-dpdf', 'myfigure.pdf'); % save to the 'myfigure.pdf' file
%
%     PRINT(printer, ...) prints the figure or model to the specified printer.
%     Use '-P' to specify the printer option.
%       print(fig, '-Pmyprinter'); % print to the printer named 'myprinter'
%
%     PRINT(resize,...) resizes the figure to fit the page when printing.
%     The resize options are valid only for figures, and only for page
%     formats (PDF, and PS) and printers. Specify resize as either
%       '-bestfit'  to preserve the figure's aspect ratio
%       '-fillpage' to ignore the aspect ratio.
%       '-noresize' to not resize
%
%   See also SAVEAS, PRINTPREVIEW, SAVEFIG, EXPORTGRAPHICS, COPYGRAPHICS.

%   Copyright 1984-2025 The MathWorks, Inc.

drawnow; % give changes a chance to be processed

[pj, inputargs] = LocalCreatePrintJob(varargin{:});

%Check the input arguments and flesh out settings of PrintJob
[pj, devices, options ] = inputcheck( pj, inputargs{:} );

% Process printing operation for simulink figure
if handleSimulinkPrinting(pj)
    return
end

%User can find out what devices and options are supported by
%asking for output and giving just the input argument '-d'.
%Do it here rather then inputcheck so stack trace makes more sense.
if strcmp( pj.Driver, '-d' )
    if nargout == 0
        disp(getString(message('MATLAB:uistring:print:SupportedDevices')))
        for i=1:length(devices)
            disp(['    -d' devices{i}])
        end
    else
        varargout{1} = devices;
        varargout{2} = options;
    end
    %Don't actually print anything if user is inquiring.
    return
end

%Validate that PrintJob state is ok, that input arguments
%and defaults work together.
pj = validate( pj );

%Handle missing or illegal filename.
%Save possible name first for potential use in later warning.
pj = matlab.graphics.internal.name( pj );

%Sometimes need help tracking down problems...
if pj.DebugMode
    disp(getString(message('MATLAB:uistring:print:PrintJobObject')))
    disp(pj)
end

if ~feature('webui')
    matlab.graphics.internal.prepareFigureForPrint(pj.Handles{1});
end
matlab.ui.internal.UnsupportedInUifigure(pj.Handles{1});

% Warn about InvertHardcopy support being removed, if necessary
msgID = matlab.graphics.internal.mlprintjob.invertHardcopyRemovalImpact(pj.Handles{1});
if ~isempty(msgID)
    warning(message(msgID));
end

%If handled via new path just return from here, otherwise fall through
pj = alternatePrintPath(pj);
if pj.donePrinting
    if pj.RGBImage
        varargout(1) = {pj.Return};
    end
    return;
end
end

% ------------------------- LOCAL FUNCTION --------------------------------

function [pj, varargin] = LocalCreatePrintJob(varargin)

import matlab.graphics.internal.*;
if ~nargin
    varargin = {};
end
varargin = convertStringToCharArgs(varargin);
handles = checkArgsForHandleToPrint(0, varargin{:});
pj = printjob([handles{:}]);
% update printjob to record current caller
pj.CallerFunc = 'print';
if ~pj.UseOriginalHGPrinting && ~isempty(varargin)
    for idx = 1:length(varargin)
        if isCharOrString(varargin{idx}) && strcmp('-printjob', varargin{idx}) && ...
                (idx+1) <= length(varargin)
            userSuppliedPJ = varargin{idx+1};
            pj = pj.updateFromPrintjob(userSuppliedPJ);
            varargin = {varargin{1:idx-1} varargin{idx+2:end}};
            break;
        end
    end
end
end

% [EOF]

% LocalWords:  fnames dpsc svdp vdp dps fn ps dwin dwinc dmeta Metafile dbitmap
% LocalWords:  dsetup deps depsc dhpgl HPGL djpeg nn dtiff packbits lossless
% LocalWords:  dtiffnocompression dpng truecolor online
% LocalWords:  dpcx PCX dppm Pixmap cmyk
% LocalWords:  adobecset Jpeg GL
