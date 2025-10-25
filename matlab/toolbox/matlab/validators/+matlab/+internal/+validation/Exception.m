classdef Exception < MException
    % Base class and utils for validation error handling

    % Copyright 2018-2024 The MathWorks, Inc.
    methods
        function ex = Exception(id, msg)
            ex@MException(id, '%s', msg);
        end
    end

    properties(Constant)
        MaxNumEnumsInMsg = 25
    end

    methods(Static)
        function messageString = getSizeSpecificMessage(ex, targetSize)
            import matlab.internal.validation.Exception

            % the following two if blocks handle big dimension values
            % exceptions
            if ~isempty(ex) && (strcmp(ex.identifier, 'MATLAB:array:SizeLimitExceeded') ||...
                    strcmp(ex.identifier, 'MATLAB:pmaxsize'))
                % reuse error messages when they make sense for validation
                messageString = ex.message;
                return;
            end

            if ~isempty(ex) && (strcmp(ex.identifier, 'MATLAB:badsubscript') ||...
                    strcmp(ex.identifier, 'MATLAB:colon:nonFiniteEndpoint'))
                % create new messages when they don't make sense for validation
                messageString = message('MATLAB:validation:IndexingLimitExceeded').getString;
                return;
            end

            [kind, tok] = Exception.parseTargetSize(targetSize);
            switch kind
                case 1
                    %notScalar (1,1)
                    messageObject = message('MATLAB:validation:NotScalar');
                case 2
                    %notVectorOfFixedLength (1,10) or (10,1)
                    messageObject = message('MATLAB:validation:NotVectorOfFixedLength', tok.length);
                case 3
                    %notVector (1,:) or (:,1)
                    messageObject = message('MATLAB:validation:NotVector');
                case 4
                    %notMatrix (:,:)
                    messageObject = message('MATLAB:validation:NotMatrix');
                case 5
                    %notMatrixOfFixedColumnLength (:,3)
                    messageObject = message('MATLAB:validation:NotMatrixOfFixedColumnLength', tok.col);
                case 6
                    %notMatrixOfFixedRowLength (3,:)
                    messageObject = message('MATLAB:validation:NotMatrixOfFixedRowLength', tok.row);
                case 7
                    %notMatrixOfFixedDimensionLength (2,4)
                    ds = message('MATLAB:matrix:dimension_separator').getString();
                    messageObject = message('MATLAB:validation:NotMatrixOfFixedDimensionLength', [num2str(tok.row) ds num2str(tok.col)]);
                case 8
                    %not3d (:,:,:)
                    messageObject = message('MATLAB:validation:Not3d');
                otherwise
                    %anything else
                    [dispSizeStr, hasUnfixedDimensions] = Exception.getDispSizeFromTokens(tok);
                    if hasUnfixedDimensions
                        messageObject = message('MATLAB:validation:InvalidSizeWithUnfixedDimensions', dispSizeStr);
                    else
                        messageObject = message('MATLAB:validation:InvalidSizeWithFixedDimensions', dispSizeStr);
                    end
            end

            messageString = messageObject.getString;
        end

        function msg = getClassConversionMessage(targetClass, caller, functionHandleToTargetClass, valueBeingValidated)
            import matlab.internal.validation.Exception.getEnumConversionMessageWithTextInput
            import matlab.internal.validation.Exception.getEnumConversionMessageWithNonTextInput
            import matlab.internal.validation.Exception.getFlagsConversionMessage

            % Default message
            msg = message('MATLAB:validation:UnableToConvertMessage',targetClass).getString();

            % handle enums
            resolvedTargetClass = caller.resolveClass(targetClass);
            if isempty(resolvedTargetClass)
                return;
            end

            mc = meta.class.fromName(resolvedTargetClass);

            if isempty(mc)
                return;
            end

            if ~mc.Enumerable
                isOptionalFlags = findobj(mc.SuperclassList,"Name","matlab.internal.validation.OptionalFlag");
                if isempty(isOptionalFlags)
                    return;
                end
            end

            % special handling for enum
            if mc.Enumerable
                % Get a list of all visible enum members from the metadata.
                emum_list = mc.EnumerationMemberList;
                visible_emum_list = emum_list(~[emum_list.Hidden]);
                visible_enum_members = {visible_emum_list.Name};

                if ischar(valueBeingValidated) || (isstring(valueBeingValidated) && ~any(ismissing(valueBeingValidated))) || iscellstr(valueBeingValidated)
                    msg = getEnumConversionMessageWithTextInput(msg, resolvedTargetClass, functionHandleToTargetClass, valueBeingValidated, visible_enum_members);
                else
                    msg = getEnumConversionMessageWithNonTextInput(resolvedTargetClass, visible_enum_members);
                end
                return;
            end

            % special handling for OptionalFlags
            flagsProp = findobj(mc.PropertyList, "Name", "Flags");
            if ~isempty(flagsProp)
                msg = getFlagsConversionMessage(msg, valueBeingValidated, flagsProp.DefaultValue);
            end
        end

        function formatedValues = genFormatedValuesForEnums(enumNames)
            n = numel(enumNames);
            if n == 1
                formatedValues = message('MATLAB:validation:OneStringChoice',    enumNames{:}).getString;
            elseif n == 2
                formatedValues = message('MATLAB:validation:TwoStringChoices',   enumNames{:}).getString;
            elseif n == 3
                formatedValues = message('MATLAB:validation:ThreeStringChoices', enumNames{:}).getString;
            elseif n == 4
                formatedValues = message('MATLAB:validation:FourStringChoices',  enumNames{:}).getString;
            elseif n == 5
                formatedValues = message('MATLAB:validation:FiveStringChoices',  enumNames{:}).getString;
            elseif n == 6
                formatedValues = message('MATLAB:validation:SixStringChoices',   enumNames{:}).getString;
            else
                list = cell2mat(arrayfun(@(x)generateIndentedStringWithQuote(x{:}), enumNames, 'UniformOutput', false));
                formatedValues = message('MATLAB:validation:ShortStringChoices', list).getString;
            end

            function quotedName = generateIndentedStringWithQuote(name)
                quotedName = message('MATLAB:validation:NameWithQuote', name).getString;
                quotedName = sprintf('    %s\n', quotedName);
            end
        end

        function formatedValues = genFormatedValuesForNamedArguments(validNames)
            import matlab.internal.validation.Exception.generateIndentedStringWithQuote
            n = numel(validNames);
            if n == 1
                formatedValues = message('MATLAB:functionValidation:OneStringChoice',    validNames{:}).getString;
            elseif n == 2
                formatedValues = message('MATLAB:functionValidation:TwoStringChoices',   validNames{:}).getString;
            elseif n == 3
                formatedValues = message('MATLAB:functionValidation:ThreeStringChoices', validNames{:}).getString;
            elseif n == 4
                formatedValues = message('MATLAB:functionValidation:FourStringChoices',  validNames{:}).getString;
            elseif n == 5
                formatedValues = message('MATLAB:functionValidation:FiveStringChoices',  validNames{:}).getString;
            elseif n == 6
                formatedValues = message('MATLAB:functionValidation:SixStringChoices',   validNames{:}).getString;
            else
                list = cell2mat(arrayfun(@(x)generateIndentedStringWithQuote(x{:}), validNames, 'UniformOutput', false));
                formatedValues = message('MATLAB:functionValidation:ShortStringChoices', list).getString;
            end
        end

        function S = sizeStrToStruct(sizestr)
            S = regexp(sizestr, ['(?<dim>[^', char(215), ']+)'], 'names');
            IsScalar = true;

            % preprocess scientic notations
            for i=1:numel(S)
                 len = S(i).dim;
                 if len(1) ~= 'D' && len(1) ~= 'M' && len(1) ~= 'N'
                     numValue = str2num(len);
                     if numValue ~= 1
                         IsScalar = false;
                     end
                     S(i).dim = numValue;
                 else
                     S(i).dim = '*';
                     IsScalar = false;
                 end
            end

            if IsScalar
                S = struct('dim',{1,1});
            end
        end
    end

    methods(Static, Access=private)
        function quotedName = generateIndentedStringWithQuote(name)
            quotedName = message('MATLAB:validation:NameWithQuote', name).getString;
            quotedName = sprintf('    %s\n', quotedName);
        end

        function msg = getFlagsConversionMessage(msg, valueBeingValidated, enumNames)
            import matlab.internal.validation.Exception.genFormatedValuesForEnums

            % nontext input
            if ~matlab.internal.datatypes.isScalarText(valueBeingValidated,false)
                formatedValues = genFormatedValuesForEnums(enumNames);
                msg = message('MATLAB:validation:ShortEnumConversionMessage', ...
                              formatedValues).getString;
                return;
            end

            try
                validatestring(valueBeingValidated, enumNames);
                return;
            catch me
            end

            % handle anbiguous names
            if (strcmp(me.identifier, 'MATLAB:ambiguousStringChoice'))
                enumNames = enumNames(startsWith(string(enumNames), valueBeingValidated, 'IgnoreCase', true));
                formatedValues = genFormatedValuesForEnums(enumNames);
                msg = message('MATLAB:validation:AmbiguousEnumMessage', ...
                    valueBeingValidated, formatedValues).getString;
                % early return
                return;
            end

            % any other test input
            formatedValues = genFormatedValuesForEnums(enumNames);
            msg = message('MATLAB:validation:ShortEnumConversionMessageForTextInput', ...
                          valueBeingValidated, formatedValues).getString;
        end

        function msg = getEnumConversionMessageWithTextInput(msg, targetClass, functionHandleToTargetClass, valueBeingValidated, enumNames)
            import matlab.internal.validation.Exception.genFormatedValuesForEnums

            invalidValue = [];
            svalue = string(valueBeingValidated);
            for i=1:numel(svalue)
                try
                    feval(functionHandleToTargetClass, svalue);
                catch me
                    invalidValue = svalue(i);
                    break;
                end
            end

            % early return
            if isempty(invalidValue); return; end

            % handle anbiguous names
            if me.identifier == "MATLAB:class:AmbiguousConvert"
                enumNames = enumNames(startsWith(string(enumNames), invalidValue, 'IgnoreCase', true));
                formatedValues = genFormatedValuesForEnums(enumNames);
                msg = message('MATLAB:validation:AmbiguousEnumMessage', ...
                    invalidValue, formatedValues).getString;
                % early return
                return;
            end

            if numel(enumNames) > matlab.internal.validation.Exception.MaxNumEnumsInMsg
                if isa(targetClass, "classID")
                    className = targetClass.Name;
                else
                    className = targetClass;
                end
                if matlab.internal.display.isHot
                    msg = message('MATLAB:validation:LongEnumConversionMessageWithHyperlinkForTextInput',...
                        invalidValue, className).getString;
                else
                    msg = message('MATLAB:validation:LongEnumConversionMessageWithoutHyperlinkForTextInput', ...
                        invalidValue, className).getString;
                end
            else
                formatedValues = genFormatedValuesForEnums(enumNames);
                msg = message('MATLAB:validation:ShortEnumConversionMessageForTextInput', ...
                    invalidValue, formatedValues).getString;
            end
        end

        function msg = getEnumConversionMessageWithNonTextInput(targetClass, enumNames)
            import matlab.internal.validation.Exception.genFormatedValuesForEnums

            if numel(enumNames) > matlab.internal.validation.Exception.MaxNumEnumsInMsg
                if matlab.internal.display.isHot
                    msg = message('MATLAB:validation:LongEnumConversionMessageWithHyperlink',...
                        targetClass).getString;
                else
                    msg = message('MATLAB:validation:LongEnumConversionMessageWithoutHyperlink', ...
                        targetClass).getString;
                end
            else
                formatedValues = genFormatedValuesForEnums(enumNames);
                msg = message('MATLAB:validation:ShortEnumConversionMessage', ...
                    formatedValues).getString;
            end
        end

        function [kind, tok] = parseTargetSize(S)
            arguments
                S struct
            end

            tok = struct;

            dim1 = S(1).dim;
            dim2 = S(2).dim;

            if numel(S) == 2
                %notScalar (1,1)
                if (dim1 == 1 && dim2 == 1)
                    kind = 1;
                    return;
                end

                %notVectorOfFixedLength (1,10) or (10,1)
                if (dim1 == 1 && isnumeric(dim2)) ||...
                    (dim2 == 1 && isnumeric(dim1))
                    kind = 2;
                    tok.length = dim1 * dim2;
                    return;
                end

                %notVector (1,:) or (:,1)
                if (dim1 == '*' && dim2 == 1) ||...
                    (dim2 == '*' && dim1 == 1)
                    kind = 3;
                    return;
                end

                %notMatrix (:,:)
                if dim1 == '*' && dim2 == '*'
                    kind = 4;
                    return;
                end

                %notMatrixOfFixedColumnLength (:,3)
                if dim1 == '*' && isnumeric(dim2)
                    kind = 5;
                    tok.col = dim2;
                    return;
                end

                %notMatrixOfFixedRowLength (3,:)
                if dim2 == '*' && isnumeric(dim1)
                    kind = 6;
                    tok.row = dim1;
                    return;
                end

                %notMatrixOfFixedDimensionLength (2,4)
                if isnumeric(dim1) && isnumeric(dim2)
                    kind = 7;
                    tok.row = dim1;
                    tok.col = dim2;
                    return;
                end
            end

            if numel(S) == 3
                %not3d (:,:,:)
                dim3 = S(3).dim(1);
                if dim1 == '*' && dim2 == '*' && dim3 == '*'
                    kind = 8;
                    return;
                end
            end

            %anything else
            tok = S;
            kind = 9;
        end

        function [dispSize, hasUnfixedDimensions] = getDispSizeFromTokens(tok)
            % Convert to format: *-by-*
            dispSize = cell(1, numel(tok));
            hasUnfixedDimensions = false;
            for i=1:numel(tok)
                len = tok(i).dim;
                if len(1) == '*'
                    dispSize{i} = '*';
                    hasUnfixedDimensions = true;
                else
                    dispSize{i} = num2str(len);
                end
            end
            ds = message('MATLAB:matrix:dimension_separator').getString();
            dispSize = strjoin(dispSize, ds);
        end
    end
end




