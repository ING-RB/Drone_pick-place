%PeerUtils
%   Utilities class

% Copyright 2014-2018 The MathWorks, Inc.

classdef PeerUtils < handle
    
    % constants representing the levels of debugging
    properties (Constant=true)
        NONE = uint64(0);
        PERFORMANCE = uint64(1);
        DEBUG = uint64(2);
        INFO = uint64(4);
        TIMES_SYMBOL = matlab.internal.display.getDimensionSpecifier;
    end

    % property to keep track of the current level of debugging
    properties (SetObservable=true, SetAccess='public', GetAccess='public', Dependent=false, Hidden=false)
        Debuglevel = uint64(0);
    end %properties

    % IsPrototype
    properties (SetObservable=true, SetAccess='public', GetAccess='public', Dependent=false, Hidden=false)
        % IsPrototype Property
        IsPrototype = false;
        IsTestingEnvironment = false;
        NumericsInLiveEditorOn = true;
        TablesInLiveEditorOn = true;
        SortTablesInLiveEditorOn = true;
        FilterTablesInLiveEditorOn = true;
    end %properties
    methods
        function storedValue = get.IsPrototype(this)
            storedValue = this.IsPrototype;
        end

        function set.IsPrototype(this, newValue)
            this.IsPrototype = logical(newValue);
        end
    end

    methods(Access='protected')
        function this = PeerUtils()
            this.Debuglevel = uint64(0);
            this.NumericsInLiveEditorOn = true;
            this.TablesInLiveEditorOn = true;
            this.SortTablesInLiveEditorOn = true;
            this.FilterTablesInLiveEditorOn = true;
        end
    end

    %PeerUtils Static Utility Methods
    methods(Static, Access='public')
        function obj = getInstance()
            mlock; % Keep persistent variables until MATLAB exits
            persistent utilsInstance;
            persistent logSubscribe;
            if isempty(utilsInstance) || ~isvalid(utilsInstance)
                utilsInstance = internal.matlab.legacyvariableeditor.peer.PeerUtils();
                logSubscribe = message.subscribe('/VELogChannel', @(es) internal.matlab.legacyvariableeditor.peer.PeerUtils.receivedLogMessage(es));
            end

            obj = utilsInstance;
        end       
        
        function formattedSize = getFormattedSize(s)
            if length(s)>3
                    formattedSize = sprintf('%d-D',length(s));
            else
                formattedSize = regexprep(num2str(s),' +', ...
                    internal.matlab.legacyvariableeditor.peer.PeerUtils.TIMES_SYMBOL);
            end
        end

        % returns class of variable
        function formattedClass = formatClass(cdata)
            if isa(cdata, 'internal.matlab.legacyvariableeditor.NullValueObject')
                % Treat the internal NullValueObject as not having a
                % class (we don't want it to show in the summary of a
                % variable, for example).
                formattedClass = '';
            else
                %TODO: need to account for global variables
                formattedClass = class(cdata);
                type='';
                if (isnumeric(cdata) && ~isreal(cdata))
                    type='complex ';
                end
                if (issparse(cdata))
                    if ~isreal(cdata)
                        type='sparse complex ';
                    else
                        type='sparse ';
                    end
                end
                formattedClass = [type formattedClass];
            end
        end

		% Creates a complete json string from key value pairs or a structure
        function jsonStr = toJSON(escapeValues, varargin)
            jsonStr = jsonencode(varargin);
            jsonStr = jsonStr(2:end-1);
        end

