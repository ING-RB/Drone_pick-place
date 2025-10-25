classdef PublishFigures < internal.matlab.publish.PublishExtension
%

% Copyright 1984-2014 The MathWorks, Inc.

    properties
        savedState = [];
        plugins = [];
    end
    
    properties (Constant)
        publishGeneratedFigure = 'MW_PublishGeneratedFigure';
    end

    methods
        
        function obj = PublishFigures(options)
            obj = obj@internal.matlab.publish.PublishExtension(options);            
            n = 0;
            
            n = n + 1;
            obj.plugins(n).check = @(f)( ...
                ~isempty(license('inuse','virtual_reality_toolbox')) && ...
                ~isempty(which('vr.figure')) && ...
                ~isempty(vr.figure.fromHGFigure(f)));
            obj.plugins(n).classname = 'internal.matlab.publish.PublishSimulink3DAnimationViewers';
            obj.plugins(n).instance = [];
            
            n = n + 1;
            obj.plugins(n).check = @(f)isa(get(f,'UserData'),'Aero.Animation');
            obj.plugins(n).classname = 'internal.aero.publish.PublishAeroAnimationFigures';
            obj.plugins(n).instance = [];

            n = n + 1;
            obj.plugins(n).check = @(f)strcmp(get(f,'Tag'),'spcui_scope_framework');
            obj.plugins(n).classname = 'internal.scopes.publish.PublishScopes';
            obj.plugins(n).instance = [];
            
            n = n + 1;
            obj.plugins(n).check = @usePublishUIFigures;
            obj.plugins(n).classname = 'internal.matlab.publish.PublishUIFigures';
            obj.plugins(n).instance = [];
                       
            obj.savedState = internal.matlab.publish.captureFigures;
        end
        
        function enteringCell(obj,~)
            obj.savedState = internal.matlab.publish.captureFigures;
        end
        
        function imgFilename = snap(obj, f)
            % Check to see if this is a special type of figure.
            for i = 1:numel(obj.plugins)
                handled = false;
                if obj.plugins(i).check(f) && ...
                        exist(obj.plugins(i).classname,'class') == 8
                    if isempty(obj.plugins(i).instance)
                        obj.plugins(i).instance = feval(obj.plugins(i).classname,obj.options);
                    end
                    imgFilename = obj.plugins(i).instance.snapFigure(f,obj.options.filenameGenerator(),obj.options);
                    handled = true;
                    break
                end
            end

            % Handle regular figures.
            if ~handled
                imgFilename = obj.snapFigure(f,obj.options.filenameGenerator(),obj.options);
            end
        end
        
        function newFiles = leavingCell(obj,~)
            % Before doing anything else, especially DRAWNOW, get the
            % figure order.
            figuresOriginal = allchild(0);
            % Save the back up of the original figures(without fvtools figures
            % as it is not applicable to it) so that it can be
            % used to restore original order at the end
            figuresOriginalBackup = figuresOriginal;
            % Get the list of fvtools figures
            % TODO: Logic to get figure handles in all App containers
            figuresOriginal = mergeFvtoolFigures(figuresOriginal, false);
          
            % Determine which figures need a snapshot.
            newFigures = internal.matlab.publish.captureFigures;
            figuresToSnap = internal.matlab.publish.compareFigures(obj.savedState, newFigures);
            
            % Use the original order, just in case they have been moved
            % about by the operating system during DRAWNOWs.
            missingFigures = setdiff(figuresToSnap,figuresOriginal)';
            isSnapped = ismember(figuresOriginal,figuresToSnap);
            figuresToSnap = flipud(figuresOriginal(isSnapped));
            figuresToSnap = [figuresToSnap; missingFigures];
            
            % Take a snapshot of the each figure that needs it.
            % Ensure that for figures docked to a
            % matlabshared.scopes.Container, only one snapshot is taken per
            % container when leaving the cell.
            newFiles = cell(size(figuresToSnap));
            figContainersSnapped = cell(size(figuresToSnap));
            for figuresToSnapCount = 1:numel(figuresToSnap)
                f = figuresToSnap(figuresToSnapCount);

                % Displaying axes toolbar during publish could dirty an image
                % and generate duplicate snapshots of the figure.
                % Set MW_PublishGeneratedFigure dynamic property on the figure to disable the axes
                % toolbar.
                if ~isprop(f, obj.publishGeneratedFigure)
                    addprop(f, obj.publishGeneratedFigure);
                end

                isDocked = strcmpi(f.WindowStyle,'docked') && ~strcmpi(f.Tag, 'filtervisualizationtool');
                grpName = '';
                % Applicable only for Tool group and Java Desktop
                if ~internal.matlab.publish.isJavaScriptDesktop()
                    if isDocked
                        % Determine the group name
                        [lastWarnMsg,lastWarnId] = lastwarn;
                        warnstate = warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
                        jf = matlab.ui.internal.JavaMigrationTools.suppressedJavaFrame(f);
                        warning(warnstate); % Restore the original warning state
                        % restore the last warning thrown
                        lastwarn(lastWarnMsg, lastWarnId);
                        if ~isempty(jf)
                            grpName = char(jf.getGroupName);
                        end
                    end
                end
                
                % Do not snap if the figure is inside a snapshottable or we have already snapped the group/container to which the figure belongs.
                if isSnapFigure(f,isDocked,grpName,figContainersSnapped)
                    imgFilename = snap(obj, f);
                    % Applicable only for Tool group and Java Desktop
                    if isDocked && ~internal.matlab.publish.isJavaScriptDesktop()
                        if ~ismember(grpName, internal.matlab.publish.PublishFigures.setgetContainerNames)
                            % Add the group/container name that was snapped
                            % to stored list of known containers
                            internal.matlab.publish.PublishFigures.setgetContainerNames(grpName);
                        end
                        % Add the group/container name that was snapped to 
                        % list of containers that are being snapped for
                        % this cell
                        figContainersSnapped{figuresToSnapCount} = grpName;
                    end
                    
                     % Add to list of figures.
                     newFiles{figuresToSnapCount} = imgFilename;
                end               

            end
            
            % Remove empty filename as it will error with fileparts call to
            % determine the file extension and result in empty file
            % references.
            newFiles(cellfun('isempty',newFiles)) = [];
            
            % Update SNAPNOW's view of the current state of figures.
            % Since the process of printing can change certain properties,
            % recapture figures to prevent extra snaps.
            obj.savedState = internal.matlab.publish.captureFigures;

            % Restore the figures to the original order, in case printing
            % or something else jostled them.
            try
                % Use ishandle to ignore figures which have closed.
                set(0,'children',figuresOriginalBackup(ishandle(figuresOriginalBackup)));
            catch e
                if strcmp(e.identifier,'MATLAB:hg:g_object:BadChildren')
                    warning(e.identifier,'%s',e.message)
                else
                    rethrow(e)
                end
            end
        end
        
    end
    
    methods(Static)

        function imgFilename = snapFigure(f,imgNoExt,opts)
            if internal.matlab.publish.isJavaScriptDesktop()
                method = opts.figureSnapMethod;
                if matches(method, ["entireGUIWindow","print"])
                    method = 'getframe';
                    % 'print' only supports exporting figures with HandleVisibility 'on'.
                    % getframe will be used for snapping web figures
                    % with UI elements since print doesn't support it.
                    if strcmp(get(f,'HandleVisibility'),'on') && ~matlab.graphics.internal.mlprintjob.containsUIElements(f)
                        method = 'print';
                    end
                end
            else
                % Nail down the figure snap method.
                method = opts.figureSnapMethod;
                if strcmp(method, 'entireGUIWindow')
                    % If we only want to capture the whole window for GUIs, use
                    % HandleVisibility to determine what is a GUI and what isn't.
                    method = 'print';
                    if ~strcmp(get(f,'HandleVisibility'),'on')
                        method = 'getframe';
                    end
                end
            end
            % Nail down the image format.
            if isempty(opts.imageFormat)
                imageFormat = internal.matlab.publish.getDefaultImageFormat(opts.format,method);
            else
                imageFormat = opts.imageFormat;
            end
            
            % Nail down the image filename.
            imgFilename = internal.matlab.publish.getPrintOutputFilename(imgNoExt,imageFormat);
            
            % Dispatch.
            switch method
                case {'print','getframe','antialiased'}
                    feval([method 'Snap'],f,imgFilename,imageFormat,opts);
                otherwise
                    % We should never get here.
                    error(message('MATLAB:takepicture:NoMethod', method))
            end
        end

    end
    
    methods(Static,Hidden)
        
        function output = setgetContainerNames(newContainerName)
            % Save the names of the containers that should be snapped only
            % once by publish when leaving the cell.
            persistent containerNamesSet;
            if isempty(containerNamesSet)
                containerNamesSet = {'Scopes'};
            end
            output = containerNamesSet;
            if nargin > 0
                if ~strcmpi(newContainerName,'Figures') && ~ismember(newContainerName,containerNamesSet)
                    containerNamesSet{end+1} = newContainerName;
                end
            end
        end

        function output = isSnapshottable(fig)
            % If an uifigure/figure is inside a snapshottable container, InsideUnsnapshottable hidden property will be set
            % for it. So, it should be snapshot only by the matlab.ui.internal.PublishSnapshottable plugin
            % and not by figure snapshot plugins to avoid creation of duplicate snapshots.
            output = ~fig.isprop('InsideUnsnapshottable');
        end
        
    end
    
