function updatedImageData = applyExifOrientation(imageData, orientationValue)
%APPLYEXIFORIENTATION transform image data based on provided orientation

% Copyright 2024 The MathWorks, Inc.

arguments
    imageData
    orientationValue (1,1) double
end

    switch orientationValue
        case 1
            % no adjustments needed
            updatedImageData = imageData;
        case 2
            % image data in the file is upright, mirrored left-to-right
            updatedImageData = flip(imageData, 2);
        case 3
            % image data in the file is upside-down, not mirrored
            updatedImageData = rot90(imageData, 2);
        case 4
            % image data in the file is upside-down, mirrored left-to-right
            updatedImageData = rot90(permute(imageData, [2 1 3]));
        case 5
            % image data in the file is on its left side, mirrored
            % left-to-right
            updatedImageData = permute(imageData, [2 1 3]);
        case 6
            % image data in the file is on its left side, not mirrored
            updatedImageData = rot90(imageData, 3);
        case 7
            % image data in the file is on its right side, mirrored
            % left-to-right
            updatedImageData = rot90(permute(imageData, [2 1 3]), 2);
        case 8
            % image data in the file is on its right side, not mirrored
            updatedImageData = rot90(imageData);
        otherwise
            % invalid orientation value - keep image data as is, but issue
            % a warning
            warning(...
                message('MATLAB:imagesci:imread:unexpectedOrientation', ...
                orientationValue))
            updatedImageData = imageData;
    end



end