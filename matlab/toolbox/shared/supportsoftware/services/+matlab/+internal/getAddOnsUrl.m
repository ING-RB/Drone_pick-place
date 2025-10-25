function out = getAddOnsUrl(baseCodes, varargin)
% MATLAB.INTERNAL.GETADDONSURL - Returns client url for installing add-ons
% defined by baseCodes
%
% OUT = MATLAB.INTERNAL.GETADDONSURL(BASECODES) returns the url for 
% Unified Add-Ons installer. The workflow is set to MLPKGINSTALL.
% OUT = MATLAB.INTERNAL.GETADDONSURL(BASECODES, 'WorkflowName', 'UPGRADE')
% returns the url for Unified Add-Ons installer installer. The workflow is
% set to UPGRADE. Valid vales for WorkflowName parameter are MLPKGINSTALL, UPGRADE, DPKG.
% OUT = MATLAB.INTERNAL.GETADDONSURL(BASECODES, 'IsJAVAUI', true)
% returns the url for JAVA installer.
%
% Example:
% out = matlab.internal.getAddOnsUrl({'ML_MINGW'});
% out = matlab.internal.get3pInstallLocation({'USBWEBCAMS'}, 'WokflowName', 'UPGRADE');
% out = matlab.internal.get3pInstallLocation({'USBWEBCAMS'}, 'IsJAVAUI', true);

% Copyright 2023-2024 The MathWorks, Inc.


p = inputParser;
addRequired(p,'baseCodes',@(x) iscell(x) && all(cellfun(@ischar, x)));
addParameter(p,'WorkflowName','MLPKGINSTALL', @(x)ismember(x, {'UPGRADE', 'MLPKGINSTALL', 'DPKG', 'INSTALLFROMFOLDER', 'ADDONSINSTALL', 'SUPPORTPACKAGEUPDATE'}));
addParameter(p,'IsJAVAUI',false, @islogical);
addParameter(p,'SpkgLoc','', @ischar);
parse(p,baseCodes,varargin{:})

height = '450px';
width = '550px';
contextKeyValue = 'SSI_IN_MATLAB';

if p.Results.IsJAVAUI
    baseUrl = '/ui/install/supportsoftwareclient/index.html?';
    mlRoot = urlencode(matlabroot);
    spRoot = urlencode(matlabshared.supportpkg.getSupportPackageRoot);
else
    baseUrl = '/ui/install/addons_ui/index.html?';
    mlRoot = matlabroot;
    spRoot = matlabshared.supportpkg.getSupportPackageRoot;
end

baseCodeStr = cellfun(@(x) ['&basecode=' x], baseCodes, 'UniformOutput', false);
baseCodeStr = [baseCodeStr{:}];

out = [baseUrl ...
    'workflowType=' p.Results.WorkflowName...
    '&matlabroot=' mlRoot...
    '&installfolder=' spRoot ...
    '&contextKey=' contextKeyValue ...
    '&height=' height...
    '&width=' width...
    baseCodeStr];

if p.Results.IsJAVAUI
    out = strrep(out, ' ', '%20');
    out = connector.getUrl(out);
else
    out = [out '&artifactType=SUPPORTPACKAGE'];
    if any(strcmp(p.Results.WorkflowName, {'UPGRADE', 'MLPKGINSTALL'}))
        out = [out '&opensInManager=true'];
    end
    if any(strcmp(p.Results.WorkflowName, {'INSTALLFROMFOLDER'}))
        out = [out '&noLoginRequired=true'];
    end
    if ~isempty(p.Results.SpkgLoc)
        out = [out '&downloadFolder=' p.Results.SpkgLoc];
    end
end
end