end

%===============================================================================
function getframeSnap(f,imgFilename,imageFormat,opts) %#ok<DEFNU> Dynamically dispatched from snapFigure.
comment = getDebugCommentForImage(f);

% Make sure the 'FigureViewReady' property is set before proceeding to export the figure
internal.matlab.publish.makeFigureViewReady(f);

myFrame = snapIt(f,{});

% Finally, write out the image file.
internal.matlab.publish.resizeIfNecessary(imgFilename,imageFormat,opts.maxWidth,opts.maxHeight,myFrame,comment);

end

%===============================================================================
function printSnap(f,imgFilename,imageFormat,opts) % Dynamically dispatched from snapFigure.
comment = getDebugCommentForImage(f);

% Reconfigure the figure for better printing.
origPaperPosition = get(f,'PaperPosition');
params = {'PaperOrientation','Units','PaperPositionMode'};
tempValues = {'portrait','pixels','auto'};
origValues = get(f,params);
set(f,params,tempValues);
resetFigureObj = onCleanup(@()restoreFigure(f, origPaperPosition, params, origValues));
    function restoreFigure(f, origPaperPosition, params, origValues)
        set(f,'PaperPosition',origPaperPosition);
        set(f,params,origValues);
    end

imWidth = opts.maxWidth;
imHeight = opts.maxHeight;
scale = internal.matlab.publish.getImageScale();

