function hgrc
    %HGRC Startup file for MATLAB graphics.
    %   HGRC is automatically executed by MATLAB during startup.
    %   It establishes the default figure size and sets a few uicontrol defaults.
    %
    %	On multi-user or networked systems, the system manager can put
    %	any messages, definitions, etc. that apply to all users here.
    %
    %   HGRC also invokes a STARTUPHG command if the file 'startupHG.m'
    %   exists on the MATLAB path.
    
    %   Copyright 1984-2024 The MathWorks, Inc.
    try
        if ~feature('webui')
            set(groot, 'DefaultFigureMenuBar','figure');
        end
        % Set the default figure position, in pixels.
        % On small screens, make figure smaller, with same aspect ratio.
        % Determine the width and height of the primary screen
        screen = get(groot, 'ScreenSize');
        width = screen(3) - screen(1);
        height = screen(4) - screen(2);

        if any(screen(3:4) ~= 1)  % don't change default if screensize == [1 1]
            margin = 200;
    
            % Calculate default Figure size
            if feature('FigureContainerDefault') && feature('webui')

                if feature('HasDisplay') && ~feature('NoFigureWindows') && matlab.ui.internal.isDesktopAvailable()
                    % Only set DefaultFigureWindowStyle to docked if we
                    % have a display, are not in NoFigureWindows mode, and
                    % the desktop is available.
                    %
                    % Docked Figures are not supported in nodisplay modes,
                    % the NoFigureWindows mode, or in cases where no
                    % desktop is available.
                    set(groot,'DefaultFigureWindowStyle','docked');
                end

                shouldScale = ~ismac;
    
                if(width > height)
                    mwheight = .6 * height;
                    mwheight = min(mwheight, 840);
                    mwwidth = mwheight*1.66;
                else
                    % For vertical monitors, we will use up to 90% of the
                    % width
                    mwwidth = .9 * width;
                    % Cap the size proportionally to the 840 height cap for
                    % horizontal monitors.  Proportional width cap for 1.66
                    % aspect ratio for height of 840 is 1394.
                    mwwidth = min(mwwidth, floor(840*1.66));
                    mwheight = mwwidth / 1.66;
                end
                
                propInspMargin = 320;
                if shouldScale
                    scaling = max(1, get(groot,'screenpixelsperinch')/96);
                    mwwidth = mwwidth * scaling;
                    mwheight = mwheight * scaling;
                    margin = margin * scaling;
                    propInspMargin = propInspMargin * scaling;
                end

                % If there is not enough margin to allow the property
                % inspector to fit...
                if((width - mwwidth) < propInspMargin)
                    % ...then calculate how much we are short
                    missingMargin = propInspMargin - (width - mwwidth);
                    % ...and modify width to allow for prop inspector to
                    % fit
                    mwwidth = mwwidth - missingMargin;
                    mwheight = mwwidth / 1.66;
                end
                
                left = screen(1) + (width - mwwidth)/2;
                if(width > height)                    
                    bottom = height - mwheight - margin - screen(2);
                else
                    % for vertical monitors, center the Figure in the
                    % monitor
                    bottom = height - mwheight - (height - mwheight)/2;
                end
    
                % round off to the closest integer.
                left = floor(left); bottom = floor(bottom);
                mwwidth = floor(mwwidth); mwheight = floor(mwheight);
    
                rect = [ left bottom mwwidth mwheight ];
            else            
                rect = calculateLegacyDefaultFigurePosition(screen, width, height, margin);
            end
    
            % Set default size for Data Exploration Figures
            set(groot, 'DefaultFigurePosition',rect);

            % Set default size for uifigures
            if feature('FigureContainerDefault') && feature('webui')
                matlab.ui.internal.setUiFigureDefaultPosition(calculateLegacyDefaultFigurePosition(screen, width, height, margin));
            else
                % use the same size as the data exploration Figure
                matlab.ui.internal.setUiFigureDefaultPosition(get(groot, 'DefaultFigurePosition'));
            end
        end
        
        %% Set the default PaperPositionMode
        pposModePref = 'auto';
        % look for preference setting
        %   set via matlab.graphics.internal.setPrintPreferences('DefaultPaperPositionMode', mode);
        %      where   mode   is a string containing either 'auto' or 'manual'
        if exist('ispref','file') && ispref('FigurePrinting', 'DefaultPaperPositionMode')
            prefs = getpref('FigurePrinting');
            if isfield(prefs, 'DefaultPaperPositionMode')
                theMode = prefs.DefaultPaperPositionMode;
            else
                theMode = [];
            end
            if ischar(theMode) && any(strcmp(theMode, {'auto', 'manual'}))
                pposModePref = theMode;
            end
        end
        set(groot,'DefaultFigurePaperPositionMode', pposModePref);
        
        % MATLAB versions prior to R2015b used 'manual' as the default
        % set(groot,'DefaultFigurePaperPositionMode', 'manual');
        
        
        %% Uncomment the next group of lines to make uicontrols, uimenus
        %% and lines look better on monochrome displays.
        %if get(groot,'ScreenDepth')==1,
        %   set(groot,'DefaultUIControlBackgroundColor','white');
        %   set(groot,'DefaultAxesLineStyleOrder','-|--|:|-.');
        %   set(groot,'DefaultAxesColorOrder',[0 0 0]);
        %   set(groot,'DefaultFigureColor',[1 1 1]);
        %end
        
        %% Uncomment the next line to use Letter paper and inches
        %defaultpaper = 'usletter'; defaultunits = 'inches'; defaultsize = [8.5 11.0];
        
        %% A4 paper size is 21.0 x 29.7
        a4Size = [21.0 29.7];
        
        %% Uncomment the next line to use A4 paper and centimeters
        %defaultpaper = 'A4'; defaultunits = 'centimeters'; defaultsize = a4Size;
        
        %% If neither of the above lines are uncommented then guess
        %% which papertype and paperunits to use based on ISO 3166-1 country code.
        
        % Possible locale output formats are xx-YY, xx-YY.foo, xx_YY, xx-yy,
        % xx-YY-ZZZZ, xx_YY_ZZZZ.foo and xx_YY.foo. We want to grab the
        % YY/yy country code, so we're parsing based off of '-' or '_'.
        localeString = matlab.internal.i18n.locale.default.LanguageTag;
        countryCode = extract(extractAfter(localeString, "-"|"_"), lineBoundary("start")+lettersPattern);
    
        % Compare the country code to the hard-coded list below
        if ~isempty(countryCode) && ~exist('defaultpaper','var') && ~any(strncmpi(countryCode, ...
                {'us', 'ca', 'cl', 'co', 'cr', 'mx', 'pa', 'gt', 'do', 'ph'},2))
            defaultpaper = 'A4';
            defaultunits = 'centimeters';
            defaultsize = a4Size;
        end
        
        %% Set the default if requested
        if exist('defaultpaper','var') && exist('defaultunits','var') && ...
                exist('defaultsize', 'var')
            % Handle Graphics defaults
            set(groot,'DefaultFigurePaperType', defaultpaper);
            set(groot,'DefaultFigurePaperUnits',defaultunits);
            set(groot,'DefaultFigurePaperSize', defaultsize);
        end
        
        %% CONTROL OVER FIGURE TOOLBARS:
        %% The new figure toolbars are visible when appropriate,
        %% by default, but that behavior is controllable
        %% by users.  By default, they're visible in figures
        %% whose MenuBar property is 'figure', when there are
        %% no uicontrols present in the figure.  This behavior
        %% is selected by the figure ToolBar property being
        %% set to its default value of 'auto'.
        
        %% to have toolbars always on, uncomment this:
        %set(groot,'DefaultFigureToolbar','figure')
        
        %% to have toolbars always off, uncomment this:
        %set(groot,'DefaultFigureToolbar','none')  
        
        % Temporarily turn off old uiflowcontainer deprecated function warning.
        warning off MATLAB:uiflowcontainer:DeprecatedFunction
        
        % Temporarily turn off old uigridcontainer deprecated function warning.
        warning off MATLAB:uigridcontainer:DeprecatedFunction
        
        % Temporarily turn off old uitab and uitabgroup deprecated function warning.
        warning off MATLAB:uitab:DeprecatedFunction
        warning off MATLAB:uitabgroup:DeprecatedFunction
    
        % Disable Automatic Figure Themes for non-webui builds.
        if ~matlab.internal.feature("webui")
            matlab.internal.feature("AutomaticFigureThemesInJSD",0);
        end
        
        % Enable web export for webui builds
        if feature('webui')
            feature('ExportUsesWeb',true);
        end

        % Enable the PersistentAxesToolbar if the feature flag is enabled, and
        % monitor changes to the feature flag to enable/disable the toolbar.
        featureName = 'PersistentAxesToolbar';
        togglePersistentAxesToolbar(featureName);
        matlab.internal.feature(featureName, 'callback', @togglePersistentAxesToolbar);
        
        % Execute startup MATLAB file, if it exists.
        startup_exists = exist('startuphg','file');
        if startup_exists == 2 || startup_exists == 6
            clear startup_exists
            startuphg
        else
            clear startup_exists
        end
        
    catch exc
        warning(message('MATLAB:matlabrc:InitHandleGraphics', exc.identifier, exc.message));
    end
