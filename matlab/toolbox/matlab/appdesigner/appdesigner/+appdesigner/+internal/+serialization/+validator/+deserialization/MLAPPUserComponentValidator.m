classdef MLAPPUserComponentValidator < appdesigner.internal.serialization.validator.MLAPPValidator
    % MLAPPUserComponentValidator Validator to check if the user component
    % classes saved in the MLAPP are valid

    % Copyright 2020 The MathWorks, Inc.

    properties (Access = private)
        MATLABCodeText
    end

    methods
        function obj = MLAPPUserComponentValidator(matlabCode)
            obj = obj@appdesigner.internal.serialization.validator.MLAPPValidator();
            obj.MATLABCodeText = matlabCode;
        end

        function validateAppData(obj, metadata, appData)
            % This validator does the following:
            % 1) Look at the generated code and extract the component code
            % names and class names from the initial properties block
            %
            % 2) Look at the code names of all components in the app
            %
            % 3) Compare the code names in the properties block to the the
            % components in the app figure to determine which components
            % have been removed
            %
            % 4) Compare the class names of the removed components to the
            % class names stored in the UserComponents field of the
            % metadata
            %
            % 5) If there is any overlap between the removed classes and
            % the metadata, pass that info up to the client.
            %
            % Note that the removed class names are cross-referenced with
            % the metadata to ensure we do not report any components that
            % are not user components.  This could happen with a component
            % introduced in a future release.
            allUserComponentClassNames = metadata.UserComponents;

            % If no user components are expected to be present in this app,
            % return early.
            if isempty(allUserComponentClassNames)
                return;
            end

            try
                codeNameToClassNameMap = obj.extractCodeNamesAndClassNames(obj.MATLABCodeText);

                remainingComponents = findall(appData.components.UIFigure, '-property', 'DesignTimeProperties');
                remainingCodeNames = cell(1, length(remainingComponents));

                for idx = 1:length(remainingComponents)
                   remainingCodeNames{idx} = remainingComponents(idx).DesignTimeProperties.CodeName;
                end

                originalCodeNames = keys(codeNameToClassNameMap);
                removedCodeNames = setdiff(originalCodeNames, remainingCodeNames);

                removedClassNames = cell(1, length(removedCodeNames));
                for idx = 1:length(removedCodeNames)
                    removedClassNames{idx} = codeNameToClassNameMap(removedCodeNames{idx});
                end
            catch
                % In case of error, make sure we do not interrupt the
                % loading process.  Return empty in that case - it will be
                % inaccurate to the user, but their app will still open.
                removedClassNames = {};
            end

            % Find indices of user-authored component classes from all
            % missing class names.  This is important to make sure we are
            % not accidentally reporting unsupported components from a
            % future release.
            % Use set intersection here to find classnames that are both
            % missing and stored in the metadata.  This eliminates any
            % components that are unknown and are not user-authored
            % components.
            missingOrErroredUserComponentClassNames = intersect(removedClassNames, allUserComponentClassNames);

            % We have now detected the user component classes that have
            % been removed, because either their classdef is missing or
            % they errored during load.  Now distinguish between the two.
            missingUserComponentClassNames = {};
            erroredUserComponentClassNames = {};

            for idx = 1:length(missingOrErroredUserComponentClassNames)
                className = missingOrErroredUserComponentClassNames{idx};
                try
                    metaclass = meta.class.fromName(className);

                    if isempty(metaclass)
                        % Class not found
                        missingUserComponentClassNames(end + 1) = {className};
                    else
                        % Class found, but it failed to load - mark it as
                        % errored.
                        erroredUserComponentClassNames(end + 1) = {className};
                    end

                catch ME
                    % Error retrieving metaclass - this can be from a
                    % syntax error in the classdef.  Report as errored.
                    erroredUserComponentClassNames(end + 1) = {className};
                end
            end

            % Create warnings for errored components and missing
            % components, if either one exists.
            if ~isempty(missingUserComponentClassNames)
                warningStruct = struct('ClassNames', {missingUserComponentClassNames});

                obj.addWarning('MissingUserComponents', warningStruct);
            end

            if ~isempty(erroredUserComponentClassNames)
                warningStruct = struct('ClassNames', {erroredUserComponentClassNames});

                obj.addWarning('ErroredUserComponents', warningStruct);
            end
        end
    end

    methods (Access = private)
        function codeNameToClassNameMap = extractCodeNamesAndClassNames(obj, matlabCode)
            codeNameToClassNameMap = containers.Map;

            % Retrieve the first properties block in the code text.
            % Capture the contents of the block using a lazy quantifier,
            % to ensure we match the first end statement
            firstPropertiesBlockRegex = 'properties \(Access = public\)\r?\n(.*?\r?\n)*?\s*end\r?\n';
            tokens = regexp(matlabCode, firstPropertiesBlockRegex, 'tokens');

            % Trim off any whitespace from the property declaration lines
            tokens = strtrim(tokens{1}{1});
            % Split up the component property declaration lines and remove
            % any surrounding whitespace
            tokens = strtrim(strsplit(tokens, '\n'));

            % For each property declaration line, split it at the
            % whitespace
            % The code name is first, followed by the class name
            % 16a has other text here but it's always after the class name,
            % so it's safely ignored here
            for idx = 1:length(tokens)
                token = tokens{idx};
                codeNameAndClassName = strsplit(token);
                codeName = codeNameAndClassName{1};
                className = codeNameAndClassName{2};

                codeNameToClassNameMap(codeName) = className;
            end
        end
    end
end
