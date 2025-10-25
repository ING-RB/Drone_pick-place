classdef memmapfile

    properties (Dependent)
        Filename;
        Writable;
        Offset;
        Format;
        Repeat;
    end

    properties (Dependent, Transient)
        Data; %#ok<MGMD> The `Data` property is implemented via subsref/subsasgn.
    end

    % Backward compatibility properties to support loading memmapfile instances from
    % MAT-files created prior to R2010b.
    properties (Hidden)

        filename = '';
        writable = false;
        offset   = 0;
        format   = 'uint8';
        repeat   = inf;
    end

    % Private properties of the memory-mapped object NOTE: All private properties should
    % have mixed case names with at least one medial capital letter so that they are not
    % found by @memmapfile/subsref and @memmapfile/subsasgn, which get/set
    % obj.(hCapitalize(fieldname)).
    properties (Dependent, Access=private)
        DataHandle;
        FileSize; % size of file.
    end

    properties (Hidden, Access=private)
        % Backward compatibility properties to support loading memmapfile instances from
        % MAT-files created prior to R2010b.
        fileSize = 0;
    end

    properties (Access=private, Transient)
        CheckAlignmentNeeded = any(strcmp(computer, {'SOL2', 'SOL64'}));
        DataHandleHolder;
    end

    methods
        function v = get.Filename(obj)
            v = obj.filename;
        end

        function obj = set.Filename(obj, v)
            obj.filename = v;
        end

        function obj = set.writable(obj, v)
            if ~isscalar(v) || ~isa(v, 'logical')
                error(message('MATLAB:memmapfile:illegalWritableSetting'));
            end
            obj.writable = v;
        end

        function v = get.Writable(obj)
            v = obj.writable;
        end

        function obj = set.Writable(obj, v)
            obj.writable = v;
        end

        function obj = set.offset(obj, v)
            if ~isscalar(v) || ~isnumeric(v) || ~isreal(v)
                error(message('MATLAB:memmapfile:illegalOffsetType'))
            elseif ~isfinite(v) || v < 0 || (~isinteger(v) && v ~= fix(v))
                error(message('MATLAB:memmapfile:illegalOffsetValue'));
            end
            v = double(v);
            obj.offset = v;
        end

        function v = get.Offset(obj)
            v = obj.offset;
        end

        function obj = set.Offset(obj, v)
            obj.offset = v;
        end

        % FORMAT can be a cell array of the form:
        % {'uint64', [30 4 10], 'x'}
        % so we need to handle that case separately from
        % the case where FORMAT is a char vector.
        function obj = set.format(obj, v)
            if iscell(v)
                [v{:}] = convertStringsToChars(v{:});
            else
                v = convertStringsToChars(v);
            end
            if ~hIsValidFormat(v)
                error(message('MATLAB:memmapfile:illegalFormatSetting'));
            end
            obj.format = v;
        end

        function v = get.Format(obj)
            v = obj.format;
        end

        function obj = set.Format(obj, v)
            obj.format = v;
        end

        function obj = set.repeat(obj, v)
            if ~isscalar(v) || ~isnumeric(v) || ~isreal(v)
                error(message('MATLAB:memmapfile:illegalRepeatType'));
            elseif isnan(v) || v <= 0 || (~isinteger(v) && v ~= fix(v))
                error(message('MATLAB:memmapfile:illegalRepeatValue'));
            end
            v = double(v);
            obj.repeat = v;
        end

        function v = get.Repeat(obj)
            v = obj.repeat;
        end

        function obj = set.Repeat(obj, v)
            obj.repeat = v;
        end

        function obj = set.FileSize(obj, v)
            obj.fileSize = v;
        end

        function v = get.FileSize(obj)
            v = obj.fileSize;
        end

        % Need to bump internal reference count of DataHandle if MATLAB is making this object
        % a copy of another object. That happens when this object's DataHandle is [], and v
        % is _not_ 0. If DataHandle is not empty, then we are updating the handle internally
        % (due to an unmap).  If v is 0, then we are constructing the object from scratch, or
        % loading the object from disk, since DataHandle is transient.
        function obj = set.DataHandle(obj, v)
            if isempty(obj.DataHandleHolder) || isequal(v, 0)
                if isempty(v) || isequal(v, 0)
                    % There's no memory map to share, so create a new DataHandle.
                    v = matlab.iofun.internal.memmapfile.hcreatenewdatahandle();
                end
            end
            obj.DataHandleHolder = memmap_data_handle_holder(v);
        end

        function dh = get.DataHandle(obj)
            if ~isempty(obj.DataHandleHolder)
                dh = obj.DataHandleHolder.dataHandle;
            else
                dh = 0;
            end
        end
    end

    methods (Access=private)

        % Compute whether accessing data with the specified format/offset/repeat would lead to an
        % unaligned data exception.
        function bad = hIsUnaligned(obj)
            bad = false;
            if iscell(obj.Format)
                loc = obj.Offset;
                % If we can run through the full frame twice legally, we should be able to run
                % through it infinitely many times, by induction. If repeat is only 1, we only need
                % to get through one frame to be legal.
                for frame = 1:min(2, obj.Repeat)
                    for elem = 1:size(obj.Format, 1)
                        if mod(loc, hFrameSize(obj.Format{elem,1})) ~= 0
                            bad = true;
                            return;
                        end
                        loc = loc + hFrameSize(obj.Format(elem,:));
                    end
                    % This exits the method if we can not fit two frames in the file starting from the
                    % offset, and the repeat is set to inf.  In this case if there are no offset problems
                    % in the first iteration, it is ok.
                    if (obj.Repeat == inf) &&(((loc - obj.Offset) * 2) + obj.Offset) > obj.FileSize
                        return;
                    end

                end
            else

                if mod(obj.Offset, hFrameSize(obj.Format)) ~= 0
                    bad = true;
                    return;
                end
            end

        end % hIsUnaligned

        function hCreateMap(obj)
            if obj.CheckAlignmentNeeded && hIsUnaligned(obj)
                error(message('MATLAB:memmapfile:illegalAlignment'));
            end

            if isinf(obj.Repeat)
                numberOfFrames = 1;
            else
                numberOfFrames = obj.Repeat;
            end

            if hFrameSize(obj.Format) * numberOfFrames + obj.Offset > obj.FileSize
                error(message('MATLAB:memmapfile:fileTooSmall', obj.Filename));
            end

            mapfileInputStruct.filename = obj.Filename;
            mapfileInputStruct.writable = obj.Writable;
            if obj.Repeat == Inf
                mapfileInputStruct.numElements = 0;
            else
                mapfileInputStruct.numElements = obj.Repeat;
            end
            mapfileInputStruct.offset = obj.Offset;
            mapfileInputStruct.format = obj.Format;
            mapfileInputStruct.dataHandle = obj.DataHandle;

            matlab.iofun.internal.memmapfile.hMapFile(mapfileInputStruct);
        end % hCreateMap

        function siz = hGetDataSize(obj)
            framesAvailable = fix((obj.FileSize - obj.Offset) / hFrameSize(obj.Format));
            if obj.Repeat == Inf
                siz = [max(framesAvailable, 0) 1];
            elseif framesAvailable < obj.Repeat
                siz = [0 1];
            else
                siz = [obj.Repeat 1];
            end
        end % hGetDataSize

        % Update filename field of memmapfile obj.
        %  * Make sure file is accessible.
        %  * Replace filename with a full path version if it refers to a file on the
        %  matlabpath
        %    or is a partial path name.
        %  * Recompute cached size of file.
        function obj = hChangeFilename(obj, filename)
            filename = convertStringsToChars(filename);
            % Validate type of filename
            if ~ischar(filename) || ~isvector(filename) || size(filename, 1) ~= 1
                error(message('MATLAB:memmapfile:illegalFilenameType'));
            end

            [fid, reason] = fopen(filename);
            if fid == -1
                error(message('MATLAB:memmapfile:inaccessibleFile', filename, reason));
            end

            obj.Filename = fopen(fid); % if file found on MATLABPATH, fopen will return full path
            % to found file.

            fseek(fid, 0, 'eof');
            obj.FileSize = ftell(fid);
            fclose(fid);

        end % hChangeFilename

        % subsasgn to Data field when it contains a numeric array.
        function [valid, s, newval] = hParseNumericDataSubsasgn(obj, s, newval)
            valid = false;
            lenS = length(s);

            if lenS == 1
                % X.DATA = NEWVAL
                LHS = subsref(obj, s); % get array being assigned to

                if numel(LHS) == numel(newval)
                    if strcmp(class(LHS), class(newval))
                        % Map the operation to X.DATA(:,:) = F(NEWVAL) (where F reshapes NEWVAL suitably)
                        [s, newval] = hMapToTwoColonIndices(LHS, s, newval);
                        valid = true;
                    else
                        error(message('MATLAB:memmapfile:classMismatch'));
                    end
                else
                    error(message('MATLAB:memmapfile:sizeMismatch'));
                end
            elseif s(2).type(1)=='('
                % X.DATA(INDS)? =
                if lenS == 2
                    % X.DATA(INDS) = NEWVAL - this is legal and handled by hSubsasgn as is.

                    % Check for out of bound and single-colon indices.
                    LHS = subsref(obj, s(1)); % get array being assigned to
                    if hSubsasgnIndexOutOfRange(LHS, s(2).subs) || ...
                            hSubsasgnIsSubscriptedDeletion(s(2).subs, newval)
                        error(message('MATLAB:memmapfile:dataFieldSizeFixed'));
                    else
                        [s, newval] = hFixSubscriptedColonAssignment(LHS, s, newval);
                        valid = true;
                    end
                end
            end

        end % hParseNumericDataSubsasgn

        % Handle subsasgn to Data field when it contains a structure array.
        function [valid, s, newval] = hParseStructDataSubsasgn(obj, s, newval)
            valid = false; % When this is set to true, LHS must have already been defined.

            % x.Data? = FOO
            if isscalar(s)
                % x.Data = FOO
                error(message('MATLAB:memmapfile:illegalDataFieldModification'));
            elseif s(2).type(1) == '.'
                % x.Data.BAR? = FOO
                if length(s)==2
                    % x.Data.BAR = FOO -  same as x.Data(:).BAR = FOO  -
                    s = [s(1) substruct('()', {':'}) s(2:end)];
                elseif s(3).type(1) == '('
                    % x.Data.BAR()? = FOO
                    if length(s) == 3
                        % x.Data.BAR() = FOO -  same as x.Data(:).BAR() = FOO  -
                        s = [s(1) substruct('()', {':'}) s(2:end)];
                    end
                end
            end

            if s(2).type(1) == '('
                % x.Data()? = FOO
                if length(s) == 2
                    % x.Data(inds) = FOO
                    error(message('MATLAB:memmapfile:illegalDataFieldModification'));
                elseif s(3).type(1) == '.'
                    % x.Data().BAR? = FOO
                    if length(s) == 3
                        % x.Data().BAR = FOO

                        if hSubsasgnIndexOutOfRange(subsref(obj, s(1)), s(2).subs)
                            error(message('MATLAB:memmapfile:dataFieldSizeFixed'));
                        end
                        LHS = subsref(obj, s); % get array being assigned to

                        if numel(LHS) == numel(newval)
                            if strcmp(class(LHS), class(newval))
                                % Map the operation to X.DATA.BAR(:,:) = F(NEWVAL) (where F reshapes NEWVAL
                                % suitably.)
                                [s, newval] = hMapToTwoColonIndices(LHS, s, newval);
                                valid = true;
                            else
                                error(message('MATLAB:memmapfile:classMismatchForSubfield'));
                            end
                        else
                            error(message('MATLAB:memmapfile:sizeMismatchForSubfield'));
                        end
                    elseif s(4).type(1) == '('
                        % x.Data().BAR()? = FOO
                        if length(s) == 4
                            % x.Data().BAR() = FOO Check for out of bound and single-colon indices.
                            if hSubsasgnIndexOutOfRange(subsref(obj, s(1)), s(2).subs)
                                error(message('MATLAB:memmapfile:dataFieldSizeFixed'));
                            end
                            LHS = subsref(obj, s(1:3)); % get array being assigned to

                            if hSubsasgnIndexOutOfRange(LHS, s(4).subs) || ...
                                    hSubsasgnIsSubscriptedDeletion(s(4).subs, newval)
                                error(message('MATLAB:memmapfile:dataSubfieldSizeFixed'));
                            else
                                [s, newval] = hFixSubscriptedColonAssignment(LHS, s, newval);
                                valid = true;
                            end
                        end
                    end
                end
            end

        end % hParseStructDataSubsasgn

        % Handlesubsasgn to Data field.
        function hDoDataSubsasgn(obj, s, newval)
            if ischar(obj.Format)
                [valid, s, newval] = hParseNumericDataSubsasgn(obj, s, newval);
            else
                [valid, s, newval] = hParseStructDataSubsasgn(obj, s, newval);
            end

            if valid
                if isnumeric(newval) && ~isreal(newval)
                    error(message('MATLAB:memmapfile:illegalComplexAssignment'));
                end
                matlab.iofun.internal.memmapfile.hSubsasgn(obj.DataHandle, s(2:end), newval);
            else
                error(message('MATLAB:memmapfile:illegalSubscriptedAssignment'))
            end
        end % hDoDataSubsasgn

        % Given a subscript structure, s, that is known to index a memmapfile's Data field, determine
        % if s would attempt to assign or reference a comma-separated list.
        function isCSL = hIsCommaSeparatedListOperation(obj, s)
            isCSL = false;
            lenS = length(s);
            % If length(s) == 1, then this is just obj.Data
            if lenS > 1
                % Check if Data represents a struct
                if iscell(obj.Format)
                    % Check if paren-indexing the struct.
                    if s(2).type(1) == '('
                        % Check for presence of dot-indexing the results of obj.Data(<inds>)
                        if lenS > 2 && s(3).type(1) == '.'
                            for i = 1:length(s(2).subs)
                                index = s(2).subs{i};
                                if isnumeric(index) || (ischar(index) && strcmp(index, ':') == 0)
                                    % more or less than one numeric index is a CSL.
                                    if length(index) ~= 1
                                        isCSL = true;
                                    end
                                elseif islogical(index)
                                    % more or less than one logical true index is a CSL
                                    if sum(index) ~= 1
                                        isCSL = true;
                                    end
                                else % is ':'
                                    % Data field must be a column vector, so ':' can only ever resolve to a non-scalar
                                    % index when it is the first index.
                                    if i == 1
                                        % If the first dimension of Data is not 1, the ':' index generates a CSL.
                                        dataSize = hGetDataSize(obj);
                                        if dataSize(1) ~= 1
                                            isCSL = true;
                                        end
                                    end
                                end
                            end
                        end
                        % If not paren-indexing the struct, make sure it is a scalar
                    elseif s(2).type(1) == '.'
                        % OBJ.DATA.FIELD will generate a CSL if OBJ.DATA is not scalar.
                        dataSize = hGetDataSize(obj);
                        isCSL = dataSize(1) ~= 1;
                    end
                end
            end

        end % hIsCommaSeparatedListOperation
    end % methods

    methods
        function obj = memmapfile(filename, varargin)

            narginchk(1, nargin);

            if rem(length(varargin), 2) ~= 0
                error(message('MATLAB:memmapfile:UnpairedParamsValues'));
            end

            obj.DataHandle = 0;
            obj = hChangeFilename(obj, filename);

            [varargin{:}] = convertStringsToChars(varargin{:});

            % Parse param-value pairs
            for i = 1:2:length(varargin)

                if ~ischar(varargin{i})
                    error (message('MATLAB:memmapfile:illegalParameter', i));
                end

                fieldname = varargin{i};
                if hIsPublicProperty(fieldname) && ~any(strcmpi(fieldname, {'Data', 'Filename'}))
                    obj.(hCapitalize(fieldname)) = varargin{i+1};
                else
                    error(message('MATLAB:memmapfile:unrecognizedParameter', varargin{ i }));
                end
            end

        end % Constructor

        function mInfo = get(obj, property)
            if nargin == 1
                out.Filename = obj.Filename;
                out.Writable = obj.Writable;
                out.Offset = obj.Offset;
                out.Format = obj.Format;
                out.Repeat = obj.Repeat;
                out.Data = subsref(obj, substruct('.', 'Data'));

                if nargout == 0
                    disp(out);
                else
                    mInfo = out;
                end
            else
                property = convertStringsToChars(property);
                if ischar(property)
                    if strcmpi(property, 'Data')
                        mInfo = subsref(obj, substruct('.', 'Data'));
                    elseif hIsPublicProperty(property)
                        mInfo = obj.(hCapitalize(property));
                    else
                        error(message('MATLAB:memmapfile:get:unknownProperty', property));
                    end
                elseif iscellstr(property)
                    % Make sure property is a row vector.
                    property = property(:)';
                    mInfo = cell(1, length(property));
                    for i = 1:length(property)
                        mInfo{i} = get(obj, property{i});
                    end
                else
                    error(message('MATLAB:memmapfile:illegalPropertyType'));
                end
            end

        end % GET method

        function disp(obj)
            %

            % %12s leaves exactly 4 spaces before the longest attribute, 'Filename', and lines
            % the other strings up by the colon, like how struct display works.
            fprintf(1, '%12s: ''%s''\n', 'Filename', obj.Filename);
            fprintf(1, '%12s: %s\n', 'Writable', mat2str(obj.Writable));
            fprintf(1, '%12s: %d\n', 'Offset', obj.Offset);

            fmt = obj.Format;
            if ischar(fmt)
                fprintf(1, '%12s: ''%s''\n', 'Format', fmt);
            else
                fprintf(1, '%12s: {', 'Format');
                for i = 1:size(fmt, 1)
                    if i > 1
                        fprintf(1, '%15s', '');
                    end

                    fprintf(1, '''%s'' [', fmt{i,1});
                    siz = fmt{i,2};
                    fprintf(1, '%d ', siz(1:end-1));
                    fprintf(1, '%d] ''%s''', siz(end), fmt{i,3});
                    if i == size(fmt, 1)
                        fprintf(1, '}');
                    end
                    fprintf('\n');
                end
            end

            fprintf(1, '%12s: %d\n', 'Repeat', obj.Repeat);

            % Don't print out all of Data, it could be really big. Print a summary instead.
            fprintf(1, '%12s: ', 'Data');

            siz = hGetDataSize(obj);

            if iscell(obj.Format)
                fprintf(1, ['%ld' matlab.internal.display.getDimensionSpecifier '%ld struct array with '], siz);
                fprintf(1, 'fields:\n');
                fprintf(1, '%17s\n', obj.Format{:,3});
            else
                fprintf(1, ['%ld' matlab.internal.display.getDimensionSpecifier '%ld %s array\n'], siz, obj.Format);
            end

            if strcmp(matlab.internal.display.formatSpacing, 'loose')
                fprintf(1, '\n');
            end

        end % Disp method

    end % methods

    methods (Hidden)

        function obj = subsasgn(obj, s, newval)
            %
            %   Supported property names are 'Format', 'Repeat', 'Offset', 'Writable', 'Data',
            %   and 'Filename'. See HELP MEMMAPFILE for a description of these properties.
            if s(1).type(1) ~= '.'
                if s(1).type(1) == '('
                    error(message('MATLAB:memmapfile:illegalParenIndex'));
                else
                    error(message('MATLAB:memmapfile:illegalBraceIndex'));
                end
            else
                % This conversion from string to char is needed to
                % handle the subsasgn form:
                %   >> obj.("Property") = newval;
                % where "Property" is a string value.
                s(1).subs = convertStringsToChars(s(1).subs);
                fieldname = s(1).subs;

                if strcmpi(fieldname, 'Data')
                    if ~obj.Writable
                        error(message('MATLAB:memmapfile:dataIsReadOnly'));
                    end

                    if (hIsCommaSeparatedListOperation(obj, s))
                        error(message('MATLAB:memmapfile:unsupportedCSL'));
                    end

                    if ~matlab.iofun.internal.memmapfile.hismapped(obj.DataHandle)
                        hCreateMap(obj);
                    end

                    hDoDataSubsasgn(obj, s, newval);
                    return;

                elseif strcmpi(fieldname, 'Filename')
                    if (length(s) > 1)
                        newname = subsasgn(obj.Filename, s(2:end), newval);
                    else
                        newname = newval;
                    end

                    obj = hChangeFilename(obj, newname);
                else
                    s(1).subs = hCapitalize(fieldname);
                    obj = builtin('subsasgn', obj, s, newval);
                end

                if hIsPublicProperty(fieldname)
                    obj.DataHandle = 0;
                end
            end

        end % Subsassgn

        function varargout = subsref(obj, s)

            %   Supported property names are 'Format', 'Repeat', 'Offset', 'Writable', 'Data',
            %   and 'Filename'. See HELP MEMMAPFILE for a description of these properties.
            if (s(1).type(1) == '.')
                % This conversion from string to char is needed to support
                % the subsref form:
                %   >> val = obj.("Property");
                % where "Property" is a string value.
                s(1).subs = convertStringsToChars(s(1).subs);
                if strcmpi(s(1).subs, 'Data')
                    if (hIsCommaSeparatedListOperation(obj, s))
                        error(message('MATLAB:memmapfile:unsupportedCSL'));
                    end

                    if ~matlab.iofun.internal.memmapfile.hismapped(obj.DataHandle)
                        hCreateMap(obj);
                    end

                    varargout{1} = matlab.iofun.internal.memmapfile.hSubsref(obj.DataHandle, s(2:end));
                else
                    if hIsPublicProperty(s(1).subs)
                        s(1).subs = hCapitalize(s(1).subs);
                    else
                        % The names of all PrivateProperties have medial caps, which means this operation
                        % will filter them out. But all method names have only lower case letters, and this
                        % operation will not affect them.
                        s(1).subs = lower(s(1).subs);
                    end

                    [varargout{1:nargout}] = builtin('subsref', obj, s);
                end
            else
                if s(1).type(1) == '('
                    error(message('MATLAB:memmapfile:illegalParenIndex'));
                else
                    error(message('MATLAB:memmapfile:illegalBraceIndex'));
                end
            end

        end % Subsref

        function s=struct(~) %#ok<STOUT>
            error(message('MATLAB:memmapfile:noStructConversion'));
        end % Struct method

        function c=horzcat(varargin) %#ok<STOUT>
            error(message('MATLAB:memmapfile:noCatenation'));
        end % horzcat

        function c=vertcat(varargin) %#ok<STOUT>
            error(message('MATLAB:memmapfile:noCatenation'));
        end % vertcat
        function c=cat(varargin) %#ok<STOUT>
            error(message('MATLAB:memmapfile:noCatenation'));
        end % cat
    end % Hidden methods

    methods(Static, Hidden)
        function DeleteDataHandle(dh)
            if ~isequal(dh, 0)
                if matlab.iofun.internal.memmapfile.hismapped(dh)
                    n = matlab.iofun.internal.memmapfile.hUnmapFile(dh); %#ok<NASGU>
                end
                matlab.iofun.internal.memmapfile.hdeletedatahandle(dh);
            end
        end
        function obj = loadobj(obj)
            if isa(obj, 'memmapfile')
                obj.DataHandle = 0;
            end
        end
        function obj = empty(varargin) %#ok<STOUT>
            %EMPTY Instantiates empty memmapfile objects (disallowed).
            error(message('MATLAB:memmapfile:noEmptyMethod'));
        end
    end

