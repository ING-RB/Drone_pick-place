function X = imdecode(bytesBuffer)
%MATLAB.INTERNAL.IMDECODE Read image from graphics buffer.
%   X = MATLAB.INTERNAL.IMDECODE(bytesBuffer) reads a grayscale or color
%   image from in-memory uint8 buffer

% Copyright 2021 The MathWorks, Inc.


% Setup the Inputparser to validate the input arguments.
    parser = inputParser;
    parser.FunctionName = "imdecode";
    if ischar(bytesBuffer) || isstring(bytesBuffer)
        validateFilename = @(x)validateattributes(x,{'char','string'},{'nonempty','scalartext'});
        addRequired (parser,"Filename",validateFilename);
        [filePath,filename,ext] = fileparts(multimedia.internal.io.absolutePathForReading(bytesBuffer, ....
                                                                                          'image_io:imdecode:fileNotFound',...
                                                                                          'image_io:imdecode:filePermissionDenied'));
        bytesBuffer = strcat(string(filePath),filesep,filename,ext);
        bytesBuffer = convertStringsToChars(bytesBuffer);
    else
        validateBuffer = @(x)validateattributes(x,{'uint8'},{'vector', 'nonempty'});
        addRequired (parser,"BytesBuffer",validateBuffer);
    end

    try
        parse(parser,bytesBuffer);
    catch ME
        throwAsCaller(ME);
    end

    % If parsing is successful, get the decoded image
    try
        X = matlab.internal.imageio.imdecode(bytesBuffer);
    catch ME
        throwAsCaller(ME);
    end
