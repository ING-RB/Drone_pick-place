classdef Path < matlab.mixin.indexing.RedefinesParen & ...
                matlab.mixin.indexing.RedefinesBrace
%PATH Path object with access to name, parent, extension - performs no IO
%     operations, used underlying filesystem to get constituent components
%     when Type is not specified.

%   Copyright 2023-2024 The MathWorks, Inc.

    properties (Access = public)
        Name (:, 1) string;
        Parent (:, 1) string;
        FileType (:, 1) string;
        Host (:, 1) string;
        Port (:, 1) double;
        Query (:, 1) string;
        Fragment (:, 1) string;
    end

    properties (SetAccess = private)
        Type (:, 1) string;
    end

    methods
        function obj = Path(pathStr, options)
            arguments
                pathStr (:, :) string
                options.Type (:, :) {mustBeMember(options.Type, ["unix", "windows", "schema", "auto"])}
            end

            if all(isempty(pathStr)) || all(ismissing(pathStr(:))) || all(pathStr(:) == "")
                % set up default values for an empty Path object
                obj.Name = missing;
                obj.Parent = missing;
                obj.FileType = missing;
                obj.Type = missing;
            else
                % call builtin to perform the string manipulation
                if isempty(fieldnames(options))
                    repeatedTypes = repmat("auto", size(pathStr, 1) * size(pathStr, 2), 1);
                    options.Type = repeatedTypes;
                else
                    % check that Type values have same length as path input
                    if size(options.Type,1) ~= size(pathStr, 1) || ...
                        size(options.Type,2) ~= size(pathStr, 2) && ...
                        numel(options.Type) ~= 1
                        error(message("MATLAB:io:filesystem:common:IncorrectSizeInputs"));
                    end

                    if isscalar(options.Type) && numel(pathStr) > 1
                        options.Type = repmat(options.Type, size(pathStr, 1), size(pathStr, 2));
                    end
                end

                S = matlab.io.internal.filesystem.pathObject(pathStr, "Type", options.Type);
                obj.Name = strip([S(:).Name]', "right");
                obj.Parent = strip([S(:).Parent]', "right");
                obj.Type = strip([S(:).PathType]', "right");
                obj.FileType = strip([S(:).Extension]', "right");
                if all(obj.Type ~= "Unix" & obj.Type ~= "Windows")
                    obj.Host = strip([S(:).Host]', "right");
                    obj.Port = [S(:).Port]';
                    obj.Query = strip([S(:).Query]', "right");
                    obj.Fragment = strip([S(:).Fragment]', "right");
                end
            end
        end

        % Overload definition of cat, horzcat is not supported
        function C = cat(dim, varargin)
            if dim == 1
                C = matlab.io.internal.filesystem.Path.empty();
                cntr = 1;
                fields = fieldnames(C);
                for ii = 1 : numel(varargin)
                    numStrings = numel(varargin{1}.(fields{1}));
                    for jj = 1 : numel(fields)
                        if isempty(varargin{ii}.(fields{jj}))
                            C.(fields{jj})(cntr : cntr+numStrings-1) = missing;
                        else
                            C.(fields{jj})(cntr : cntr+numStrings-1) = varargin{ii}.(fields{jj});
                        end
                    end
                    cntr = cntr + numStrings;
                end
            else
                error(message("MATLAB:io:filesystem:common:HorzcatUnsupported",class(obj1)));
            end
        end

        % Overload definition of size
        function varargout = size(obj, varargin)
            fields = fieldnames(obj);
            [varargout{1:nargout}] = size(obj.(fields{1}), varargin{:});
        end

        % Equality check
        function tf = eq(obj, obj1)
            fields = fieldnames(obj);
            % verify that obj1 is Path object too
            if ~isa(obj1, "matlab.io.internal.filesystem.Path")
                error(message("MATLAB:io:filesystem:common:NotAPath", obj1));
            end

            fields1 = fieldnames(obj1);
            if ~isequaln(numel(fields), numel(fields1)) || ~isequaln(sort(fields), sort(fields1))
                tf = false;
                return;
            end

            for ii = 1 : numel(fields)
                if ~isequaln(obj.(fields{ii}), obj1.(fields{ii}))
                    tf = false;
                    return;
                end
            end

            tf = true;
        end

        function tf = isequaln(obj, obj1)
            tf = eq(obj, obj1);
        end

        function tf = absolute(obj)
            if obj.Type == "Unix"
                tf = startsWith(obj.Parent, "/");
            elseif obj.Type == "Windows"
                tf = startsWith(obj.Parent, "\\") || ...
                    ~isempty(regexpi(obj.Parent, "^[\wA-Z]:", 'once'));
            elseif ismissing(obj.Type)
                tf = false;
            else
                % schema paths
                tf = true;
            end
        end
    end

    methods % Setters block
        function obj = set.Name(obj, value)
            for ii = 1 : size(obj, 1)
                if obj(ii).Type == "Windows"
                    if value(ii).contains("\")
                        error(message("MATLAB:io:filesystem:common:NameCannotContainFilesep"));
                    end
                else
                    if value(ii).contains("/")
                        error(message("MATLAB:io:filesystem:common:NameCannotContainFilesep"));
                    end
                end
            end

            obj.Name = strip(value, "right");
            if isscalar(dbstack)
                % to avoid going into infinite recursion because Name sets
                % FileType, check the caller stack
                obj.FileType = strip(getExtension(value), "right");
            end
        end

        function obj = set.FileType(obj, value)
            if any(~ismissing(value))
                validateExtension(value);
            end
            value(value == "") = missing;
            obj.FileType = strip(value, "right");
            if isscalar(dbstack)
                % to avoid going into infinite recursion because FileType
                % sets Name, check the caller stack
                obj.Name = replaceExtension(obj.Name, value); %#ok<*MCSUP>
            end
        end

        function obj = set.Query(obj, value)
            value(value == "") = missing;
            obj.Query = strip(value, "right");
        end

        function obj = set.Fragment(obj, value)
            value(value == "") = missing;
            obj.Fragment = strip(value, "right");
        end
    end

    methods (Access = protected)
        %%
        % Methods to be implemented for RedefinesParen
        function varargout = parenReference(obj, indexOp)
            if isscalar(indexOp)
                % Example - P(:), where P is a Path object
                P = matlab.io.internal.filesystem.Path.empty();
                fields = fieldnames(P);
                for ii = 1 : numel(fields)
                    P.(fields{ii}) = obj.(fields{ii})(indexOp.Indices{1});
                end
                % return a Path object here
                [varargout{1:nargout}] = P;
            else
                indices = indexOp(1).Indices{1};
                if all(isnumeric(indices)) && any(indices > size(obj,1))
                    error(message("MATLAB:io:filesystem:common:IndexOutOfBounds"));
                end
                fields = indexOp(2).Name;
                if fields == ""
                    error(message("MATLAB:io:filesystem:common:NoFieldsSpecifiedForIndexing"));
                end
                if numel(fields) > 1
                    % return struct
                    % Example - P(1).(["Name", "Type"]), where P is Path
                    % object
                    for ii = 1 : numel(fields)
                        P.(fields{ii}) = obj.(fields{ii});
                        P.(fields{ii}) = P.(fields{ii})(indices);
                    end
                else
                    % return string
                    % Example - P(1).Name, where P is Path object
                    if fields{1} == "absolute"
                        P = absolute(obj(indices));
                    else
                        P = obj.(fields)(indices);
                    end
                end

                [varargout{1:nargout}] = P;
            end
        end

        function obj = parenAssign(obj, indexOp, varargin)
            obj = assignment(obj, indexOp, varargin{:});
        end

        function n = parenListLength(~, ~, ~)
            n = 1;
        end

        function obj = parenDelete(obj, indexOp)
            if isscalar(indexOp)
                fields = fieldnames(obj);
                for ii = 1 : numel(fields)
                    obj.(fields{ii})(indexOp.Indices{1}) = [];
                end
            end
        end

        %%
        % Methods to be implemented for RedefinesBrace
        function varargout = braceReference(obj, indexOp)
            if isscalar(indexOp)
                P = matlab.io.internal.filesystem.Path.empty();
                fields = fieldnames(obj);
                indices = indexOp.Indices{1};
                for jj = 1 : numel(fields)
                    P.(fields{jj}) = obj.(fields{jj})(indices);
                end
            else
                indices = indexOp(1).Indices{1};
                fields = indexOp(2).Name;
                if fields == ""
                    error(message("MATLAB:io:filesystem:common:NoFieldsSpecifiedForIndexing"));
                end
                if numel(fields) > 1
                    for jj = 1 : numel(fields)
                        % Example - P{1}.(["Name", "FileType"]), where
                        % P is a Path object. Returns a struct
                        P.(fields{jj}) = obj.(fields{jj})(indices);
                    end
                else
                    for ii = indices
                        % Example - P{1}.("Name"), where P is Path object.
                        % Returns an array of the specific type
                        if fields{1} == "absolute"
                            P = absolute(obj(indices));
                        else
                            P(:, 1) = obj.(fields{1})(ii);
                        end
                    end
                end
            end
            [varargout{1 : nargout}] = P;
        end

        function obj = braceAssign(obj, indexOp, varargin)
            obj = assignment(obj, indexOp, varargin{:});
        end

        function n = braceListLength(~, ~, ~)
            n = 1;
        end

        %%
        % Build the header for the display
        function buildHeader(obj, className)
            if ~matlab.internal.display.isDesktopInUse
                dims = [num2str(size(obj,1)) char(120) '1'];
            else
                dims = [num2str(size(obj,1)) char(215) '1'];
            end
            if matlab.internal.display.isHot
                fontType = 'style="font-weight:bold"';
                out = [dims, ' <a href="matlab:helpPopup ' ,class(obj), ...
                    '" ', fontType, '>', className, '</a>'];
            else
                out = [dims,' ',className];
            end
            out = [char(32), char(32), out];
            fprintf(out);
            fprintf(newline);
            fprintf(newline);
        end
    end

    methods (Hidden)
        % Overload definition of horzcat
        function C = horzcat(obj1, ~) %#ok<STOUT>
            error(message("MATLAB:io:filesystem:common:HorzcatUnsupported",class(obj1)));
        end

        % Overload definition of vertcat
        function C = vertcat(varargin)
            C = cat(1, varargin{:});
        end

        function displayInfo(~, T)
            % Render the table display into a string.
            fh = feature('hotlinks');
            if fh
                disp(T);
            else
                % For no desktop, use hotlinks off on evalc to get rid of
                % xml attributes for display, like, <strong>Var1</strong>, etc.
                disp(evalc('feature hotlinks off; disp(T);'));
                feature('hotlinks', fh);
            end
        end

        function disp(obj)
            %DISP controls the display of the Path.
            buildHeader(obj, 'Path');
            if all(obj.Type == "Unix" | obj.Type == "Windows")
                T = table(obj.Parent, obj.Name, obj.FileType, obj.Type, 'VariableNames', ...
                    {'Parent', 'Name', 'FileType', 'Type'});
            else
                T = table(obj.Parent, obj.Name, obj.FileType, obj.Type, ...
                    obj.Host, obj.Port, obj.Query, obj.Fragment, 'VariableNames', ...
                    {'Parent', 'Name', 'FileType', 'Type', 'Host', 'Port', 'Query', 'Fragment'});
            end
            displayInfo(obj,T);
        end

        function obj = assignment(obj, indexOp, varargin)
            rhs = varargin{1};
            if isscalar(indexOp)
                fields = fieldnames(obj);
                % Example - P1{1} = P{1}, where both P and P1 are Path
                % objects; for braceAssign case
                % Example - P(1) = P2(1), where both P and P1 are Path
                % objects; for parenAssign case
                for ii = 1 : numel(fields)
                    obj.(fields{ii})(indexOp.Indices{1}) = rhs.(fields{ii});
                end
            else
                if isempty(rhs)
                    error(message("MATLAB:io:filesystem:common:DeleteAttribute"));
                end
                fields = indexOp(2).Name;
                if fields.matches("Type")
                    error(message("MATLAB:io:filesystem:common:CannotUpdateField"));
                end

                indices = indexOp(1).Indices{1};
                if ~isnumeric(indices) && indices == ":"
                    indices = 1 : size(obj.Name, 1);
                end

                if sum(fields.matches(["Name", "FileType"])) > 1
                    % check that both Name and FileType are being updated
                    % appropriately
                    extensions = getExtension(rhs.Name);
                    if any(extensions ~= rhs.FileType)
                        error(message("MATLAB:io:filesystem:common:ExtensionMustBePartOfName"));
                    end
                    validateExtension(rhs.FileType);
                elseif any(fields.contains("Name"))
                    % need to update FileType as well
                    if isstruct(rhs)
                        obj.FileType(indices) = strip(getExtension(rhs.Name), "right");
                    else
                        obj.FileType(indices) = strip(getExtension(rhs), "right");
                    end
                elseif any(fields.contains("FileType"))
                    % need to update Name as well
                    if isstruct(rhs)
                        validateExtesion(rhs.FileType);
                        obj.Name(indices) = strip(replaceExtension(obj.Name(indices), rhs.FileType), "right");
                    else
                        validateExtension(rhs);
                        obj.Name(indices) = strip(replaceExtension(obj.Name(indices), rhs), "right");
                    end
                end

                for ii = 1 : numel(fields)
                    if isstruct(varargin{1})
                        % Example - P.{["Name", "FileType"]} =
                        % struct("Name", "abc.txt", "FileType", ".txt")
                        % for braceAssign case
                        % Example - P.(["Name", "FileType"]) =
                        % struct("Name", "abc.txt", "FileType", ".txt")
                        % for parenAssign case
                        obj.(fields(ii))(indices) = rhs.(fields(ii));
                    else
                        % Example - P.{"Name"} = "abc.txt" for braceAssign
                        % case
                        % Example - P.("Name") = "abc.txt" for parenAssign
                        % case
                        obj.(fields(ii))(indices) = rhs;
                    end
                end
            end
        end
    end

    methods (Static, Access = public)
        function obj = empty()
            obj = matlab.io.internal.filesystem.Path([]);
        end
    end
end

function ext = getExtension(name)
    % get extension from the name
    newName = reverse(name);
    ext = reverse(extractBefore(newName,".") + ".");
    hasNoDot = ismissing(ext);
    ext(hasNoDot) = "";
end

function newName = replaceExtension(name, extension)
    % replace extension in name
    newName = reverse(name);
    if size(extension, 2) > size(extension, 1)
        extension = extension';
    end
    if size(name, 1) > size(extension, 1) && isscalar(extension)
        % scalar expansion case where single extension is being provided to update
        % an array of matlab.io.internal.filesystem.Path objects
        extension = repmat(extension, size(name, 1), size(name, 2));
    end
    for ii = 1 : size(newName, 1)
        newName(ii) = reverse(replace(newName(ii), extractBefore(newName(ii), ".") + ".", reverse(extension(ii))));
    end
end

function validateExtension(extension)
    if any(~ismissing(extension) & ~startsWith(extension, ".") & extension ~= "")
        error(message("MATLAB:io:filesystem:common:NotAValidExtension"));
    end
end
