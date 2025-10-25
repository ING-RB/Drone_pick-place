function urlInfo = convertImageToBase64URL(imageFileInfo)
% Converts an image to a base64 URL String
%
% This should be used when needing to get image data from MATLAB to 
% the client.
%
% https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/Data_URIs
%
% Inputs: 
% 
%	imageFileName	Full file path to the image 
%                   or
%                   output of imfinfo(fileName) 
%
% Outputs:
%
%	urlInfo			A Struct with the following fields
%
%                    IconURL       Base64 URL encoding
%				     IconWidth     Width of image (px)
%				     IconHeight    Height of image (px)
%
% The width / height are included because the URL does not know anything
% about its size, and DOM elements typically need to be explicitly sized to
% avoid flicker when first rendering the URL.

if isstruct(imageFileInfo)
    imFileInfo = imageFileInfo;
    
else
    % get full file info
    imFileInfo = imfinfo(imageFileInfo);
    % 'gif' files may contain multiple images. Use the first image only.
    imFileInfo = imFileInfo(1);
end

if isfield(imageFileInfo, 'FileObject')
    % Use File Object if provided
    imFile = imageFileInfo.FileObject;
else
    % Create file for reading
    imFile = java.io.File(imFileInfo.Filename);
end

% Read the file as a BufferedImage
bImage = javax.imageio.ImageIO.read(imFile);

% Write as byte output
baos = java.io.ByteArrayOutputStream;

fileType = imFileInfo.Format;
javax.imageio.ImageIO.write(bImage, fileType, baos);

% Get the bytes
bImageBytes = baos.toByteArray();
baos.flush();
baos.close();

% Convert bytes to encoded URL
encoder = org.apache.commons.codec.binary.Base64;
iconString = transpose(char(encoder.encode(bImageBytes)));
urlString = sprintf('data:image/%s;base64,%s',fileType,iconString);

% Return all information as a struct
urlInfo = struct;
urlInfo.IconURL =  urlString;
urlInfo.IconWidth = imFileInfo.Width;
urlInfo.IconHeight = imFileInfo.Height;
end