end % Class definition

% Validate memmapfile Format field setting.
function isvalid = hIsValidFormat(format)
if ischar(format)
    switch(format)
        case {'double', 'int8', 'int16', 'int32', 'int64', ...
                'uint8', 'uint16', 'uint32', 'uint64', ...
                'single'}
            isvalid = true;
        otherwise
            isvalid = false;
    end
elseif iscell(format)
    if size(format, 1) < 1 || size(format, 2) ~= 3
        isvalid = false;
    else
        isvalid = true;
        for i = 1:size(format, 1)
            field1 = format{i,1};
            field2 = format{i,2};
            field3 = format{i,3};
            % field 1 must be a string containing one of the supported basic data types.
            if ~ischar(field1) || ~hIsValidFormat(field1)
                isvalid = false;
                % field 2 must be a 1xN double array such that N > 0.
            elseif ~isa(field2, 'double') || ~isrow(field2) || ...
                    isempty(field2)
                isvalid = false;
                % field 2 must contain nonnegative integral values
            elseif any(field2 < 0 | ~isfinite(field2) | ...
                    ~isreal(field2) | field2 ~= fix(field2))
                isvalid = false;
                % field 3 must be a legal MATLAB variable name.
            elseif ~isvarname(field3)
                isvalid = false;
            end
        end

        % Make sure all field names are unique and that overall frame size is > 0
        if isvalid
            fields = format(:,3);
            if length(fields) > length(unique(fields))
                isvalid = false;
            elseif hFrameSize(format) == 0
                isvalid = false;
            end
        end
    end
