function [redirect,mapfile,topic] = checkForDemoRedirect(html_file)
% Internal use only.

% This fuction helps map references to examples from the legacy location
% under toolbox, e.g. toolbox/matlab/demos/html/sparsity.html, to their new
% location under docroot, e.g. matlab/examples/sparse-matrices.html. It
% does this by figuring out which doc set a given toolbox folder 
% corresponds to and looking there for an anchor matching the filename.
% If one is found, it can open the page in the new location instead.

%   Copyright 2012-2020 The MathWorks, Inc.

% Defaults.
redirect = false;
mapfile = '';
topic = '';

% WEB called with no arguments?
if isempty(html_file)
    return
end

% Break up the full path, and standardize fileseps to "/".
[htmlDir,topic] = fileparts(fullfile(html_file));
htmlDir = canonicalizeFilesep(htmlDir);

% In an "html" directory?
if isempty(regexp(htmlDir,'/html$','once')) 
    return
end
    
% In foodemos (or foodemo for wavedemo) or examples or fooexamples?
if isempty(regexp(htmlDir,'demos?/','once')) && ...
   isempty(regexp(htmlDir,'examples/','once'))
    return
end

% Look for for a toolbox folder. This might be under matlab/toolbox
% or elsewhere, such as a support package.
[~,toolbox] = regexp(htmlDir,'[\\/]toolbox[\\/]','once');
if ~isempty(toolbox)
    relDir = htmlDir(toolbox+1:end);
    mapfile = checkCshTopic(relDir,topic);
    if ~isempty(mapfile)
        redirect = true;
    end
end
end

%--------------------------------------------------------------------------
function helpDir = checkCshTopic(relDir,topic)
    % A corresponding map file?
    helpDir = mapToolboxDirToHelpDir(relDir);
    % Contains topic?
    if matlab.internal.doc.csh.mapTopic(helpDir,topic) == ""
        helpDir = '';
        return
    end
end

%--------------------------------------------------------------------------
function helpDir = mapToolboxDirToHelpDir(relDir)

dc = @(d)strncmp(relDir,[d '/'],numel(d)+1);
if dc('aero')
    helpDir = 'aerotbx';
elseif dc('shared/eda') || dc('shared/tlmgenerator') || dc('edalink')
    helpDir = 'hdlverifier';
elseif dc('shared/sdr/sdrplug/plutoradio_hspdef/plutoradiodemos')
    helpDir = 'plutoradio';
elseif dc('shared/sdr/sdrr')
    helpDir = 'rtlsdrradio';
elseif dc('shared/sdr/sdru')
    helpDir = 'usrpradio';
elseif dc('shared/sdr/sdrz/usrpe3xxdemos')
    helpDir = 'usrpembeddedseriesradio';
elseif dc('shared/sdr/sdrz')
    helpDir = 'xilinxzynqbasedradio';
elseif dc('globaloptim')
    helpDir = 'gads';
elseif  dc('dsp/supportpackages') || ...
        dc('hdlcoder/supportpackages') || ...
        dc('instrument/supportpackages') || ...
        dc('matlab/hardware/supportpackages') || ...
        dc('robotics/supportpackages') || ...
        dc('target/supportpackages')
    helpDir = regexp(relDir,'(?<=supportpackages\/)[^\/]+','match','once');
elseif dc('idelink') || dc('target')
    helpDir = 'rtw';
elseif dc('rfblks')
    helpDir = 'simrf';
elseif dc('simulink/fixedandfloat')
    helpDir = 'fixedpoint';
elseif dc('simulinktest')
    helpDir = 'sltest';
elseif dc('slde')
    helpDir = 'simevents';
elseif dc('physmod')
    helpDir = regexp(relDir,'(?<=/)[^\/]+','match','once');
    switch helpDir
        case 'sh'
            helpDir = 'hydro';
        case {'elec','pe','powersys'}
            helpDir = 'sps';
        case 'mech'
            helpDir = 'sm';
    end
elseif dc('rtw/targets')
    helpDir = regexp(relDir,'(?<=targets\/)[^\/]+','match','once');
elseif dc('rptgenext/rptgenextdemos/slxmlcomp')
    helpDir = 'simulink';
elseif dc('shared/aeroblks/aerodemos')
    helpDir = 'aeroblks';
else
    helpDir = regexp(relDir,'[^\/]+','match','once');
end
end

%--------------------------------------------------------------------------
function s = canonicalizeFilesep(s)
s = strrep(s,'\','/');
end
