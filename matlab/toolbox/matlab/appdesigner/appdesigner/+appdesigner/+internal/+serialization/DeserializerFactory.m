classdef DeserializerFactory
    %DESERIALIZERFACTORY Creates an AppDeserializer specific to an app
    %format (MLAPP or M)

    methods (Static)

        function deserializer = createDeserializer(fileName)

            % assumes valid file ext #fix

            import appdesigner.internal.serialization.FileFormat;

            [~, ~, ext] = fileparts(lower(fileName));
            ext = strip(ext,'.');

            switch ext
                case FileFormat.Text
                    validators = appdesigner.internal.serialization.DeserializerFactory.createAppFileValidators(ext);
                    deserializer = appdesigner.internal.serialization.PlainTextDeserializer(fileName, validators);

                case FileFormat.Binary
                    fileReader = appdesigner.internal.serialization.FileReader(fileName);
                    codeText = fileReader.readMATLABCodeText();

                    validators = appdesigner.internal.serialization.DeserializerFactory.createAppFileValidators(ext, codeText);
                    deserializer = appdesigner.internal.serialization.MLAPPDeserializer(fileName, validators);

                otherwise
                    error(message('MATLAB:appdesigner:appdesigner:InvalidFileExtension', fileName));
            end
        end

        function validators = createAppFileValidators(fileExtension, codeText)

            % TODO M and MLAPP could use same validators but all are called MLAPP...

            import appdesigner.internal.serialization.validator.deserialization.*;
            import appdesigner.internal.serialization.FileFormat;

            switch fileExtension

                case FileFormat.Text
                    validators = {};

                case FileFormat.Binary
                    validators = {...
                    ... Data Integrity
                    MLAPPReleaseValidator, ...
                    MLAPPTypeValidator, ...
                    MLAPPResponsiveAppValidator, ...
                    MLAPPSimulinkAppValidator ...
                    ... Environment
                    MLAPPLicenseValidator, ...
                    MLAPPUserComponentValidator(codeText) ...
                    };

                otherwise
                    validators = {};
            end
        end
    end
end

