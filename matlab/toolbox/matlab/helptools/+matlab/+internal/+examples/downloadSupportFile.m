function localfile = downloadSupportFile(component, filename)
%DOWNLOADSUPPORTFILE Download a file from mathworks.com/supportfile.
% DOWNLOADSUPPORTFILE will make a support file on mathworks.com available
% on the local machine and cache that file so that it doesn't need to be
% downloaded again if it has already been downloaded.
%
% The output is a full path to the file downloaded. You cannot assume that
% this location is on the MATLAB path and you will need to use the full
% filename to access the data. If the data has already been downloaded by a
% previous call to downloadSupportFile then you will receive the same file
% location as the previous call. You should NOT modify the content of
% LOCALFILE; otherwise the next time you call downloadSupportFile you
% will receive the modified file.
%
% DOWNLOADSUPPORTFILE is for internal use only and may change in a future release. 
%
% Syntax
% ------
% localfile = MATLAB.INTERNAL.EXAMPLES.DOWNLOADSUPPORTFILE(component, filename)
%
% Example 
% -------
% Download trained series network object for lane detection network
% component = 'gpucoder';
% filename = 'cnn_models/lane_detection/trainedLaneNet.mat';
% localfile = matlab.internal.examples.downloadSupportFile(component,filename);

% Copyright 2020 The MathWorks, Inc.
 
% Convert inputs to char
component = char(component);
filename = char(filename);
% Determine destination folder
sd = matlab.internal.examples.utils.getSupportFileDir();
[filepath,name,ext] = fileparts(filename);
localDir = fullfile(sd, component, filepath);

% Construct full path to local destination filename
localfile = fullfile(localDir, [name ext]);

if ~exist(localfile,'file')
    
    % Setup workdir
    matlab.internal.examples.setupWorkDir(localDir);


    webFilePath = matlab.internal.examples.utils.getWebFilePath(component, filename);
    localfile = websave(localfile, webFilePath);
end

