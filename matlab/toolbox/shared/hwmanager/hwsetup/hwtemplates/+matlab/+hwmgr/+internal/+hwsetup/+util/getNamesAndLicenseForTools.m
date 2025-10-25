function [name, url] = getNamesAndLicenseForTools(instrSetInfo, isDownloadLink)
% matlab.hwmgr.internal.hwsetup.util.getNamesAndLicenseForTools
% This function retrieves the names and license URLs for third-party (3P)
% tools from the instruction set information.
%
% Inputs:
%   instrSetInfo: A cell array containing objects with information about each tool.
%
%   isDownloadLink: A boolean flag indicating whether to format the tool names as
%                   clickable download links or license link
%
% Outputs:
%   name: A cell array of strings containing the names of the tools. If isDownloadLink
%         is true, these names will be formatted as HTML links.
%   url: A cell array of strings containing the URLs to the license information for each tool.

% Copyright 2024 The MathWorks, Inc.

name = {};
url = {};

if ~iscell(instrSetInfo)
    instrSetInfo ={instrSetInfo};
end

for i = 1:numel(instrSetInfo)
    if isDownloadLink
        url{end+1} = ['<a href="' instrSetInfo{i}.getDownloadUrl() '">' getString(message('hwsetup:template:LinkText')) '</a>'];
    else
        url{end+1} = instrSetInfo{i}.getLicenseUrl();    
    end
      name{end+1} = instrSetInfo{i}.getDisplayName();
end
end