function imagesFound = checkIfImagesFound(imageArray)
    %CHECKIFIMAGESFOUND Checks if multiple images are on the MATLAB path
    % Input: imageArray: a cell array of images to check
    % Output: imagesFound: a boolean array indicating if each image was
    % found on the path
    
    % Copyright 2021 MathWorks, Inc.

    checkImages = @(image) exist(image, 'file') == 2;
    imagesFound = cellfun(checkImages, imageArray);
end