end

function rect = calculateLegacyDefaultFigurePosition(screen, width, height, margin)
    if ~ismac % For PC and Linux
        if height >= 500
            mwwidth = 560; mwheight = 420;
            scaling = max(1, get(groot,'screenpixelsperinch')/96);
            mwwidth = mwwidth * scaling;
            mwheight = mwheight * scaling;
            margin = margin * scaling;
        else
            mwwidth = 560; mwheight = 375;
        end
        left = screen(1) + (width - mwwidth)/2;
        bottom = height - mwheight - margin - screen(2);
    else % For Mac
        if height > 768
            mwwidth = 560; mwheight = 420;
            left = screen(1) + (width-mwwidth)/2;
            bottom = height-mwheight -margin - screen(2);
        else  % for screens that aren't so high
            mwwidth = 512; mwheight = 384;
            left = screen(1) + (width-mwwidth)/2;
            bottom = height-mwheight -(margin * 0.76) - screen(2);
        end
    end
    
    % round off to the closest integer.
    left = floor(left); bottom = floor(bottom);
    mwwidth = floor(mwwidth); mwheight = floor(mwheight);

    rect = [ left bottom mwwidth mwheight ];

end

function togglePersistentAxesToolbar(featureName, featureValue)
arguments
    featureName %#ok<INUSA>
    featureValue = matlab.internal.feature(featureName)
