function daabout(product)
%DAABOUT  DAStudio about figure for Simulink and Stateflow

%   Copyright 1995-2024 The MathWorks, Inc.

% Resource locations:
% Derived (non source controlled, current release only): toolbox/shared/dastudio/resources/about_sl_sf/derived
% Source controlled (pre-populated for releases 2020-2030): toolbox/shared/dastudio/internal/about_sl_sf/
% TopTester: matlab/test/toolbox/slglue/system/aboutImages/tAboutImages.m
%
% NOTE: if you are looking for the About MATLAB splash screen see:
%       Code: matlab/coreui/src/SplashScreenImpl/win64/src/MLinfo.cpp
%       PNG images: matlab/resources/coreui/matlab
%       Text: matlab/resources/coreui/en/splashscreen.xml

mlock;

    matlabRelease = version('-release'); 
    aboutImageDir = [matlabroot '/toolbox/shared/dastudio/resources/about_sl_sf/derived/R' matlabRelease '/'];

    product = lower(product);

    switch(product),
    case 'simulink',
        sinceYear = '1990';
        [scale, path] = getScaledImagePath([aboutImageDir 'about_sl.png']);
        [cdata, map] = imread(path, 'png');
        dlgTitle = DAStudio.message('Simulink:dialog:AboutSimulink');

        aboutString = {...
            ver2str(ver('simulink')), ...
        };
    case 'stateflow',
        sinceYear = '1997';
        [scale, path] = getScaledImagePath([aboutImageDir 'about_sf.png']);
        [cdata, map] = imread(path, 'png');
        dlgTitle = DAStudio.message('Stateflow:dialog:AboutStateflow');


        verOutput = evalc('ver');
        if contains(verOutput, 'Stateflow')
            verInfo = ver('Stateflow');
        else
            verInfo = ver('Simulink');
            verInfo.Name = 'Stateflow';
        end
        
        if sf('License','basic')
            aboutString = {ver2str(verInfo)};
        else
            % No license. Demo version.
            aboutString = {ver2str( verInfo, 'Demo')};
        end       
    otherwise,
        error('DAStudio:UnsupportedProduct', 'Product not supported by DAStudio');
    end

    % if we're already on the screen, bring us forward and return.
    alreadyUp = findall(0, 'tag', tag_l, 'Name', dlgTitle);

    if ~isempty(alreadyUp)
        figure(alreadyUp);
        return;
    end

    dlg = dialog(   'Name',        dlgTitle, ...
                    'Color',       'White', ...
                    'WindowStyle', 'Normal', ...
                    'Visible',     'off', ...
                    'Tag',         tag_l,...
                    'Colormap',    map);
                    
    pos = get(dlg, 'position');
    imsize = size(cdata);
    pos(3) = imsize(1) / scale;
    pos(4) = imsize(2) / scale;
    
    dlgWidth = imsize(1);
   
   
    imH = imsize(2);
    set(dlg, 'Position', [pos(1) pos(2) pos(3) pos(4)]);

    ax = axes(      'Parent',   dlg, ...
                    'Visible',  'off', ...
                    'units',    'normalized', ...
                    'position', [0 0 1 1], ...
                    'xlim',     [0.5 imsize(1)+0.5], ...
                    'ydir',     'reverse', ...
                    'ylim',     [0.5 imsize(2)+0.5]);
                
    
    image('Parent',   ax, 'CData',    cdata);
    textX = 25*scale;

    % Font size for version number
    fontSize = 11;
    text(   'fontsize',         fontSize, ...
            'parent',           ax, ...
            'string',           aboutString, ...
            'tag',              'aboutString', ...
            'color',            [255, 255, 255]/255, ...
            'horizontala',      'left', ...
            'verticala',        'middle', ...
            'pos',              [textX 30*scale]);

    
    len = length(aboutString{1});
    year = aboutString{1}(len - 3 : len);
    copyrightPatentString = ['© ',sinceYear,'-',year,'. The MathWorks, Inc. Protected by U.S. and international', 10,...
                             'patents. See mathworks.com/patents. MATLAB and Simulink are', 10, ...
                             'registered trademarks of The MathWorks, Inc. See mathworks.com/', 10, ...
                             'trademarks for a list of additional trademarks. Other product or brand', 10, ...
                             'names may be registered trademarks of their respective holders.'];

    % Create copyright text (WARNING: font size modified below to fit dialog)
    fontSize = 10;
    copyrightPos = [textX, imH-78*scale];
    t = text(   'fontsize',         fontSize, ...
                'color',            [229, 247, 250]/255, ...
                'parent',           ax, ...
                'string',           copyrightPatentString, ...
                'tag',              'copyrightPatentString', ...
                'horizontala',      'left', ...
                'verticala',        'middle', ...
                'pos',              copyrightPos);

    % Set actual font size for the copyright text by using information about how
    % wide the text actually renders and reducing the font size until it fully
    % fits (including margins).
    % On leased Linux and Windows 11, this drops font to size 8 on standard DPI
    % On leased Mac machine, size 9
    while text_width(t) > (dlgWidth-2*textX) && fontSize > 5
        fontSize = fontSize-1;
        set(t,'fontsize',fontSize);
        drawnow;
    end

    set(dlg, 'Visible', 'on');

end % end daabout function

%---------------------------------
function textWidth = text_width(t)
    ext = get(t,'extent');
    textWidth = ext(3); 
end % function

%-------------------
function tag = tag_l
   tag = 'SLSF_About_Dialog';
end % function

%--------------------------------
function str = ver2str(ver, arg2)
    switch nargin
        case 1, 
            name = 'Version';
        case 2,
            switch class(arg2)
                case 'char', 
                    name = [arg2, ' Version'];
                otherwise
                    name = ver.Name; 
            end
        otherwise
            error('DAStudio:UnsupportedArguments', 'bad args');
    end
    
    dateS = datestr(ver.Date,'mmmm dd, yyyy');
    str = [name ' ' ver.Version ' ' ver.Release 10 dateS] ;

end % function

function [scale, scaledImagePath] = getScaledImagePath(imagePath)
scaledImagePath = imagePath;
scale = GLUE2.Util.getDevicePixelRatio * GLUE2.Util.getDpiScale;
if(scale>1)
    [path,name,ext] = fileparts(imagePath);
    scaledImagePath = [path '/' name '@' num2str(scale) 'X' ext];
    if exist(scaledImagePath, 'file') ~= 2
        scaledImagePath = imagePath;
        scale = 1;
    end
end
end
