function hDialog = dialog(varargin)
%

%   Copyright 1984-2024 The MathWorks, Inc.

%check for support in deployed web apps
matlab.ui.internal.NotSupportedInWebAppServer('dialog');

% Throws error if in -nojvm mode
matlab.ui.internal.utils.checkJVMError;

if nargin > 0
    [varargin{:}] = convertStringsToChars(varargin{:});
end

if rem(nargin, 2) == 1
    error (message('MATLAB:dialog:NeedParamPairs'));
end

isWebui = feature('webui');

dlgMenubar   ='none';
btndown      ='if isempty(allchild(gcbf)), close(gcbf), end';
colormap     =[];
dockctrls    ='off';
handlevis    ='callback';
inthandle    ='off';
if ~isWebui % only want InvertHardcopy set in Java
    invhdcpy     ='off';
end
numtitle     ='off';
ppmode       ='auto';
resize       ='off';
visible      ='on';
winstyle     ='modal';

extrapropval=varargin;

rmloc=[];

for lp=1:2:size(varargin,2)
    switch lower(varargin{lp})
        case 'buttondownfcn'    , btndown   =varargin{lp+1}; rmloc=[rmloc;lp lp+1]; %#ok<*AGROW>
        case 'colormap'         , colormap  =varargin{lp+1}; rmloc=[rmloc;lp lp+1];
        case 'integerhandle'    , inthandle =varargin{lp+1}; rmloc=[rmloc;lp lp+1];
        case 'inverthardcopy'
            if ~isWebui
                % if in Java, set invhdcpy
                invhdcpy=varargin{lp+1};
                rmloc=[rmloc;lp lp+1];
            end
        case 'handlevisibility' , handlevis =varargin{lp+1}; rmloc=[rmloc;lp lp+1];
        case 'menubar'          , dlgMenubar=varargin{lp+1}; rmloc=[rmloc;lp lp+1];
        case 'numbertitle'      , numtitle  =varargin{lp+1}; rmloc=[rmloc;lp lp+1];
        case 'paperpositionmode', ppmode    =varargin{lp+1}; rmloc=[rmloc;lp lp+1];
        case 'windowstyle'      , winstyle  =varargin{lp+1}; rmloc=[rmloc;lp lp+1];
        case 'resize'           , resize    =varargin{lp+1}; rmloc=[rmloc;lp lp+1];
        case 'visible'          , visible   =varargin{lp+1}; rmloc=[rmloc;lp lp+1];
        case 'dockcontrols'     , dockctrls =varargin{lp+1}; rmloc=[rmloc;lp lp+1];
    end
end

if ~isempty(rmloc)
    extrapropval(rmloc)=[];
end

% Create the dialog
hDialog = figure('Visible','off','HandleVisibility','callback');
matlab.graphics.internal.themes.figureUseDesktopTheme(hDialog)

if ~isempty(colormap)
    hDialog.Colormap=colormap;
end

set(hDialog, ...
    'ButtonDownFcn'    ,btndown   , ...
    'IntegerHandle'    ,inthandle , ...
    'HandleVisibility' ,handlevis , ...
    'MenuBar'          ,dlgMenubar, ...
    'NumberTitle'      ,numtitle  , ...
    'PaperPositionMode',ppmode    , ...
    'WindowStyle'      ,winstyle  , ...
    'Resize'           ,resize    , ...
    'Visible'          ,visible   , ...
    'DockControls'     ,dockctrls , ... % Make sure DockControls is set after WindowStyle, because DockControls cannot be turned off if Windowstyle is set to 'docked'.
    extrapropval{:}                ...
    );

if ~isWebui
    % If in Java, set InvertHardcopy property
    set(hDialog, 'InvertHardcopy', invhdcpy);
end
