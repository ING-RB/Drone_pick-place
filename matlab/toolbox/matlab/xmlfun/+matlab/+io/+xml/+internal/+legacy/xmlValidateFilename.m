function validatedFilename = xmlValidateFilename(filename)
%

% Copyright 2022-2024 The MathWorks, Inc.

    import matlab.io.xml.internal.legacy.xmlstringinput

    if ischar(filename)
        filename = xmlstringinput(filename,true);
        % This strips off the extra stuff in the resolved file. Then,
        % we are going to use java to put it in the right form.
        if strncmp(filename, 'file:', 5)
            filename = regexprep(filename, '^file:///(([a-zA-Z]:)|[\\/])','$1');
            filename = strrep(filename, 'file://', '');
            validatedFilename = java.io.File(filename);
        else
            % http: doesn't work with java.io.File.
            % Xerces accepts strings which works for http://.
            validatedFilename = org.xml.sax.InputSource(filename);
        end
    elseif isa(filename,'java.io.File')
        % Xerces is happier when UNC filepaths are sent as a
        % FileReader/InputSource than a File object
        % Note that FileReader(String) is also valid
        if filename.exists
            validatedFilename = org.xml.sax.InputSource(java.io.FileReader(filename));
        else
            error(message('MATLAB:xml:FileNotFound', char(filename)));
        end
    elseif isa(filename,'org.xml.sax.InputSource') || ...
            isa(filename,'java.io.InputStream')
        % noop - DocumentBuilder.parse accepts all these data types directly,
        % so we don't need to alter the input if it is one of these classes
        validatedFilename = filename;
    else
        error(message('MATLAB:xmlread:InvalidInput'));
    end
end