end
featureEnabled = featureValue > 0;

p = path;

% Find where the old toolbar lives in the path.
oldToolbarPath = fullfile(matlabroot, 'toolbox/matlab/graphics/graphics/plottools');
oldToolbarPathIndex = strfind(p, oldToolbarPath);
if isempty(oldToolbarPathIndex)
    oldToolbarPathIndex = Inf;
end

% Find where the persistent toolbar lives in the path.
persistentToolbarPath = fullfile(matlabroot, '/toolbox/matlab/graphicsinteractions/uicomponents/matlab');
persistentToolbarPathIndex = strfind(p, persistentToolbarPath);
if isempty(persistentToolbarPathIndex)
    persistentToolbarPathIndex = Inf;
end

% The persistent is active if it is earlier in the path.
currentlyActive = persistentToolbarPathIndex < oldToolbarPathIndex;

if featureEnabled && ~currentlyActive
    % The new toolbar may already be on the path, but this will bump it to
    % the top of the path.
    addpath(persistentToolbarPath);
elseif ~featureEnabled && isfinite(persistentToolbarPathIndex)
    % The persistent toolbar folder is on the path when MATLAB is first
    % started, just lower on the path (and thus shadowed by) the old
    % toolbar. If the persistent toolbar feature is disabled, remove it
    % from the path.
    rmpath(persistentToolbarPath);
end

end
