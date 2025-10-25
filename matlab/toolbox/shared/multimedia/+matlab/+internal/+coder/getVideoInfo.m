function vidProps = getVideoInfo(fileName)
%GETVIDEOINFO Queries information about the video file that is necessary to
%describe the frame returned when reading the file. This is a helper
%function that is used to determine dimensions at compile time.

%   Authors: DI
%   Copyright 2018 The MathWorks, Inc.

% Only those propertis that are needed to describe an output frame
% completely are necessary.
propList = {'Height', 'Width', 'BitsPerPixel', 'VideoFormat'};

maxLenOfVideoFormat = 20;

if nargin == 0
    for cnt = 1:numel(propList)
        switch(propList{cnt})
            case {'VideoFormat'}
                % Pad the video format property to a maximum length to make
                % coder happy.
                vidProps.(propList{cnt}) = blanks(maxLenOfVideoFormat);
            otherwise
                vidProps.(propList{cnt}) = NaN;
        end
    end
    return;
end

% If the file cannot be read, we error out. This ensure that the error
% happens during code-generation time.
v = matlab.internal.VideoReader(fileName);
for  cnt = 1:numel(propList)
    x = v.(propList{cnt});

    % Pad the video format property to a maximum length to make
    % coder happy.
    if strcmp(propList{cnt}, 'VideoFormat')
        x = [ x blanks(maxLenOfVideoFormat - numel(x)) ];
    end

    vidProps.(propList{cnt}) = x;
end