else
    isvalid = false;
end

end % hIsValidFormat


% size of a single frame in bytes.
function sz = hFrameSize(format)

sz = 0;
if iscell(format)
    for i=1:size(format, 1)
        sz = sz + hFrameSize(format{i,1}) * prod(format{i,2});
    end
else
    switch format
        case {'int8', 'uint8'}
            sz = 1;

        case {'int16', 'uint16'}
            sz = 2;

        case {'int32', 'uint32', 'single'}
            sz = 4;

        case {'double', 'int64', 'uint64'}
            sz = 8;
    end
end

end % hFrameSize


% A(:)=B or A.f(:)=B has the internal effect of replacing A with B (after appropriate
% error checking is made). This causes us to lose the memory mapped Data pointer. To
% work around this, we transform to A(:,:)=reshape(B, size(A, 1), []) or
% A.f(:,:)=reshape(B, size(A, 1), [])
function [S, RHS] = hMapToTwoColonIndices(LHS, S, RHS)
RHS = reshape(RHS, size(LHS, 1), []);
S = [S substruct('()', {':', ':'})];
end % hMapToTwoColonIndices

% Check to see if we need to work around internal optimization of single colon index. If
% subscript-assigning a non-scalar to a single-colon indexed variable, we need to map
% to an equivalent double colon index.
function [S, RHS] = hFixSubscriptedColonAssignment(LHS, S, RHS)
if isequal(S(end).subs, {':'}) && ~isscalar(RHS) && ...
        numel(LHS) == numel(RHS)
    [S, RHS] = hMapToTwoColonIndices(LHS, S(1:end-1), RHS);
