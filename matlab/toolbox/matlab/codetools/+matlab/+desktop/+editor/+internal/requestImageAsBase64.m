% Helper function to open a file chooser dialog to
% pick an image and returns a base64 DataURI on success or an empty char
% array otherwise.

% Copyright 2024 The MathWorks, Inc.

function base64URI = requestImageAsBase64 ()

imageFileFilter = '*.png;*.jpg;*.jpeg;*.bmp;*.webp;*.svg;*.gif;*.apng';

% Store the last used image directory for this session.
% Initialize with current directory. 
persistent lastUsedLocation;
if isempty(lastUsedLocation)
    lastUsedLocation = pwd;
end

base64URI = '';

% Request file path.
[file, location] = uigetfile({imageFileFilter,...
    getString(message("MATLAB:Editor:Document:InsertImageFilter"))},...
    getString(message("MATLAB:Editor:Document:InsertImageTitle")),...
    lastUsedLocation);
if ~ischar(file) || ~ischar(location)
    return;
end

lastUsedLocation = location;
path = fullfile(location, file);

% Convert binary
base64Data = internal.matlab.videos.videoUtils.base64file(path);

% Guess mime type from extension.
[~, ~, ext] = fileparts(file);
mime = lower(extractAfter(ext, '.'));
% Handle special mimes.
switch mime
    case 'jpg'
        mime = 'jpeg';
    case 'svg'
        mime = 'svg+xml';
end

% Construct URI
base64URI = ['data:image/' mime ';base64,' base64Data];

end
