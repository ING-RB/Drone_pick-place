classdef string

    %MATLAB Code Generation Private Class

    %   Copyright 2016-2024 The MathWorks, Inc.
    %#codegen

    properties (Access = private, Hidden)
        Value
    end

    methods
        % String constructor; if val is omitted, returns an empty string.
        function obj = string(val)
            coder.internal.userReadableName([]);
            coder.internal.stringchk;
            coder.internal.allowEnumInputs;
            coder.internal.allowHalfInputs;
            if nargin == 1
                coder.internal.prefer_const(val);
                obj.Value = coder.internal.string.convertToString(val);
            else
                obj.Value = EMPTY;
            end
        end

        % Adds the two string objects and returns a new string object.
        function obj = plus(obj1, obj2)
            %add coder.internal.implicitExpansionBuiltin when implicit
            %expansion is added
            coder.internal.userReadableName([]);
            if coder.internal.get_eml_option('SimulinkStringSupport')
                coder.internal.preserveUselessInputs;
            end
            narginchk(2,2);
            obj1Value = coder.internal.string.convertToString(obj1);
            obj2Value = coder.internal.string.convertToString(obj2);
            obj = coder.internal.string([obj1Value obj2Value]);
            coder.internal.markNotSimulinkString(obj1, obj2, obj);
        end

        % Displays the value of the string object.
        function disp(obj)
            coder.internal.userReadableName([]);
            narginchk(1,1);
            coder.internal.markNotSimulinkString(obj);
            if ~isempty(obj.Value)
                feval('disp', obj.Value);
            end
        end

        % Returns 'string' (instead of coder.internal.string) as the class name.
        function class_name = class(~)
            narginchk(1,1);
            class_name = 'string';
        end

        % Returns true iff 'obj' is a coder.internal.string.
        function is_string = isstring(obj)
            narginchk(1,1);
            is_string = isa(obj, 'coder.internal.string');
        end

        % Returns the string as a character array.
        function char_array = char(obj, varargin)
            coder.internal.userReadableName([]);
            coder.inline('always');
            narginchk(1,1); % No combination of strings and nargs > 1 is valid
            coder.internal.markNotSimulinkString(obj, varargin{:});
            char_array = uncheckedChar(obj);
        end

        % Converts the input string to a cell array and returns it.
        function cell_str = cellstr(obj)
            coder.internal.userReadableName([]);
            coder.inline('always');
            narginchk(1,1);
            coder.internal.markNotSimulinkString(obj);
            cell_str = {obj.Value};
        end

        % Attempts to convert the input string to a double.
        function double_value = double(obj)
            coder.internal.userReadableName([]);
            coder.inline('always');
            narginchk(1,1);
            coder.internal.markNotSimulinkString(obj);
            double_value = coder.internal.str2double(obj.Value,false);
        end

        % Returns true iff obj1 and obj2 are equal.
        function equal = eq(obj1, obj2)
            %add coder.internal.implicitExpansionBuiltin when implicit
            %expansion is added
            if coder.internal.get_eml_option('SimulinkStringSupport')
                coder.internal.preserveUselessInputs;
            end
            narginchk(2,2);
            equal = relational_op(obj1, obj2, @eq);
            coder.internal.unifyIsSimulinkStringProperties(obj1, obj2);
        end

        % Returns true iff obj1 and obj2 are not equal.
        function not_equal = ne(obj1, obj2)
            %add coder.internal.implicitExpansionBuiltin when implicit
            %expansion is added
            if coder.internal.get_eml_option('SimulinkStringSupport')
                coder.internal.preserveUselessInputs;
            end
            narginchk(2,2);
            not_equal = relational_op(obj1, obj2, @ne);
            coder.internal.unifyIsSimulinkStringProperties(obj1, obj2);
        end

        % Returns true iff obj1 > ob2
        function is_greater_than = gt(obj1, obj2)
            %add coder.internal.implicitExpansionBuiltin when implicit
            %expansion is added
            coder.internal.userReadableName([]);
            narginchk(2,2);
            coder.internal.markNotSimulinkString(obj1, obj2);
            is_greater_than = relational_op(obj1, obj2, @gt);
        end

        % Returns true iff obj1 >= obj2.
        function is_greater_than_or_equal_to = ge(obj1, obj2)
            %add coder.internal.implicitExpansionBuiltin when implicit
            %expansion is added
            coder.internal.userReadableName([]);
            narginchk(2,2);
            coder.internal.markNotSimulinkString(obj1, obj2);
            is_greater_than_or_equal_to = relational_op(obj1, obj2, @ge);
        end

        % Returns true iff obj1 < obj2.
        function is_less_than = lt(obj1, obj2)
            %add coder.internal.implicitExpansionBuiltin when implicit
            %expansion is added
            coder.internal.userReadableName([]);
            narginchk(2,2);
            coder.internal.markNotSimulinkString(obj1, obj2);
            is_less_than = relational_op(obj1, obj2, @lt);
        end

        % Returns true iff obj1 <= obj2.
        function is_less_than_or_equal_to = le(obj1, obj2)
            %add coder.internal.implicitExpansionBuiltin when implicit
            %expansion is added
            coder.internal.userReadableName([]);
            narginchk(2,2);
            coder.internal.markNotSimulinkString(obj1, obj2);
            is_less_than_or_equal_to = relational_op(obj1, obj2, @le);
        end

        % Returns the number of characters in the input string.
        function string_length = strlength(obj)
            if coder.internal.get_eml_option('SimulinkStringSupport')
                coder.internal.preserveUselessInputs;
            end
            coder.inline('always');
            narginchk(1,1);
            string_length = numel(obj.Value);
        end

        function y = lower(obj)
            coder.internal.userReadableName([]);
            narginchk(1,1);
            y = charWrapper(@lower, obj);
            coder.internal.markNotSimulinkString(obj, y);
        end

        function y = upper(obj)
            coder.internal.userReadableName([]);
            narginchk(1,1);
            y = charWrapper(@upper, obj);
            coder.internal.markNotSimulinkString(obj, y);
        end

        % Returns a new string object that is the reverse of the input
        % string object.
        function reversed = reverse(obj)
            coder.internal.userReadableName([]);
            narginchk(1, 1);
            reversed = coder.internal.string(flip(obj.Value));
            coder.internal.markNotSimulinkString(obj, reversed);
        end

        % Returns true iff the pattern is found in obj.
        function does_contain = contains(obj, pattern, varargin)
            coder.internal.userReadableName([]);
            narginchk(2, inf);
            coder.internal.string.validateParameters('IgnoreCase', varargin{:});
            coder.internal.markNotSimulinkString(obj, pattern, varargin{:});

            if nargin > 3 && logical(varargin{2})
                matchPos = coder.internal.string.findFirst(lower(obj), lower(pattern));
            else
                matchPos = coder.internal.string.findFirst(obj, pattern);
            end
            does_contain = (matchPos > 0);
        end

        % Counts the number of distinct occurrences of pattern in obj.
        function count_of_occurences = count(obj, pattern, varargin)
            coder.internal.userReadableName([]);
            narginchk(2, inf);
            coder.internal.string.validateParameters('IgnoreCase', varargin{:});
            coder.internal.markNotSimulinkString(obj, pattern, varargin{:});

            if nargin > 3 && logical(varargin{2})
                nbMatches = coder.internal.string.findPattern(lower(obj), lower(pattern));
            else
                nbMatches = coder.internal.string.findPattern(obj, pattern);
            end
            count_of_occurences = double(nbMatches);
        end

        % Returns true iff obj starts with the specified pattern.
        function does_start_with = startsWith(obj, pattern, varargin)
            coder.internal.userReadableName([]);
            narginchk(2, inf);
            coder.internal.string.validateParameters('IgnoreCase', varargin{:});
            coder.internal.markNotSimulinkString(obj, pattern, varargin{:});

            [objVal, objLen] = coder.internal.string.getCharValue(obj);
            [patVal, patLen] = coder.internal.string.getCharValue(pattern);
            startPos = ONE;
            endPos = eml_min(objLen, patLen);

            if nargin > 3 && logical(varargin{2})
                matchPos = coder.internal.string.findFirst(...
                    lower(objVal), lower(patVal), startPos, endPos);
            else
                matchPos = coder.internal.string.findFirst(objVal, patVal, startPos, endPos);
            end
            does_start_with = (matchPos == startPos);
        end

        % Returns true iff obj ends with the specified pattern.
        function does_end_with = endsWith(obj, pattern, varargin)
            coder.internal.userReadableName([]);
            narginchk(2, inf);
            if ~isstring(pattern) && ~ischar(pattern) && eml_ambiguous_types
                does_end_with = coder.ignoreConst(false);
                return;
            end
            coder.internal.string.validateParameters('IgnoreCase', varargin{:});
            coder.internal.markNotSimulinkString(obj, pattern, varargin{:});

            [objVal, objLen] = coder.internal.string.getCharValue(obj);
            [patVal, patLen] = coder.internal.string.getCharValue(pattern);
            startPos = eml_max(objLen - patLen + 1, ONE);
            endPos = objLen;

            if nargin > 3 && logical(varargin{2})
                matchPos = coder.internal.string.findFirst(...
                    lower(objVal), lower(patVal), startPos, endPos);
            else
                matchPos = coder.internal.string.findFirst(objVal, patVal, startPos, endPos);
            end
            does_end_with = (matchPos == startPos);
        end

        % Return the substring of obj between [1:endPos), where endPos is
        % either an index or the first match of a text pattern.
        function extracted = extractBefore(obj, endStr)
            coder.internal.userReadableName([]);
            narginchk(2, 2);
            coder.internal.markNotSimulinkString(obj, endStr);
            [objVal, objLen] = coder.internal.string.getCharValue(obj);

            if isnumeric(endStr)
                endPos = coder.internal.string.checkPosition(endStr, 1, objLen + 1);
            else
                endPos = coder.internal.string.findFirst(objVal, endStr);
                if (endPos < 1)
                    extracted = coder.internal.string.missingStr('extractBefore');
                    return;
                end
            end
            extracted = coder.internal.string(objVal(1:endPos-1));
        end

       
        % Return the substring of obj between (startPos:end], where
        % startPos is either an index or the first match of a text pattern.
        function extracted = extractAfter(obj, startStr)
            coder.internal.userReadableName([]);
            narginchk(2, 2);
            coder.internal.markNotSimulinkString(obj, startStr);
            [objVal, objLen] = coder.internal.string.getCharValue(obj);

            if isnumeric(startStr)
                startPos = coder.internal.string.checkPosition(startStr, 0, objLen) + 1;
            else
                startPos = coder.internal.string.findFirst(objVal, startStr);
                if (startPos < 1)
                    extracted = coder.internal.string.missingStr('extractAfter');
                    return;
                else
                    startPos = startPos + coder.internal.string.getIntLength(startStr);
                end
            end
            extracted = coder.internal.string(objVal(startPos:end));
        end

        function inserted_str = insertBefore(obj, endStr, newText)
            coder.internal.userReadableName([]);
            narginchk(3, 3);
            coder.internal.markNotSimulinkString(obj, endStr, newText);

            if isnumeric(endStr)
                objLen = coder.internal.string.getIntLength(obj);
                endPos = coder.internal.string.checkPosition(endStr, 1, objLen + 1);
                inserted = coder.internal.string.stitchRange(obj, newText, endPos, endPos);
            else
                [nbMatches, matches] = coder.internal.string.findPattern(obj, endStr, ZERO);
                inserted = coder.internal.string.stitchMatches(obj, newText, nbMatches, matches, 0);
            end
            inserted_str = coder.internal.string(inserted);
        end

        function inserted_str = insertAfter(obj, startStr, newText)
            narginchk(3, 3);
            coder.internal.markNotSimulinkString(obj, startStr, newText);

            if isnumeric(startStr)
                objLen = coder.internal.string.getIntLength(obj);
                startPos = coder.internal.string.checkPosition(startStr, 0, objLen) + 1;
                inserted = coder.internal.string.stitchRange(obj, newText, startPos, startPos);
            else
                [nbMatches, matches] = coder.internal.string.findPattern(obj, startStr, ...
                    coder.internal.string.getIntLength(startStr));
                inserted = coder.internal.string.stitchMatches(obj, newText, nbMatches, matches, 0);
            end
            inserted_str = coder.internal.string(inserted);
        end

        % Deletes all occurrences of match in obj. The erase function
        % returns the remainder of the string as a new string.
        function erased = erase(obj, match)
            coder.internal.userReadableName([]);
            narginchk(2, 2);
            coder.internal.markNotSimulinkString(obj, match);
            erased = replace(obj, match, EMPTY);
        end

        % Returns a new string with the 'new' text replacing the 'old' text.
        function replaced_str = replace(obj, oldPattern, newText)
            coder.internal.userReadableName([]);
            narginchk(3, 3);
            coder.internal.markNotSimulinkString(obj, oldPattern, newText);
            objVal = coder.internal.string.getCharValue(obj);
            [oldVal, oldLen] = coder.internal.string.getCharValue(oldPattern);
            newVal = coder.internal.string.getCharValue(newText);

            if strcmp(newVal, oldVal)
                replaced = objVal;
            else
                [nbMatches, matches] = coder.internal.string.findPattern(objVal, oldVal);
                replaced = coder.internal.string.stitchMatches(objVal, newVal, nbMatches, matches, oldLen);
            end

            % Matlab has special semantics for strings: the return type
            % (char or string) depends on the type of the first argument
            replaced_str = coder.internal.string(replaced);
        end

        % Returns a string that starts at position strStart (strStart is an index)
        % or starts after the found position strStart (strStart is a char or string).
        % and ends at position strEnd (strEnd is an index)
        % or ends before the found position strEnd (strEnd is a char or string.)
        function extracted = extractBetween(~, ~, ~, varargin)
            %narginchk(3, Inf);
            %extracted = updateBetween('extractBetween', obj, strStart, strEnd, varargin{:});
            coder.internal.assert(false, 'Coder:builtins:MCOSMethodDoesNotSupportCodeGeneration', 'string.extractBetween');
            extracted = coder.internal.string();
        end

        % Removes the characters from position startStr (if startStr is an index)
        % or the characters following the pattern startStr (if startStr is scalar text)
        % to position endStr (if endStr is an index)
        % or until the pattern endStr (if endStr is scalar text).
        function erased = eraseBetween(obj, startStr, endStr, varargin)
            coder.internal.userReadableName([]);
            narginchk(3, Inf);
            coder.internal.markNotSimulinkString(obj, startStr, endStr, varargin{:});
            erased = replaceBetween(obj, startStr, endStr, EMPTY, varargin{:});
        end

        % Replaces the characters from position startStr (if startStr is an index)
        % or the characters following the pattern startStr (if startStr is scalar text)
        % to position endStr (if endStr is an index)
        % or until the pattern endStr (if endStr is scalar text)
        % with newText.
        function replaced_str = replaceBetween(obj, startStr, endStr, newText, varargin)
            coder.internal.userReadableName([]);
            narginchk(4, Inf);
            coder.internal.markNotSimulinkString(obj, startStr, endStr, newText, varargin{:});
            [inclusive, exclusive] = coder.internal.string.checkBoundaries(varargin{:});
            % Note: you might expect exclusive = ~inclusive, but that is
            % NOT the case if neither was specified explicitly! Instead,
            % by default, position bounds are inclusive and text bounds
            % are exclusive.

            [objVal, objLen] = coder.internal.string.getCharValue(obj);
            if isnumeric(startStr)
                startPos = coder.internal.string.checkPosition(startStr + exclusive, 1, objLen + 1);
                if isnumeric(endStr)
                    endPos = coder.internal.string.checkPosition(endStr - exclusive, 0, objLen);
                    coder.internal.assert(endPos - startPos >= -1, ...
                        'Coder:toolbox:StringStartPositionAfterEndPosition');
                    replaced = coder.internal.string.stitchRange(objVal, newText, startPos, endPos + 1);
                else
                    endLen = coder.internal.string.getIntLength(endStr);
                    endPos = coder.internal.string.findFirst(objVal, endStr, startPos, objLen);
                    if (endPos > 0)
                        endPos = endPos + inclusive * endLen;
                        replaced = coder.internal.string.stitchRange(objVal, newText, startPos, endPos);
                    else
                        replaced = objVal;
                    end
                end
            elseif isnumeric(endStr)
                endPos = coder.internal.string.checkPosition(endStr - exclusive, 0, objLen);
                startLen = coder.internal.string.getIntLength(startStr);
                startPos = coder.internal.string.findFirst(objVal, startStr, ONE, endPos);
                if (startPos > 0)
                    startPos = startPos + (1 - inclusive) * startLen;
                    replaced = coder.internal.string.stitchRange(objVal, newText, startPos, endPos + 1);
                else
                    replaced = objVal;
                end
            else
                [nbMatches, matches] = coder.internal.string.findBetween(objVal, startStr, endStr, inclusive);
                replaced = coder.internal.string.stitchBetween(objVal, newText, nbMatches, matches);
            end

            % Matlab has special semantics for strings: the return type
            % (char or string) depends on the type of the first argument
            replaced_str = coder.internal.string(replaced);
        end

        function stripped = strip(obj, varargin)
            coder.internal.userReadableName([]);
            narginchk(1,3);
            coder.internal.markNotSimulinkString(obj, varargin{:});
            [objValue, objLength] = coder.internal.string.getCharValue(obj);
            whitespaceChars = coder.const(feval(...
                'coder.internal.matlabWhitespaceToday', coder.internal.charmax));
            if nargin == 3
                % strip(s,side,padding)
                coder.internal.assert(coder.internal.isOptionName(varargin{1}), ...
                    'Coder:toolbox:StringOptionMustBeOneOfSideOnly');
                side = matchSide(varargin{1}, 'Coder:toolbox:StringOptionMustBeOneOfSideOnly');
                coder.internal.assert(ischar(varargin{2}) || isstring(varargin{2}), ...
                    'Coder:toolbox:StringStripCharOrString');
                coder.internal.assert(strlength(varargin{2}) == 1, ...
                    'Coder:toolbox:StringStripCharacterSize');
                stripCharacters = coder.internal.string.getCharValue(varargin{2});
            elseif nargin == 2
                % strip(s,sideOrPadding)
                coder.internal.assert(ischar(varargin{1}) || isstring(varargin{1}), ...
                    'Coder:toolbox:StringOptionMustBeOneOf');
                if strlength(varargin{1}) == 1
                    stripCharacters = coder.internal.string.getCharValue(varargin{1});
                    side = SIDE_BOTH;
                else
                    stripCharacters = whitespaceChars;
                    side = matchSide(varargin{1}, 'Coder:toolbox:StringOptionMustBeOneOf');
                end
            else
                % strip(s)
                stripCharacters = whitespaceChars;
                side = SIDE_BOTH;
            end
            % edge case
            if objLength == 0
                stripped = coder.internal.string(EMPTY);
                return
            end
            [beginningIndex, endIndex] = coder.internal.string.findStripIndices(objValue, objLength, side, stripCharacters);
            stripped = coder.internal.string(objValue(beginningIndex:endIndex));
        end

        function [varargout] = ismissing(varargin)
            [varargout{1:nargout}] = functionNotSupported('ismissing');
        end

        function [varargout] = issorted(varargin)
            if nargin > 1 && ~isstring(varargin{1})
                [varargout{1:nargout}] = charWrapper(@issorted,varargin{:});
            else
                [varargout{1:nargout}] = functionNotSupported('issorted');
            end
        end

        function [varargout] = issortedrows(varargin)
            if nargin > 1 && ~isstring(varargin{1})
                [varargout{1:nargout}] = charWrapper(@issortedrows,varargin{:});
            else
                [varargout{1:nargout}] = functionNotSupported('issortedrows');
            end
        end

        function [varargout] = sort(varargin)
            if nargin > 1 && ~isstring(varargin{1})
                [varargout{1:nargout}] = charWrapper(@sort,varargin{:});
            else
                [varargout{1:nargout}] = functionNotSupported('sort');
            end
        end

        function tf = matches(varargin)
            tf = coder.internal.matches(varargin{:});
        end

        function p = isequal(varargin)
            coder.internal.allowEnumInputs();
            narginchk(2,Inf);
            stringIdx = ZERO;
            %unroll?
            for i=ONE:nargin
                coder.internal.errorIf(isenum(varargin{i}), 'Coder:builtins:EnumCompareString');
                if isstring(varargin{i})
                    stringIdx = i;
                elseif ~ischar(varargin{i}) && ~iscellstr(varargin{i})
                    p = false;
                    return
                end
            end
            stringExemplar = varargin{stringIdx};
            for i=ONE:nargin
                if iscell(varargin{i})
                    if ~isscalar(varargin{i}) || stringExemplar ~= varargin{i}
                        p = false;
                        return
                    end
                elseif stringExemplar~=varargin{i}
                    p = false;
                    return
                end
            end
            p = true;
        end

    end

    methods (Hidden = true)
        function result = uncheckedChar(obj)
            if coder.internal.get_eml_option('SimulinkStringSupport')
                coder.internal.preserveUselessInputs;
            end
            result = obj.Value;
        end

        % "Classic" toolbox wrapper functions
        % NOTE: Most of the following methods are only intended to redirect to their corresponding
        % char-only function, and are not "really" part of the string class; Therefore, they do not
        % apply the 'type of first argument' dispatch rule followed by the other string methods, and
        % instead fall back to the mcos dispatching rules (any dominant type).
         function extracted = extractByPositionOrChar(obj, Str) % The extract function is defined as a private function, and it outputs array of strings while taking an array of strings as input. However, this functionality is not supported in code generation.
            coder.internal.userReadableName([]);
            narginchk(2, 2);
            coder.internal.markNotSimulinkString(obj, Str);
            [objVal, objLen] = coder.internal.string.getCharValue(obj);
            if isnumeric(Str)
                Pos = coder.internal.string.checkPosition(Str, 1, objLen);
                if (Pos < 1)
                    extracted = coder.internal.string.missingStr('extract');
                    return;
                else
                    extracted = coder.internal.string(objVal(Pos));
                end
            else
               exlen = count(obj,Str);
               Pos = coder.ignoreConst(coder.internal.string.findFirst(objVal, Str));
               Posend = Pos + coder.internal.string.getIntLength(Str);
               extracted = (repmat({objVal(Pos:Posend-1)},exlen,1)); % If regexp is supported the code need to be changed accordingly.
               
            end
            
         end
        function y = bin2dec(obj)
            narginchk(1,1);
            coder.internal.markNotSimulinkString(obj);
            y = charWrapper(@bin2dec, obj);
        end

        function y = deblank(obj)
            narginchk(1,1);
            coder.internal.markNotSimulinkString(obj);
            y = charWrapper(@deblank, obj);
        end

        function y = hex2dec(obj)
            narginchk(1,1);
            coder.internal.markNotSimulinkString(obj);
            y = charWrapper(@hex2dec, obj);
        end

        function y = hex2num(obj)
            narginchk(1,1);
            coder.internal.markNotSimulinkString(obj);
            y = charWrapper(@hex2num, obj);
        end

        function y = isletter(obj)
            narginchk(1,1);
            coder.internal.markNotSimulinkString(obj);
            y = charWrapper(@isletter, obj);
        end

        function y = isspace(obj)
            narginchk(1,1);
            coder.internal.markNotSimulinkString(obj);
            y = charWrapper(@isspace, obj);
        end

        function y = isstrprop(obj, varargin)
            narginchk(2,4);
            coder.internal.markNotSimulinkString(obj, varargin{:});
            y = charWrapper(@isstrprop, obj, varargin{:});
        end

        function y = str2double(obj)
            narginchk(1,1);
            coder.internal.markNotSimulinkString(obj);
            y = charWrapper(@str2double, obj);
        end

        function y = strfind(obj, varargin)
            narginchk(2,4);
            coder.internal.markNotSimulinkString(obj, varargin{:});
            y = charWrapper(@strfind, obj, varargin{:});
        end

        function y = strjoin(obj, delim)
            narginchk(1,2);
            coder.internal.markNotSimulinkString(obj);
            if isstring(obj) % strjoin requires the first argument to be a cell (or string) array
                if nargin == 2
                    coder.internal.markNotSimulinkString(delim);
                    yc = strjoin(cellstr(obj), coder.internal.toCharIfString(delim));
                else
                    yc = strjoin(cellstr(obj));
                end
                y = coder.internal.string(yc);
            else % in that case, we know that a) delim exists and b) it's a string
                coder.internal.markNotSimulinkString(delim);
                y = strjoin(obj, char(delim));
            end
        end

        function y = strjust(obj, varargin)
            narginchk(1,2);
            coder.internal.markNotSimulinkString(obj, varargin{:});
            y = charWrapper(@strjust, obj, varargin{:});
        end

        function y = strrep(varargin)
            narginchk(3,3);
            coder.internal.markNotSimulinkString(varargin{:});
            % NOTE: This function behaves differently than all other string functions:
            % If any of its inputs is a string, the result is always a string (unlike other string
            % functions, where the type of the first argument determines the return type).
            % Since this method here will be invoked only if at least one of the inputs is a string,
            % it follows that we will always return a string.
            y = coder.internal.string(charWrapper(@strrep,varargin{:}));
        end

        function [token, remain] = strtok(varargin)
            narginchk(1,2);
            coder.internal.markNotSimulinkString(varargin{:});
            % Note: We cannot defer to charWrapper here because strtok returns more than one value.
            args = coder.nullcopy(cell(1,nargin));
            for k = coder.unroll(1:nargin)
                if isstring(varargin{k})
                    args{k} = varargin{k}.Value;
                else
                    args{k} = varargin{k};
                end
            end

            resultIsString = isstring(varargin{1});
            if nargout == 2
                if resultIsString
                    [tokenC, remainC] = strtok(args{:});
                    token = coder.internal.string(tokenC);
                    remain = coder.internal.string(remainC);
                else
                    [token, remain] = strtok(args{:});
                end
            else
                if resultIsString
                    token = coder.internal.string(strtok(args{:}));
                else
                    token = strtok(args{:});
                end
            end
        end

        function y = strtrim(obj)
            narginchk(1,1);
            coder.internal.markNotSimulinkString(obj);
            y = charWrapper(@strtrim, obj);
        end

        function y = strcat(varargin)
            narginchk(1,Inf);
            for i = 1:nargin
                coder.internal.errorIf(~coder.internal.isCharOrScalarString(varargin{i}) ...
                    && ~iscell(varargin{i}), 'MATLAB:strcat:InvalidInputType');
            end
            y = coder.internal.string(charWrapper(@strcat, varargin{:}));
        end

        function out = append(varargin)
            % Add implicit expansion support when object arrays are supported
            narginchk(1, Inf);
            for k = coder.unroll(1:nargin)
                if isstring(varargin{k})
                    coder.internal.assert(isscalar(varargin{k}), ...
                        'Coder:toolbox:MustBeCharCellArrayOrString', k);
                elseif iscell(varargin{k})
                    coder.internal.assert(isscalar(varargin{k}), ...
                        'Coder:toolbox:AppendStringCellArray');
                    coder.internal.assert(checkScalarChar(varargin{k}{1}), ...
                        'Coder:toolbox:MustBeCharCellArrayOrString', k);
                else
                    coder.internal.assert(checkScalarChar(varargin{k}), ...
                        'Coder:toolbox:MustBeCharCellArrayOrString', k);
                end
            end

            % Compute the output string size
            outSize = coder.internal.indexInt(0);
            for k = 1:nargin
                if ischar(varargin{k})
                    outSize = outSize + coder.internal.indexInt(size(varargin{k}, 2));
                elseif iscell(varargin{k})
                    outSize = outSize + coder.internal.indexInt(size(varargin{k}{1}, 2));
                else
                    outSize = outSize + coder.internal.indexInt(size(varargin{k}.Value, 2));
                end
            end

            % Create the output string
            out = coder.internal.string(blanks(outSize));

            % Loop over the inputs and create the scalar output
            startIndex = coder.internal.indexInt(0);
            for k = 1:nargin
                if ischar(varargin{k})
                    sizeK = coder.internal.indexInt(size(varargin{k}, 2));
                    out.Value((startIndex+1):startIndex+sizeK) = varargin{k};
                elseif iscell(varargin{k})
                    sizeK = coder.internal.indexInt(size(varargin{k}{1}, 2));
                    out.Value((startIndex+1):startIndex+sizeK) = varargin{k}{1};
                else
                    sizeK = coder.internal.indexInt(size(varargin{k}.Value, 2));
                    out.Value((startIndex+1):startIndex+sizeK) = varargin{k}.Value;
                end
                startIndex = startIndex + sizeK;
            end
        end

        function result = matlabCodegenAllocLike(eg, varargin)
            coder.internal.assert(all([varargin{:}] == 1), 'Coder:builtins:StringArraysNotSupported');
            if coder.internal.isConst(numel(eg.Value))
                result = coder.internal.string(eml_expand(char(0), 1, coder.const(numel(eg.Value))));
            else
                result = coder.internal.string;
            end
        end

        function d = dictionary(varargin)
            % workaround for G3027369
            d = coder.internal.dictionary(varargin{:});
        end
    end

    methods (Access = private, Hidden = true) % Helper functions
        function y = charWrapper(f,varargin)
            nargs = numel(varargin);
            args = coder.nullcopy(cell(1,nargs));
            for k = coder.unroll(1:nargs)
                if isstring(varargin{k})
                    args{k} = varargin{k}.Value;
                else
                    args{k} = varargin{k};
                end
            end

            yc = f(args{:});
            if isstring(varargin{1}) && ischar(yc)
                y = coder.internal.string(yc);
            else
                y = yc;
            end
        end

        % Use the relational operator 'op' to compare two objects.
        function r = relational_op(obj1, obj2, op)
            if (isa(obj1, 'double') || isa(obj2, 'double')) && coder.internal.isAmbiguousTypes
                r = coder.ignoreConst(false);
                return
            end
            % TODO: Support enums for == and ~=
            checkRelopArgs(obj1,obj2);

            % If op is 'eq' or 'ne', then call strcmp
            if isequal(op,@eq)
                r = strcmp(obj1,obj2);
                return
            elseif isequal(op,@ne)
                r = ~strcmp(obj1,obj2);
                return
            end

            [obj1Value,obj1Size] = coder.internal.string.getCharValue(obj1);
            [obj2Value,obj2Size] = coder.internal.string.getCharValue(obj2);

            minSize = eml_min(obj1Size, obj2Size);
            % Base case: either obj1, obj2, or both objects are empty.
            if minSize == 0
                r = op(obj1Size, obj2Size);
                return;
            end

            i = ONE;
            while i <= minSize
                if obj1Value(i) ~= obj2Value(i)
                    break;
                end
                i = i + 1;
            end
            identicalUpToMinSize = (i == minSize + 1);

            % If both obj1 and obj2 are identical up to min_size,
            % use the size of both objects to determine the result
            % of the relational operation.
            if identicalUpToMinSize
                r = op(obj1Size, obj2Size);
                return;
            end
            % Else, compare the character values at index i.
            r = op(obj1Value(i), obj2Value(i));
        end
    end

    methods (Static, Access = public, Hidden = true)
        function this = matlabCodegenToRedirected(s)
            % Given MATLAB string, s, return coder.internal.string, this.  Returns an array
            % whose size matches size(s) for error-reporting purposes.
            if isempty(s)
                this = repmat(coder.internal.string(),size(s));
                return
            end
            for k = 1:numel(s)
                coder.internal.errorIf(ismissing(s(k)), ...
                    'Coder:toolbox:StringNoMissing');
                this(k) = coder.internal.string(char(s(k))); %#ok
            end
            this = reshape(this,size(s));
        end

        function s = matlabCodegenFromRedirected(this)
            % Given coder.internal.string, this, return MATLAB string, s.
            s = string({this.Value});
        end
    end

    methods(Static, Access = private, Hidden = true)
        function result = matlabCodegenUserReadableName
            result = 'string';
        end

        function result = matlabCodegenDispatcherName
            result = 'string';
        end

        % This function returns a <missing> string; (errors out for now).
        function out = missingStr(varargin)
            coder.inline('always');
            out = coder.internal.string();
            coder.internal.error('Coder:toolbox:StringReturnMissing', varargin{:});
        end

        % Creates the string representation of various other datatypes.
        function str = convertToString(val)
            coder.internal.allowEnumInputs();
            coder.internal.allowHalfInputs;
            coder.internal.prefer_const(val);
            coder.internal.errorIf(issparse(val), 'MATLAB:invalidConversion', ...
                'string', ['sparse ' class(val)]);

            if ischar(val) || isstring(val)
                str = coder.internal.string.getCharValue(val);
            elseif iscell(val)
                coder.internal.assert(coder.internal.isConstTrue(isscalar(val)), ...
                    'Coder:toolbox:StringScalarsOnly', class(val), mfilename);

                str = coder.internal.string.convertToString(val{1});

            else
                coder.internal.assert(...
                    coder.internal.isConstTrue(isscalar(val)), ...
                    'Coder:toolbox:StringScalarsOnly', class(val), mfilename);
                if isenum(val)
                    str = char(val);
                elseif islogical(val)
                    if val
                        str = 'true';
                    else
                        str = 'false';
                    end
                else
                    coder.internal.assert(...
                        coder.internal.isBuiltInNumeric(val), ...
                        'Coder:toolbox:StringUnsupportedType'); %TODO improve this message
                    str = coder.internal.string.int2strSci(val);
                end
            end
        end

        % Returns the character value and length of obj.
        function [val, len] = getCharValue(str)
            coder.inline('always');
            if ischar(str)
                val = normalizeChar(str, 'Coder:toolbox:StringMustBeRowVector');
            elseif iscell(str)
                coder.internal.assert(isscalar(str), ...
                    'Coder:toolbox:StringMustBeScalarCellArray');
                coder.internal.assert(ischar(str{1}), ...
                    'Coder:toolbox:StringUnsupportedType');
                val = normalizeChar(str{1}, 'Coder:toolbox:StringMustBeRowVectorInCell');
            elseif isa(str, 'double') && coder.internal.isAmbiguousTypes
                c = '';
                coder.varsize('c', [1 Inf]);
                val = coder.ignoreConst(c);
            else
                coder.internal.assert(isstring(str) && isscalar(str), ...
                    'Coder:toolbox:StringUnsupportedType');
                if isa(str,'coder.internal.string')
                    val = uncheckedChar(str);
                else
                    % In MATLAB execution we may get a MATLAB string
                    val = char(str);
                end
            end
            if nargout > 1
                len = coder.internal.indexInt(numel(val));
            end
        end

        % Returns length of obj as coder.internal.indexInt
        function len = getIntLength(obj)
            coder.inline('always');
            if iscell(obj)
                coder.internal.assert(isscalar(obj), ...
                    'Coder:toolbox:StringMustBeScalarCellArray');
                coder.internal.assert(ischar(obj{1}), ...
                    'Coder:toolbox:StringUnsupportedType');
                str = obj{1};
            else
                coder.internal.assert(ischar(obj) || isstring(obj), ...
                    'Coder:toolbox:StringUnsupportedType');
                str = obj;
            end
            len = coder.internal.indexInt(strlength(str));
            %[~, len] = coder.internal.string.getCharValue(obj);
            % The above alternative looks cleaner but sometimes generates a
            % lot of extra C code unfortunately.
        end

        % Returns false if there are no parameters, true if there are valid
        % parameters, and errors out if they exist but are invalid.
        function has_parameter = validateParameters(expectedName, actualName, value)
            if nargin > 1
                coder.internal.prefer_const(expectedName, actualName);
                coder.internal.assert(nargin > 2, ...
                    'Coder:toolbox:StringParameterMustHaveAssociatedValue');
                coder.internal.assert(coder.internal.isOptionName(actualName), ...
                    'Coder:toolbox:StringParameterNameMustBeRightType');
                coder.internal.assert(strcmpi(actualName, expectedName), ...
                    'Coder:toolbox:StringUnrecognizedParameterName', expectedName);
                switch expectedName
                    case 'IgnoreCase'
                        coder.internal.assert(isscalar(value), ...
                            'Coder:toolbox:StringValueArgMustBeScalar', actualName);
                    case 'Boundaries'
                        coder.internal.assert(strcmpi(value, 'inclusive') || strcmpi(value, 'exclusive'), ...
                            'Coder:toolbox:StringValueArgMustBeChar', actualName, 'Inclusive', 'Exclusive');
                end
                has_parameter = true;
            else
                has_parameter = false;
            end
        end

        % Returns the state of the inclusive and exclusive boundary flags.
        function [inclusive, exclusive] = checkBoundaries(varargin)
            % This functions returns 1s and 0s instead of true and false to
            % avoid further 'if' tests in its caller's scope.
            inclusive = 0;
            exclusive = 0;
            if coder.internal.string.validateParameters('Boundaries', varargin{:})
                if strcmpi(varargin{2}, 'inclusive')
                    inclusive = 1;
                elseif strcmpi(varargin{2}, 'exclusive')
                    exclusive = 1;
                end
                coder.internal.assert(xor(inclusive, exclusive), 'Coder:builtins:Explicit', ...
                    'validateParameters should have caught that earlier.');
            end
        end

        % This function checks that the given numeric position is between
        % the allowable [lower, upper] bounds; it returns the position
        % expressed as an indexInt (int32 in MATLAB).
        function idx = checkPosition(position, lowerBound, upperBound)
            coder.inline('always');
            coder.internal.prefer_const(position);
            coder.internal.assert(coder.internal.isBuiltInNumeric(position), ...
                'Coder:toolbox:StringIndexMustBePositiveInteger');

            coder.internal.assert(isscalar(position), 'Coder:toolbox:StringIndexMustBePositiveInteger');
            % When we'll support string arrays, the above should test that size(position) == size(input).
            pos = full(position(1)); % Ensure scalarness in case of variable-sized position.

            coder.internal.assert(isreal(pos) && isfinite(pos) && floor(pos) == pos, ...
                'Coder:toolbox:StringIndexMustBePositiveInteger');
            coder.internal.assert(pos >= lowerBound, ...
                'Coder:toolbox:StringIndexMustBePositiveInteger');

            idx = coder.internal.indexInt(pos);
            coder.internal.assert(idx <= upperBound, ...
                'Coder:toolbox:StringIndexMustNotExceedLength');
        end

        % This function returns the position of the first match of pattern
        % found in obj, within the boundaries set by [startPos, endPos].
        function matchPos = findFirst(obj, pattern, startPos, endPos)
            % obj and pattern can be empty; startPos and endPos are optional.
            [objVal, objLen] = coder.internal.string.getCharValue(obj);
            [patVal, patLen] = coder.internal.string.getCharValue(pattern);

            if nargin > 2
                % These checks are actually redundant, but I'm leaving them
                % here anyway to prevent future 'misuse' of the function.
                coder.internal.assert(startPos >= 1, ...
                    'Coder:toolbox:StringIndexMustBePositiveInteger');
                coder.internal.assert(endPos <= objLen, ...
                    'Coder:toolbox:StringIndexMustNotExceedLength');
            else
                startPos = ONE;
                endPos = objLen;
            end
            endPos = endPos - patLen + 1;

            % If patLen > objLen then the loop has no iterations.
            for i = startPos:endPos
                j = ONE;
                while (j <= patLen && (objVal(i + j - 1) == patVal(j)))
                    j = j + 1;
                end
                if (j > patLen)
                    matchPos = i;
                    return;
                end
            end
            matchPos = ZERO;
        end

        % This function returns an nx1 array of indexInt indicating the
        % beginning (+ offset) of each pattern match in the input.
        function [nbMatches, matches] = findPattern(obj, pattern, offset)
            % obj and pattern can be empty; offset is optional.
            if (nargin < 3)
                offset = ZERO;
            end
            coder.internal.prefer_const(pattern, offset);
            [objVal, objLen] = coder.internal.string.getCharValue(obj);
            [patVal, patLen] = coder.internal.string.getCharValue(pattern);

            % Pre-allocate enough space for the output;
            % Upper bound is given by objLen / patLen.
            if (patLen == ZERO) % Special case if pattern is empty.
                maxMatches = objLen + 1;
                stepSize = ONE;
            else
                maxMatches = coder.internal.indexDivide(objLen,patLen);
                stepSize = patLen;
            end
            matches = coder.nullcopy(zeros(maxMatches, 1, coder.internal.indexIntClass));
            nbMatches = ZERO;

            % Find the matching substrings;
            % If patLen > objLen then the loop has no iterations.
            i = ONE;
            while (i <= objLen - patLen + 1)
                j = ONE;
                while (j <= patLen && (objVal(i + j - 1) == patVal(j)))
                    j = j + 1;
                end
                if (j > patLen)
                    nbMatches = nbMatches + 1;
                    matches(nbMatches, 1) = i + offset;
                    i = i + stepSize;
                else
                    i = i + 1;
                end
            end
        end

        % This function returns an nx2 array of indexInt indicating the
        % beginning and end (excluded) of each pattern match in the input.
        function [nbMatches, matches] = findBetween(obj, patternStart, patternEnd, includeBoundaries)
            % obj, patternStart and patternEnd can be empty.
            coder.internal.prefer_const(patternStart, patternEnd, includeBoundaries);
            [objVal, objLen] = coder.internal.string.getCharValue(obj);
            [startVal, startLen] = coder.internal.string.getCharValue(patternStart);
            [endVal, endLen] = coder.internal.string.getCharValue(patternEnd);

            % Pre-allocate enough space for the output;
            % Upper bound is given by objLen / (startLen + endLen).
            if (startLen + endLen == ZERO) % Special case if both patterns are empty.
                nbMatches = objLen + ONE;
                matches = [(ONE:nbMatches).' (ONE:nbMatches).'];
                return;
            else
                maxMatches = coder.internal.indexDivide(objLen, startLen + endLen);
            end
            matches = coder.nullcopy(zeros(maxMatches, 2, coder.internal.indexIntClass));
            nbMatches = ZERO;

            startIndex = ZERO;
            patVal = char(startVal, endVal);
            patLen = startLen;
            k = ONE;

            % Find the matching substrings;
            % If patLen > objLen then the loop has no iterations.
            i = ONE;
            while (i <= objLen - patLen + 1)
                j = ONE;
                while (j <= patLen && (objVal(i + j - 1) == patVal(k, j)))
                    j = j + 1;
                end
                if (j > patLen)
                    if (startIndex == ZERO)
                        startIndex = i;
                        i = i + patLen;
                        patLen = endLen;
                        k = k + 1;
                    else
                        nbMatches = nbMatches + 1;
                        if (includeBoundaries)
                            matches(nbMatches, 1) = startIndex;
                            matches(nbMatches, 2) = i + patLen;
                        else
                            matches(nbMatches, 1) = startIndex + startLen;
                            matches(nbMatches, 2) = i;
                        end
                        i = i + patLen ;
                        patLen = startLen;
                        k = ONE;
                        startIndex = ZERO;
                    end
                else
                    i = i + 1;
                end
            end
        end

        function stitched = stitchRange(obj, newText, startPos, endPos)
            [objVal, objLen] = coder.internal.string.getCharValue(obj);
            [newVal, newLen] = coder.internal.string.getCharValue(newText);

            outputLen = objLen - (endPos - startPos) + newLen;
            coder.internal.assert(outputLen >= 0, 'Coder:builtins:Explicit', ...
                'Output string length must be non-negative.');
            assert(outputLen <= objLen + newLen); %<HINT>
            stitched = coder.nullcopy(blanks(outputLen));

            k = ONE;
            for i = 1:(startPos-1)
                stitched(k) = objVal(i);
                k = k + 1;
            end
            for j = 1:newLen
                stitched(k) = newVal(j);
                k = k + 1;
            end
            for i = endPos:objLen
                stitched(k) = objVal(i);
                k = k + 1;
            end
        end

        function stitched = stitchMatches(obj, newText, nbMatches, matches, removeLen)
            coder.internal.prefer_const(removeLen);
            [objVal, objLen] = coder.internal.string.getCharValue(obj);
            [newVal, newLen] = coder.internal.string.getCharValue(newText);

            outputLen = objLen;
            if isnumeric(removeLen)
                coder.internal.assert(removeLen >= 0, 'Coder:builtins:Explicit', ...
                    'Pattern length must be non-negative.');
                outputLen = outputLen + nbMatches * (newLen - removeLen);
            else
                for n = 1:nbMatches
                    outputLen = outputLen + newLen - (matches(n, 2) - matches(n, 1));
                end
            end
            coder.internal.assert(outputLen >= 0, 'Coder:builtins:Explicit', ...
                'Output string length must be non-negative.');
            assert(outputLen <= objLen + nbMatches * newLen); %<HINT>
            stitched = coder.nullcopy(blanks(outputLen));

            k = ONE;
            i = ONE;
            for n = 1:nbMatches
                while i < matches(n, 1)
                    stitched(k) = objVal(i);
                    k = k + 1;
                    i = i + 1;
                end
                for j = 1:newLen
                    stitched(k) = newVal(j);
                    k = k + 1;
                end
                if isnumeric(removeLen)
                    i = i + removeLen;
                else
                    i = matches(n, 2);
                end
            end
            while i <= objLen
                stitched(k) = objVal(i);
                k = k + 1;
                i = i + 1;
            end
        end

        function stitched = stitchBetween(obj, newText, nbMatches, matches)
            coder.inline('always');
            stitched = coder.internal.string.stitchMatches(obj, newText, nbMatches, matches, 'variable');
        end

        function [firstIndex, secondIndex] = findStripIndices(text, length, side, stripCharacters)
            switch side
                case SIDE_LEFT
                    firstIndex = coder.internal.string.findNonStripCharacter(text, length, stripCharacters, 'beginning');
                    secondIndex = length;
                case SIDE_RIGHT
                    firstIndex = coder.internal.indexInt(1);
                    secondIndex = coder.internal.string.findNonStripCharacter(text, length, stripCharacters, 'end');
                otherwise % case SIDE_BOTH
                    firstIndex = coder.internal.string.findNonStripCharacter(text, length, stripCharacters, 'beginning');
                    secondIndex = coder.internal.string.findNonStripCharacter(text, length, stripCharacters, 'end');
            end
        end

        function index = findNonStripCharacter(text, length, stripCharacters, beginningOrEnd)
            if strcmp(beginningOrEnd, 'beginning')
                startFromBeginning = true;
                i = ONE;
                ub = length + 1;
            else
                startFromBeginning = false;
                i = length;
                ub = ZERO;
            end
            index = ZERO;
            nonStripCharFound = false;
            while ~nonStripCharFound
                if i == ub || all(text(i) ~= stripCharacters)
                    nonStripCharFound = true;
                    index = i;
                end
                if startFromBeginning
                    i = i + 1;
                else
                    i = i - 1;
                end
            end
        end

        % string construction helper function for numeric inputs
        % displays number for integer types,
        % and may convert to scientific format for large floats.
        function val = int2strSci(obj)
            coder.internal.errorIf(isnan(obj), ...
                'Coder:toolbox:StringNumericNoNaN');
            coder.internal.assert(floor(obj) == obj, ...
                'Coder:toolbox:StringNumericIntegerInf');
            if coder.internal.isConst(obj)
                % If we've received a constant, defer to MATLAB to enable constant folding. We
                % forcibly call coder.const to avoid the need to perform a
                % value-based size computation of the resultant string here
                val = coder.const(char(feval('string',obj)));
                return
            end
            if ~isreal(obj)
                if imag(obj) < 0
                    p = '';
                else
                    p = '+';
                end
                val = [coder.internal.string.int2strSci(real(obj)),...
                    p, coder.internal.string.int2strSci(imag(obj)), 'i'];
                return
            end

            if isfloat(obj)
                obj = round(obj);
                if obj == 0
                    % Avoid negative zero
                    val = '0';
                    return
                end
                if isinf(obj)
                    if obj > 0
                        val = 'Inf';
                    else
                        val = '-Inf';
                    end
                    return
                end
                if isnan(obj)
                    val = 'NaN';
                    return
                end

                logMaxValue = eml_max(1 , ceil(log10(realmax(class(obj)))));
                printWidth = eml_min(12, logMaxValue) + 4;
                formatStr = ['%.' int2str(printWidth) 'g'];

                val = coder.internal.printNumToBuffer(obj, logMaxValue+11, printWidth+7, formatStr); % 7 chars among '-.e+###'
            else
                val = int2str(obj);
            end
        end
    end
