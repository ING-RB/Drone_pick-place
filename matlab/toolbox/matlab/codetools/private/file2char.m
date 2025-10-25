function c = file2char(filename)

% Copyright 1984-2019 The MathWorks, Inc.

[~,~,ext] = fileparts(filename);

if isequal(ext, '.mlx')
    c = matlab.internal.getCode(filename);
else
    f = fopen(filename);
    c = fread(f,'uint8')';                % Read in BYTES with no encoding
    fclose(f);

    % Look for charset specification in the file
    encoding = char(regexp(char(c),'charset=([A-Za-z0-9\-\.:_])*','tokens','once'));

    try
        native2unicode(255,encoding);     % Verify the encoding is valid and supported
    catch
        encoding = '';                    % If not valid, set it to empty
        % A warning msg can be added here if needed.
    end

    if ~isempty(encoding)
        c = native2unicode(c,encoding);   % Convert data using specified encoding
    else
        c = fileread(filename);           % Leverage fileread for auto-charset detection
    end
end
