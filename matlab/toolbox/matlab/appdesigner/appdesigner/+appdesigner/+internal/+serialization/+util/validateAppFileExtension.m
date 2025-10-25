function validateAppFileExtension(inputFileNameOrPath)
    %VALIDATEAPPFILEEXTENSION Ensure that the file extension of the
    % input path matches '.m' or '.mlapp' exactly.
    %   If the file extension does not match '.m' or '.mlapp', an error will
    %   be thrown.  The comparison is case sensitive.

    % Copyright 2019-2024 The MathWorks, Inc.

    % g3439417: Add feature control
    if feature('AppDesignerPlainTextFileFormat')
        expectedFileExtensions = {'.m', '.mlapp'};
    else
        expectedFileExtensions = {'.mlapp'};
    end

    [~, ~, ext] = fileparts(inputFileNameOrPath);

    if ~any(strcmp(ext, expectedFileExtensions))
        % g1934804: we do not open or save files with extensions other than .mlapp,
        % case sensitive.  If only the case is a mismatch, inform the user to make
        % the extension fully lowercase.

        % #todo - why care about ext case?
        
        if any(strcmpi(ext, expectedFileExtensions))
            msgIdentifier = 'MATLAB:appdesigner:appdesigner:InvalidFileExtensionCase';
        else
            msgIdentifier = 'MATLAB:appdesigner:appdesigner:InvalidFileExtension';
        end

        error(message(msgIdentifier, inputFileNameOrPath));
    end
end