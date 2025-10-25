function tooBig = checkImageSizeForPrint(dpi, ~, width, height)
    % CHECKIMAGESIZEFORPRINT Checks to see if the image that will be
    % produced in the print path is within certain bounds. This
    % undocumented helper function is for internal use.

    % This function is called during the print path.  See usage in
    % alternatePrintPath.m
    
    % Predict how big the image data will be based on the requested
    % resolution and image size.  Returns true if the image size is greater
    % than the limit in imwrite.
    
    % Copyright 2013-2020 The MathWorks, Inc.

    tooBig = matlab.graphics.internal.mlprintjob.checkImageSizeForPrint( ...
        dpi, width, height); 
end
