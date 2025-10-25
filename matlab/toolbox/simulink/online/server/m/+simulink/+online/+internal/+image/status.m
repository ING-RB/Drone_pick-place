function status()
    quality = ['Current image quality is set at', ' ', num2str(slonline.getImageQuality())];
    encoding = ['Current image encoding is set to', ' ', slonline.getImageEncoding()];
    disp(quality);
    disp(encoding);
end