% Print a normal figure.
printOptions = {['-d' imageFormat]};
switch imageFormat
    case internal.matlab.publish.getVectorFormats()
        % Use the default resolution.
    otherwise
        screenRes = 0;
        % check if screen is high dpi
        if scale > 1           
            screenRes = get(0, 'ScreenPixelsPerInch');
        end    
        printOptions{end+1} = sprintf('-r%d', screenRes);
end
try
    % Disables deprecation warning for printing with ui components
    cl_ui = matlab.graphics.internal.export.disableWarningInScope( ...
        'MATLAB:print:ExcludesUIInFutureRelease');
    cl_img = matlab.graphics.internal.export.disableWarningInScope( ...
        'MATLAB:print:RasterNotSupportedInFutureRelease');
    figureDefaultColorWarning = matlab.graphics.internal.export.disableWarningInScope( ...
        'MATLAB:print:InvertHardcopyIgnoredDefaultColorUsed');
    figureColorUsedWarning = matlab.graphics.internal.export.disableWarningInScope( ...
        'MATLAB:print:InvertHardcopyIgnoredFigureColorUsed');
   % Disable axes toolbar warning displayed sporadically
    axesToolbarWarning = matlab.graphics.internal.export.disableWarningInScope( ...
        'MATLAB:graphics:axestoolbar:PrintWarning');
    print(f,printOptions{:},imgFilename);
catch printExc
    if isequal(printExc.identifier,'MATLAB:print:FrameBuffer')
        warning(message(printExc.identifier))
    else
        [fileAttribMsg,checkedFilename] = checkFilePermission(imgFilename);
        fileExc = MException(pm('CannotWriteImage',checkedFilename,fileAttribMsg));
        newExc = addCause(fileExc,printExc);
        throw(newExc);
    end
end

    if ~isfield(opts,'format') || ~strcmp(opts.format,'latex')
        if scale == 1
            internal.matlab.publish.resizeIfNecessary(imgFilename,imageFormat,imWidth,imHeight,[],comment);
        else
            [frame.cdata, frame.colormap] = imread(imgFilename);
            internal.matlab.publish.writeImage(imgFilename,imageFormat,frame,imHeight,imWidth,comment);
        end
    end
end

%===============================================================================
function [diagMsg,checkedName] = checkFilePermission(filename)

[stat,msg] = fileattrib(filename);
if (stat == 1)
    % File exists, check permissions
    F = fieldnames(msg);
    diagMsg = '';
    for n = 1:(numel(F))
        field = F{n};
        % Skip Name        
        if (strcmp(field,'Name'))
            continue;
        else
            diagMsg = sprintf('%s\n  %s:%d',diagMsg,field,msg.(field));
        end
    end    
    checkedName = filename;
else
    % File does not exist, check directory
    [diagMsg,checkedName] = checkFilePermission(fileparts(filename));
end
end

%===============================================================================
function m = pm(id,varargin)
m = message(['MATLAB:publish:' id],varargin{:});
end

%===============================================================================
% PublishUIFigures plugin should be used only in Java Desktop for snapping
% uifigures. All the figures are ui(web) figures in JavaScript Desktop, so this
% plugin will always return true in JavaScript Desktop. So this check is needed 
% to avoid snapping every figure with this plugin in JavaScript Desktop.
function usePlugin = usePublishUIFigures(f)
usePlugin = ~internal.matlab.publish.isJavaScriptDesktop() && matlab.ui.internal.isUIFigure(f);
end

%===============================================================================
function snap = isSnapFigure(f,isDocked,grpName,figContainersSnapped)
snap = internal.matlab.publish.PublishFigures.isSnapshottable(f);
if ~internal.matlab.publish.isJavaScriptDesktop
    snap = snap && (~isDocked || (isDocked && ~any(strcmpi(figContainersSnapped,grpName))));
end
end