end

%--------------------------------------------------------------------------

function checkRelopArgs(s,t)
coder.internal.assert((isstring(s) || ischar(s) || iscell(s)) && ...
    (isstring(t) || ischar(t) || iscell(t)), ...
    'MATLAB:string:ComparisonNotDefined', ...
    class(s), class(t));
coder.internal.errorIf((iscell(s) && ~iscellstr(s)) || ...
    (iscell(t) && ~iscellstr(t)), ...
    'MATLAB:string:CellInputMustBeCellArrayOfStrings');
end

%--------------------------------------------------------------------------

function c = normalizeChar(str, msg)
coder.inline('always');
coder.internal.prefer_const(msg);
if coder.internal.isConstTrue(isrow(str))
    c = str;
elseif isequal(size(str), [0 0]) % isempty(str) would be too lenient here
    c = EMPTY; % We use blanks(0) instead of '' so that c is always 1x?
else
    coder.internal.assert(isrow(str), msg);
    c = str(1, 1:size(str,2)); % Ensures first dim is of fixed size 1
end
end

function c = EMPTY
coder.inline('always');
c = blanks(0); % blanks(0) creates a 1x0 char array
end

%--------------------------------------------------------------------------

function side = matchSide(s,id)
if strcmpi(s,'left')
    side = SIDE_LEFT;
