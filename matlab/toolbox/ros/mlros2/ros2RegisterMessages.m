function ros2RegisterMessages(genDir)
%ros2RegisterMessages Register custom messages with MATLAB
%   ros2RegisterMessages(GENDIR) registers the custom messages with
%   MATLAB. GENDIR is the path to the folder that contains
%   matlab_msg_gen.zip file. Use this function to register the custom
%   messages generated on another computer running on the same platform and
%   same MATLAB release version with MATLAB.
%
%
%   Example:
%
%      % Create a custom message package folder in a local directory.
%      genDir = fullfile(pwd,"ros2CustomMessages");
%      packagePath = fullfile(genDir,"simple_msgs");
%      mkdir(packagePath)
% 
%      % Create a folder msg inside the custom message package folder.
%      mkdir(packagePath,"msg")
% 
%      % Create a .msg file inside the msg folder.
%      messageDefinition = {'int64 num'};
% 
%      fileID = fopen(fullfile(packagePath,'msg','Num.msg'),'w');
%      fprintf(fileID,'%s\n',messageDefinition{:});
%      fclose(fileID);
% 
%      % Create a folder srv inside the custom message package folder.
%      mkdir(packagePath,"srv")
% 
%      % Create a .srv file inside the srv folder.
%      serviceDefinition = {'int64 a'
%                           'int64 b'
%                           '---'
%                           'int64 sum'};
% 
%      fileID = fopen(fullfile(packagePath,'srv','AddTwoInts.srv'),'w');
%      fprintf(fileID,'%s\n',serviceDefinition{:});
%      fclose(fileID);
%
%      % Create an .action file inside the action folder.
%      actionDefinition = {'int64 goal'
%                          '---'
%                          'int64 result'
%                          '---'
%                          'int64 feedback'};
% 
%      fileID = fopen(fullfile(packagePath,'action','Test.action'),'w');
%      fprintf(fileID,'%s\n',actionDefinition{:});
%      fclose(fileID);
%
%      % Generate custom messages from ROS 2 definitions in .msg, and .srv and .action files.
%      ros2genmsg(genDir,CreateShareableFile=true)
%      
%      % Copy the generated zip file to the target computer running MATLAB
%      %of the same release version and same operating system and register
%      %the generated custom messages using ros2RegisterMessages function.
%      ros2RegisterMessages(genDir)
%
%   See also ros2genmsg, ros2message, ros2.

% Copyright 2022 The MathWorks, Inc.

if nargin < 1
    genDir = pwd;
end

genZipFile = fullfile(genDir,'matlab_msg_gen.zip');
if ~isfile(genZipFile)

    %If there is no zip file present in the input directory, we throw
    %an error saying to provide the correct input folder.
    error(message('ros:utilities:custommsg:NoZipFileExists','matlab_msg_gen.zip'))
else
    if isfolder(fullfile(genDir,'matlab_msg_gen'))

        %If there exists a folder named matlab_msg_gen in the
        %provided input directory, we throw an error saying to copy the
        %zip file to any other input folder and execute the
        %registration.
        error(message('ros:utilities:custommsg:FolderExists','matlab_msg_gen'))
    else
        unzip(genZipFile, genDir);
    end
end

versionStorageMapPath = fullfile(genDir,'VersionInfo.mat');
load(versionStorageMapPath,'versionStorageMap');

%Sharing of custom messages is supported only to same platform. If user
%tries to copy a zip file of one platform to other, we throw an error
%message and give a link to user which will re-generate custom messages
%for him by clicking on it.
if ~isequal(versionStorageMap('Platform'),computer('arch'))
    error(message('ros:utilities:custommsg:PlatformNotSupported',computer('arch'),'ros2genmsg',genDir))
end

%Sharing of custom messages is supported only to same release. If user
%tries to copy a zip file of one release to other, we throw an error
%message and give a link to user which will re-generate custom messages
%for him by clicking on it.
if ~isequal(versionStorageMap('Release'),version('-release'))
    error(message('ros:utilities:custommsg:ReleaseNotSupported',version('-release'),versionStorageMap('Release'),'ros2genmsg',genDir))
end

%Get the MessageTypes and ServiceTypes from the MAT file.
msgFullName = versionStorageMap('MessageList');
srvFullNameRequest = versionStorageMap('ServiceRequestList');
srvFullNameResponse = versionStorageMap('ServiceResponseList');
srvFullName = versionStorageMap('ServiceList');
actionFullName = versionStorageMap('ActionList');

% Update preferences with folder information
reg = ros.internal.custommsgs.updatePreferences(msgFullName,srvFullNameRequest,srvFullNameResponse,srvFullName,actionFullName,'ros2',genDir); %#ok<NASGU>
end