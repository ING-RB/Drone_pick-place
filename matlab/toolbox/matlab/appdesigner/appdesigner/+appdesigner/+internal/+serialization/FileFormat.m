classdef FileFormat
    %FILEFORMAT

    % Copyright 2024, MathWorks Inc.

    properties (Constant)
        Text = 'm';
        Binary = 'mlapp';
    end

    methods (Static)
        function fileFormat = getFileFormatByExtension (filepath)
            import appdesigner.internal.serialization.FileFormat

            if endsWith(filepath, FileFormat.Text, 'IgnoreCase', true)
                fileFormat = appdesigner.internal.serialization.FileFormat.Text;

            elseif endsWith(filepath, FileFormat.Binary, 'IgnoreCase', true)
                fileFormat = appdesigner.internal.serialization.FileFormat.Binary;
            else
                error(message('MATLAB:appdesigner:appdesigner:InvalidFileExtension', filepath));
            end
        end
    end

end

