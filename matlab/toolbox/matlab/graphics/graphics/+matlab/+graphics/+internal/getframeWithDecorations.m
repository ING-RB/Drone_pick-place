function X = getframeWithDecorations(f, withDecorations, doDrawnow)
% GETFRAMEWITHDECORATIONS(f) Capture the whole figure including window decorations.
% GETFRAMEWITHDECORATIONS(f, withDecorations) Capture the whole figure, including decorations if the flag is true

% Copyright 1984-2021 The MathWorks, Inc.
    
    if nargin < 2
        withDecorations = true;
    end

    if nargin < 3
       doDrawnow = true;
    end

    % some clients may have done preemptive drawnow on their own
    % avoiding calls here may save a little time 
    if doDrawnow
       drawnow
       drawnow
    end

    if ~isgraphics(f, 'figure')
        error(message('MATLAB:capturescreen:FigureWindowRequired'));
    end

    if matlab.ui.internal.isUIFigure(f)
        cdata = getWebFigureWithDecorations(f, withDecorations);
    else
        cdata = getJavaFrameWithDecorations(f, withDecorations);
    end

    % Need to initialize fields in this order
    X.cdata = cdata;
    X.colormap = [];
end

function cdata = getWebFigureWithDecorations(f, includeFigureToolbars)
    if ~matlab.graphics.internal.export.isAppCaptureSupported()
        m = message('MATLAB:print:AppCaptureAndExportNotSupported');
        throwAsCaller(MException(m.Identifier, m.getString));
    end
    % Turn visible in certain scenarios in order to make dom available
    cleanup = makeDockedFigVisible(f);

    % Export using dom-snapshot-utils
    base64Image = matlab.ui.internal.FigureImageCaptureService.exportToPngBase64(f, includeFigureToolbars);
    clear cleanup;
    imageBytes = matlab.net.base64decode(base64Image);
    cdata = matlab.graphics.internal.convertImageBytesToCData(imageBytes);
end

function cdata = getJavaFrameWithDecorations(f, withDecorations)
    jf = matlab.graphics.internal.getFigureJavaFrame(f);
    if isempty(jf)
       % input was not valid
       error(message('MATLAB:capturescreen:FigureWindowRequired'));
    end
    c = jf.getAxisComponent();

    try
        cdata = getFrameImage(c, withDecorations);
        if isempty(cdata)
            % Try again, one time
            opts.fig = f;
            opts.Visible = get(f, 'Visible');
            cleanupHandler = onCleanup(@() doCleanup(opts));
            set(f,'Visible','on')
            drawnow
            drawnow
            cdata = getFrameImage(c, withDecorations);
        end
    catch e
        matlab.graphics.internal.processPrintingError(e);
        rethrow(e);
    end
end

function cleanup = makeDockedFigVisible(f)
    % Make JSD invisible docked figures visible for export
    % This will ensure there is an html dom present during export
    cleanup = [];
    if feature('webui') && ...
        strcmp(get(f,'Visible'),'off') && ...
        strcmp(get(f, 'WindowStyle'),'docked')
        
        set(f, 'Visible_I', 'on');
        drawnow;
    
        cleanup = onCleanup(@()makeDockedFigVisibleCleanup(f));
    end
end

function makeDockedFigVisibleCleanup(f)
    set(f, 'Visible_I', 'off');
    drawnow;
end

%===============================================================================
function doCleanup(opts)
    set(opts.fig, 'Visible', opts.Visible);
    drawnow;
end

% LocalWords:  recalc yoffset
