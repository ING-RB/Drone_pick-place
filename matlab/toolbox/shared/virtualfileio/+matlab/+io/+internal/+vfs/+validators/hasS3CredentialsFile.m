function tf = hasS3CredentialsFile()
%HASS3CREDENTIALSFILE Check if the local machine has a AWS credentials
% configuration

%   Copyright 2018 The MathWorks, Inc.

credentialsFilePath = iGetCredentialsPath();
tf = exist(credentialsFilePath, 'file') == 2;
end

function credentialsFilePath = iGetCredentialsPath()
credentialsFilePath = getenv('AWS_SHARED_CREDENTIALS_FILE');
if ~isempty(credentialsFilePath)
    return;
end

if ispc
    basePath = getenv('UserProfile');
else
    basePath = getenv('HOME');
end
credentialsFilePath = fullfile(basePath, '.aws', 'credentials');
end