% 		% Creates a json string from key value pairs or an input structure
%         function jsonStr = toJSONContents(escapeValues, varargin)
%             if isempty(escapeValues)
%                 escapeValues = true;
%             end
%
%             propVals = varargin;
%
% 			% Check for a struct being passed in as argument
%             if (nargin == 2) && isstruct(varargin{1})
%                 s = varargin{1};
%                 fns = fieldnames(s);
%                 propVals = cell(1,2*length(fns));
%                 for i=1:length(fns)
%                     propVals{i*2-1} = fns{i};
%                     propVals{i*2} = s.(fns{i});
%                 end
%             elseif (nargin == 2) && isa(varargin{1}, 'containers.Map')
%                 s = varargin{1};
%                 fns = s.keys;
%                 propVals = cell(1,2*length(fns));
%                 for i=1:length(fns)
%                     propVals{i*2-1} = fns{i};
%                     propVals{i*2} = s(fns{i});
%                 end
%             elseif (nargin == 2) && iscell(varargin{1}) % Single cell array passed in
%                 propVals = varargin{1};
%             end
%             % TODO: Add object support
%
% 			% Check for key value pairs
%             if mod(length(propVals), 2) ~= 0
%                 error(message('MATLAB:codetools:variableeditor:PropertyValuePairsExpected'));
%             end
%
%             % Escape any invalid JSON characters
%             doRemoveArrayQuotes = false;
%             if escapeValues
%                 for i=1:length(propVals)
%                     if isa(propVals{i},'java.lang.String[]')
%                         propVals{i} = cell(propVals{i});
%                     end
%
%                     if ischar(propVals{i})
%                         propVals{i} = internal.matlab.legacyvariableeditor.peer.PeerUtils.escapeJSONValue(propVals{i});
%                     elseif iscellstr(propVals{i})
%                         quotedStrings = cellfun(@(x) ['"' internal.matlab.legacyvariableeditor.peer.PeerUtils.escapeJSONValue(x) '",'], ...
%                             propVals{i}, 'UniformOutput', false);
%                         if iscolumn(quotedStrings)
%                             quotedStrings = quotedStrings';
%                         end
%                         propVals{i} = ['[' strjoin(quotedStrings) ']'];
%
%                         % Remove trailing comma
%                         propVals{i} = strrep(propVals{i}, ',]', ']');
%                         doRemoveArrayQuotes = true;
%                     else
%                         try
%                             propVals{i} = mat2str(propVals{i});
%                         catch err
%                             disp(err);
%                         end
%                     end
%                 end
%             end
%
% 			% TODO: Loop through KV pairs and check for other structures and call toJSON on those
%
% 			%Create format for key value pairs
%             fmt = repmat(',"%s":"%s"',1,length(propVals)/2);
%             jsonStr = sprintf(fmt,propVals{:});
% 			% Remove leading comma
%             jsonStr = jsonStr(2:length(jsonStr));
%
%
%             % Remove any quotes around arrays
%             if doRemoveArrayQuotes
%                 jsonStr = strrep(jsonStr, '"[', '[');
%                 jsonStr = strrep(jsonStr, ']"', ']');
%             end
%         end

        % Escapes a string for JSON
        function jsonStr = escapeJSONValue(strValue)
            jsonStr = strrep(strValue,'\','\\');
            jsonStr = strrep(jsonStr,'"','\"');
            jsonStr = strrep(jsonStr,char(9),'\t');
        end

        % returns true if the current debugging level includes DEBUG
        function debug = isDebug()
            utilsInstance = internal.matlab.legacyvariableeditor.peer.PeerUtils.getInstance();
            debug = bitand(utilsInstance.Debuglevel, internal.matlab.legacyvariableeditor.peer.PeerUtils.DEBUG);
        end

        % returns true is the current debugging level includes INFO
        function info = isInfo()
            utilsInstance = internal.matlab.legacyvariableeditor.peer.PeerUtils.getInstance();
            info = bitand(utilsInstance.Debuglevel, internal.matlab.legacyvariableeditor.peer.PeerUtils.INFO);
        end

        % adds/removes DEBUG to the existing debug level based on the value passed in
        function setDebug(value)
            utilsInstance = internal.matlab.legacyvariableeditor.peer.PeerUtils.getInstance();
            newLevel = utilsInstance.Debuglevel;

            % if setDebug is called with true or no arguments then, we turn
            % on the debug flag and the existing log level
            % logic - existinglevel || debug
            if isempty(value) || value
                newLevel = internal.matlab.legacyvariableeditor.peer.PeerUtils.addLogLevel(internal.matlab.legacyvariableeditor.peer.PeerUtils.DEBUG);
            else
                % if setDebug is called with false, then we turn off
                % debugging if it is true
                if internal.matlab.legacyvariableeditor.peer.PeerUtils.isDebug()
                    newLevel = internal.matlab.legacyvariableeditor.peer.PeerUtils.removeLogLevel(internal.matlab.legacyvariableeditor.peer.PeerUtils.DEBUG);
                end
            end

            internal.matlab.legacyvariableeditor.peer.PeerUtils.setLogLevel(newLevel);

        end

        function receivedLogMessage(msg)
            if strcmp(msg.eventType,'setLogFlagFromClient')
                utilsInstance = internal.matlab.legacyvariableeditor.peer.PeerUtils.getInstance();
                utilsInstance.Debuglevel = msg.LogLevel;
            end
        end

        function setLogLevel(logLevel)
            utilsInstance = internal.matlab.legacyvariableeditor.peer.PeerUtils.getInstance();
            utilsInstance.Debuglevel = uint64(logLevel);
            publishData = struct('eventType','setLogFlagFromServer');
            publishData.flag = logLevel;
            message.publish('/VELogChannel',publishData);
        end

        function newLevel = addLogLevel(logLevel)
            utilsInstance = internal.matlab.legacyvariableeditor.peer.PeerUtils.getInstance();
            newLevel = bitor(utilsInstance.Debuglevel,logLevel);
        end

        function newLevel = removeLogLevel(logLevel)
            utilsInstance = internal.matlab.legacyvariableeditor.peer.PeerUtils.getInstance();
            if utilsInstance.Debuglevel >= logLevel
                newLevel = bitxor(utilsInstance.Debuglevel,logLevel);
            end
        end

        function prototype = isPrototype()
            utilsInstance = internal.matlab.legacyvariableeditor.peer.PeerUtils.getInstance();
            prototype = utilsInstance.IsPrototype;
        end

        function setPrototype(isPrototype)
            utilsInstance = internal.matlab.legacyvariableeditor.peer.PeerUtils.getInstance();
            utilsInstance.IsPrototype = isPrototype;
        end

        function sendPeerEvent(peerNode, eventType, varargin)
            % Check for paired values
            if nargin<2 || rem(nargin-2, 2)~=0
                error(message('MATLAB:codetools:variableeditor:UseNameRowColTriplets'));
            end

            hm = java.util.HashMap;
            hm.put('source', 'server');
            s = struct();
            for i=1:2:nargin-2
                hm.put(varargin{i},varargin{i+1});
                s.(varargin{i}) = varargin{i+1};
            end

            if any(strcmp(methods(peerNode),'dispatchPeerEvent'))
                peerNode.dispatchPeerEvent(eventType,peerNode,hm);
            else
                s.('type') = eventType;
                peerNode.dispatchEvent(s);
            end
        end

        function logDebug(peerNode, class, method, message, varargin)
            internal.matlab.legacyvariableeditor.peer.PeerUtils.logMessage(...
                peerNode, class, method, message, ...
                internal.matlab.legacyvariableeditor.peer.PeerUtils.DEBUG, ...
                varargin{:});
        end

        function logMessage(peerNode, class, method, thismessage, logLevel, varargin)
            utilsInstance = internal.matlab.legacyvariableeditor.peer.PeerUtils.getInstance();
            if bitand(utilsInstance.Debuglevel, logLevel)
                try
                    msgStr = [class '.' method];
                    if ~isempty(thismessage)
                        msgStr = [msgStr ': [' thismessage ']'];
                    end
                    msgStr = [msgStr ' @ [' char(datetime('now', 'Format', 'yyyy/MM/dd HH:mm:ss.SSS')) ']'];
                    for i=1:nargin-5
                        if i==1
                            msgStr = [msgStr ' (']; %#ok<AGROW>
                        else
                            msgStr = [msgStr ', ']; %#ok<AGROW>
                        end
                        if ischar(varargin{i})
                            msgStr = [msgStr varargin{i}]; %#ok<AGROW>
                        elseif isnumeric(varargin{i}) || islogical(varargin{i})
                            msgStr = [msgStr mat2str(varargin{i})]; %#ok<AGROW>
                        else
                            % Try to convert to a char
                            msgStr = [msgStr char(varargin{i})]; %#ok<AGROW>
                        end
                    end
                    if nargin>4
                        msgStr = [msgStr ')'];
                    end
                     logData = struct('eventType','log','message',msgStr);
                     message.publish('/VElogmessage', logData);
                catch e
                    warning(['LogError: ' e.message]);
                end
            end
        end

        function numType = isNumericType(type)
            numType = any(strcmp(type,{'double','single','int8','int16','int32','int64','uint8','uint16','uint32','uint64'}));
        end


        % If the data is string, just replace the first and last "" with ''
        % for validation. Any "" within the string is legitimate and should
        % not be replaced, but escaped
        function data = parseStringQuotes(data, classType)
            % Evaluate String to check if it begins and ends with "" for replacement,
            % else append the string with ""
            if (strcmp(classType, 'string') && ~isempty(data))
                data = regexprep(data, '(^''|''$)', '');
                data = regexprep(data, '(^"|"$)', '');
                if contains(data, '"') && ~contains(data, '""')
                    data = strrep(data, '"', '""');
                end
                data = ['"' data '"'];
            end
        end

        function newVal = removeOuterQuotes(inVal)
            newVal = inVal;
            newVal = regexprep(newVal,'^\s*''','');
            newVal = regexprep(newVal,'\s*''$','');
        end

        % Function handles \n and \t from strings by converting them to
        % char arrays with char(10) and char(9) respectively.
        % For example, 'a\nb\tc' -> ['a' char(10) 'b' char(10) 'c']
        function formattedData = escapeSpecialCharsForStrings(data)
            tabChar = char(8594);
            if any(regexp(data, '\n|\t')) || ...
                    contains(data, matlab.internal.display.getNewlineCharacter(newline)) || ...
                    contains(data, tabChar)
                % Input data already comes enclosed in '',
                data = regexprep(data,'(^''|''$)','');
                s = strrep(data, newline, '" + newline + "');
                s = strrep(s, matlab.internal.display.getNewlineCharacter(newline), '" + newline + "');
                s = strrep(s, sprintf('\t'), '" + char(9) + "');
                s = strrep(s, tabChar, '" + char(9) + "');
                formattedData = char(s);
            else
                formattedData = data;
            end
        end
        
        % Formats the string to display as shown on the client
        function formattedData = formatStringClientView(data)
            formattedData = regexprep(data,'\n', '\x21b5');
            formattedData = regexprep(formattedData,'\t', '\x2192'); 
        end
        
        % Formats the client string to display as per server characters
        function formattedData = formatStringToServerViewFromClientView(data)
            formattedData = regexprep(data,  '\x21b5', '\n');
            formattedData = regexprep(formattedData, '\x2192', '\t'); 
        end

        % Escape \ and " as they do not go via peerUtils.toJSON for
        % cellarrays and structarrays. Escape \n and \t to \\n and \\t respectively for
        % String datatypes alone
        function data = formatGetJSONforCell(rawVal, val)
            data = strrep(strrep(val , '\', '\\'),'"','\"');
            if internal.matlab.datatoolsservices.FormatDataUtils.checkIsString(rawVal) && isscalar(rawVal)
                data = regexprep(data,'\n','\\n');
                data = regexprep(data,'\t','\\t');
            end
        end

        function setNumericsInLiveEditorOn(state)
            utilsInstance = internal.matlab.legacyvariableeditor.peer.PeerUtils.getInstance();
            utilsInstance.NumericsInLiveEditorOn = state;
            message.publish('/LiveEditorNumerics', struct('status', state));
        end

        function feature = isNumericsInLiveEditorOn()
            utilsInstance = internal.matlab.legacyvariableeditor.peer.PeerUtils.getInstance();
            feature = utilsInstance.NumericsInLiveEditorOn;
        end

        function setTablesInLiveEditorOn(state)
            utilsInstance = internal.matlab.legacyvariableeditor.peer.PeerUtils.getInstance();
            utilsInstance.TablesInLiveEditorOn = state;
            message.publish('/LiveEditorTables', struct('status', state));
        end

        function feature = isTablesInLiveEditorOn()
            utilsInstance = internal.matlab.legacyvariableeditor.peer.PeerUtils.getInstance();
            feature = utilsInstance.TablesInLiveEditorOn;
        end

        function setSortTablesInLiveEditorOn(state)
            utilsInstance = internal.matlab.legacyvariableeditor.peer.PeerUtils.getInstance();
            utilsInstance.SortTablesInLiveEditorOn = state;
        end
        
        function setFilterTablesInLiveEditorOn(state)
            utilsInstance = internal.matlab.legacyvariableeditor.peer.PeerUtils.getInstance();
            utilsInstance.FilterTablesInLiveEditorOn = state;
        end

        function feature = isSortTablesInLiveEditorOn()
            utilsInstance = internal.matlab.legacyvariableeditor.peer.PeerUtils.getInstance();
            feature = utilsInstance.SortTablesInLiveEditorOn;
        end
        
        function feature = isFilterTablesInLiveEditorOn()
            utilsInstance = internal.matlab.legacyvariableeditor.peer.PeerUtils.getInstance();
            feature = utilsInstance.FilterTablesInLiveEditorOn;
        end
       
        function feature = isTestingOn()
            utilsInstance = internal.matlab.legacyvariableeditor.peer.PeerUtils.getInstance();
            feature = utilsInstance.IsTestingEnvironment;
        end
        
        function setTestingOn(state)
            utilsInstance = internal.matlab.legacyvariableeditor.peer.PeerUtils.getInstance();
            utilsInstance.IsTestingEnvironment = state;
        end
  

        % This function computes the grouped column information for tables
        function tableMetaData = getTableMetaData(variableValue)
            tableMetaData = cumsum([1 varfun(@(x) ...
                max(size(x,2)*ismatrix(x)*~ischar(x)*~isa(x,'dataset')*~isa(x,'table') + ...
                ischar(x)+isa(x,'dataset')+isa(x,'table'), 1), ...
                variableValue(1,1:min(end,50)),'OutputFormat','uniform')]);
        end

        function context = isLiveEditor(usercontext)
            context = ~isempty(usercontext) && contains(usercontext, 'liveeditor');
        end

        function isSortable = checkIsSortable(variableValue, isPreview)
            featureOn = internal.matlab.legacyvariableeditor.peer.PeerUtils.isSortTablesInLiveEditorOn();
            f = @(val) (featureOn && ~isPreview && ~(((iscell(val) && ~iscellstr(val)) || isstruct(val) || isinteger(val) && ~isreal(val) || ...
                (isobject(val) && ~iscategorical(val) && ~isstring(val) && ~isdatetime(val) && ~isduration(val)) ...
                || length(size(val)) > 2)));
            isSortable = varfun(f, variableValue, 'OutputFormat', 'uniform');
        end
        
        function isFilterable = checkIsFilterable(variableValue, isPreview)
            featureOn = internal.matlab.legacyvariableeditor.peer.PeerUtils.isFilterTablesInLiveEditorOn();
            f = @(val) (featureOn && ~isPreview && ~(((iscell(val) && ~iscellstr(val)) || isstruct(val) || ...
                (isobject(val) && ~iscategorical(val) && ~isstring(val) && ~isdatetime(val) && ~isduration(val)) ...
                || (isnumeric(val) && ~isreal(val)) || length(size(val)) > 2 || size(val,2) > 1)));
            isFilterable = varfun(f, variableValue, 'OutputFormat', 'uniform');
        end

        function orig_state = disableWarning()
            % return original state for resume later.
            orig_state = warning;
            
            % disable warning
            warning('off', 'all');
        end
        
        function resumeWarning(orig_state)
            warning(orig_state);
        end
        
        function [quotes, braces_o, braces_c] = getCodegenConstructsForDatatype(datatype)
            if strcmp(datatype, 'string')
                quotes = char(34);
                braces_o = char(91);
                braces_c = char(93);
            else
                quotes = char(39);
                braces_o = char(123);
                braces_c = char(125);
            end
        end
        
        function cleanFiltNames = getCleanedNamesForCodegen(names, quotes, cClass)
            % Using a regex to escape any single quotes or double quotes
            % contained in the names
            names = regexprep(cellstr(names),[quotes],[quotes quotes]);
            if ~strcmp(cClass, 'logical')
                % Using a regex to escape any newline charecters contained in
                % the names.
                if strcmp(cClass, 'string')
                    % if it is a strings, using string concatenation code
                    names = regexprep(cellstr(names), newline, ...
                        [quotes '+newline+' quotes]);
                    names = regexprep(cellstr(names), char(9), ...
                        [quotes '+char(9)+' quotes]);
                else
                    % If it is a Cellstr or categorical, use the appropriate
                    % concatenation code for newline charecters.

                    % Using a non-printing charecter as a placeholder for the
                    % whilespace so that cats and cellstrs which have the
                    % keyword newline as part of their strings do not get the
                    % square braces.
                    names = regexprep(cellstr(names), newline, ...
                        [quotes char(31) 'newline' char(31) quotes]);
                    names = regexprep(cellstr(names), char(9), ...
                        [quotes char(31) 'char(9)' char(31) quotes]);
                end
                temp = cell(1, length(names));
                for i = 1:length(names)
                    if contains(names{i}, [char(31) 'newline' char(31)]) || ...
                            contains(names{i}, [char(31) 'char(9)' char(31)])
                        
                        % Replacing the non-printing charecter [char(31)] with
                        % the charecter for whitespace [char(32)] to generate the
                        % optimal code
                        names{i} = regexprep(names{i}, char(31), char(32));
                        % cellstr or cats need to wrap the value in square
                        % brackets for correct code generation
                        temp{i} = [char(91), quotes, names{i}, quotes, char(93)];
                    else
                        % If is it string, the newline command will
                        % automatically get concatenated in the correct manner
                        % if needed
                        temp{i} = [quotes, names{i}, quotes];
                    end
                end
            else
                temp = names;
            end
            cleanFiltNames = temp;
        end
    end
end