elseif strcmpi(s,'right')
    side = SIDE_RIGHT;
elseif strcmpi(s,'both')
    side = SIDE_BOTH;
else
    side = SIDE_UNKNOWN;
end
coder.internal.errorIf(side == SIDE_UNKNOWN, id);
end

function y = SIDE_LEFT
coder.inline('always');
y = uint8(0);
end

function y = SIDE_RIGHT
coder.inline('always');
y = uint8(1);
end

function y = SIDE_BOTH
coder.inline('always');
y = uint8(2);
end

function y = SIDE_UNKNOWN
coder.inline('always');
y = uint8(3);
end

%--------------------------------------------------------------------------

function n = ZERO
coder.inline('always');
n = coder.internal.indexInt(0);
end

function n = ONE
coder.inline('always');
n = coder.internal.indexInt(1);
end

%--------------------------------------------------------------------------

function [varargout] = functionNotSupported(fname)
coder.internal.prefer_const(fname);
coder.inline('always');
coder.internal.assert(false, ...
    'Coder:toolbox:FunctionDoesNotSupportDatatype',fname,'string');
[varargout{1:nargout}] = deal([]);
end

%--------------------------------------------------------------------------

function charVec = checkScalarChar(ipCharVec)
% When object arrays are supported consider using
% toolbox/eml/lib/matlab/strfun/private/isTextStrict.m
charVec = coder.internal.isConstTrue(ischar(ipCharVec) && isrow(ipCharVec));
end
