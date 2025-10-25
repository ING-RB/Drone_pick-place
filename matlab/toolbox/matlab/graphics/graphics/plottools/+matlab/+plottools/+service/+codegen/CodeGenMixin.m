classdef CodeGenMixin < handle
    % Helper function for code generation that can be shared across
    % accessors

    properties(Access='protected')
        GeneratePvPairCode = true;
    end

    properties(Constant, Hidden=true)
        % This placeholder will be replaced with escaped single quotes after
        % converting all single quotes to double quotes.
        PLACEHOLDER = 'PLACEHOLDER';
    end

    methods(Access='protected')
 
        function code = generateLabelCode(obj, textObj, fcnName, exceptions)

            labelStr = '%s(%s%s)';

            pvPairs = obj.pvPairsCode(textObj, exceptions);

            if ~isempty(pvPairs)
                labelStr = '%s(%s, %s)';
            end

            code = sprintf(labelStr, fcnName, obj.formatLabelCode(textObj.String),...
                pvPairs);
        end
       
        function code = pvPairsCode(obj, hobj, exceptedProps)
            code = '';

            if (~obj.GeneratePvPairCode)
                return;
            end

            warning('off', 'MATLAB:hg:EraseModeIgnored');

            cl = metaclass(hobj);

            for i=1:numel(cl.PropertyList)
                propInfo = cl.PropertyList(i);
                modePropName = propInfo.Name;

                if isempty(code)
                    delim = '';
                else
                    delim = ', ';
                end

                if endsWith(modePropName, 'Mode')
                    
                    propName = strsplit(modePropName, 'Mode');

                    prop = hobj.findprop(propName{1});

                    % Skip Code Gen for Hidden Properties
                    if ~isempty(prop) && (prop.Hidden)
                        continue;
                    end

                    modeVal = get(hobj, modePropName);
                   
                    if strcmpi(modeVal, 'manual') && ~any(contains(exceptedProps, propName{1}))
                        propVal = get(hobj, propName{1});
                        code = [code, delim, sprintf('"%s", %s',...
                            propName{1}, obj.formatPropValue(propVal))]; %#ok<AGROW>
                    end
                end
            end

            warning('on', 'MATLAB:hg:EraseModeIgnored');
        end

        function code = formatArray(~, propValue)
            switch numel(propValue)
                case 4
                    code = sprintf('[%.4f %.4f %.4f, %.4f]', ...
                        propValue(1), propValue(2), ...
                        propValue(3),  propValue(4));
                case 3
                    code = sprintf('[%.4f %.4f %.4f]',...
                        propValue(1), propValue(2), ...
                        propValue(3));
                case 2
                    code = sprintf('[%.4f %.4f]',...
                        propValue(1), propValue(2));
            end
        end

        function code = formatPropValue(obj, value)
            if isnumeric(value) && isscalar(value)
                % numeric values should not have quotes
                code = string(value);
            elseif isnumeric(value) && ~isscalar(value)
                code = obj.formatArray(value);
            else
                code = sprintf('"%s"', string(value));
            end
        end 

        function str = formatLabelCode(obj,str)
            str = obj.escapeSingleQuote(str);
            % Escape double quotes
            str = obj.escapeDoubleQuotes(str);
            if ~isscalar(str)
                % if there are multiple lines join them with the newline
                % keyword
                str = str.join(''' , ''');
                str = strcat('[','''',str,'''',']');
            else
                str = strcat('''',str,'''');
            end
        end   

        function str = escapeSingleQuote(obj, str)
            % Instead of escaping single quotes immediately, insert a placeholder.
            str = string(strrep(cellstr(str),'''', obj.PLACEHOLDER));
        end

        % This function takes a string as input and returns the string with
        % double quotes escaped by doubling them
        function processedStr = escapeDoubleQuotes(~, inputStr)
            processedStr = strrep(inputStr, '"', '""');
        end
    end
end