end
end % hFixSubscriptedColonAssignment

% Check maximum value of subscript values in each subscript position against actual size of
% LHS in corresponding dimension. As a special case, if only one subscript position
% is used (i.e. A(M)=N) then check maximum value of M against total number of
% elements in N.
function outOfRange = hSubsasgnIndexOutOfRange(LHS, indices)
for index = 1:length(indices)
    I = indices{index};
    % colon index can never be bigger than existing dimension.
    if ~isequal(I, ':')
        % Convert logical indices to numeric indices with FIND.
        if islogical(I)
            Imax = max([0; find(I(:))]);
        else
            Imax = max([0; I(:)]);
        end

        if (isscalar(indices) && Imax > numel(LHS)) || ...
                length(indices)  > 1 && Imax > size(LHS, index)
            outOfRange = true;
            return;
        end
    end
end
outOfRange = false;
end % hSubsasgnIndexOutOfRange

% Check if an subscripted assignment operation is actually a subscripted delete operation
% (i.e. assigning [] to a piece of an array).
function isDeletion = hSubsasgnIsSubscriptedDeletion(subs, RHS)
if isempty(RHS) && (isa(RHS, 'double') || isa(RHS, 'char'))
    % if any subscript is empty, then don't consider this subscripted assignment. It is
    % either legal (if subs only contains one element) or an illegal operation that
    % hSubsasgn and MATLAB's built-in indexing code will catch ("Indexed empty matrix
    % assignment is not allowed.")
    isDeletion = ~any(cellfun('isempty',subs));
else
    isDeletion = false;
end
end % hSubsasgnIsSubscriptedDeletion

% Capitalize input string (i.e. upper-case the first character, lower-case rest).
function out = hCapitalize(in)
out = lower(in);
out(1) = upper(out(1));
end % hCapitalize

% Determine if input string is the name of a public property, case-insensitively.
function isPublicProperty = hIsPublicProperty(in)
persistent publicProperties;
if isempty(publicProperties)
    publicProperties = properties(mfilename);
end
isPublicProperty = any(strcmpi(publicProperties, in));
end % hIsPublicProperty

%   Copyright 2004-2024 The MathWorks, Inc.