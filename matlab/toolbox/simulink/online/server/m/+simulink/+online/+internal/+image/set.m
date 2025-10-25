function set(imageEncoding, imageQuality)
    if nargin < 1
        warning('You havent set up an image format!');
    end

    if nargin < 2
        imageQuality = 90;
    end

    slonline.setImageQuality(imageQuality);
    slonline.setImageEncoding(imageEncoding);
end
