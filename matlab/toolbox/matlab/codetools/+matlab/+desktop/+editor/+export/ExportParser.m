classdef (Sealed) ExportParser < handle
    % matlab.desktop.editor.export.ExportParser Wrapper class around inputParser
    % to handle export options.
    %   This class creates an inputParser and prepares it for the use
    %   from other export APIs. It should not used directly.

    %   Copyright 2021-2024 The MathWorks, Inc.

    properties (Constant=true, Access=private)
        supportedFormats = {'pdf', 'html', 'docx', 'latex', 'm', 'markdown', 'ipynb'};
    end

    properties (Access=private, Hidden=true)
        % A struct of supported options. The struct entries must look like this:
        % optionname: {
        %   defaultValue,
        %   validationFcn,
        %   {comma separated list of formats which support this option}
        % }
        % In future revisions this might become a deep struct or a class list,

        optionList = struct(...
            'Destination', {'', @mayBeFileOrPath, {}}, ...
            'Format', {'', @ischar, {}}, ...
            'HideCode', {'', @isLogical, {'pdf', 'html','docx', 'latex', 'markdown', 'ipynb'}}, ...
            'OpenExportedFile', {false, @isLogical, {'pdf', 'html','docx', 'latex', 'm', 'markdown', 'ipynb'}}, ...
            'FigureFormat', {false, @ischar, {'pdf', 'latex', 'markdown', 'ipynb', 'html'}}, ...
            'FigureResolution', {false, @(n) isIntegerInRange(n, 36, 2880), {'pdf', 'latex', 'markdown', 'ipynb', 'html'}}, ...
            'PageSize', {false, @ischar, {'pdf', 'docx', 'latex'}}, ...
            'Orientation', {false, @isValidOrientation, {'pdf', 'docx', 'latex'}}, ...
            'Margins', {false, @(m) isfloat(m) && (length(m) == 4), {'pdf', 'docx', 'latex'}}, ...
            'GenerateFigureAnimationVideo', {false, @islogical, {'html'}}, ...
            'MediaLocation', {'', @mayBeFileOrPath, {'html','latex', 'markdown', 'ipynb'}}, ...
            'FigureAnimationVideoFormat', {false, @(n) any(strcmp(n, {'MPEG-4'})), {'html'}}, ...
            'IncludeOutputs', { false, @isLogical, {'markdown', 'ipynb'}}, ...
            'ProgrammingLanguage', { 'matlab', @ischar, {'markdown', 'ipynb'} }, ...
            'EmbedImages', { true,     @isLogical, {'markdown', 'ipynb', 'html'} }, ...
            'AcceptHTML', { true,     @isLogical, {'markdown'} }, ...
            'HTMLanchors', { false,     @isLogical, {'markdown', 'ipynb'} }, ...
            'RenderLaTeXOnline', { 'off',    @ischar, {'markdown'} });
    end

    properties (Access=private, Hidden=true)
        iparser; % The inputParser used in this class.
        customParams = {}; % Parser parameters added from caller.
    end

    methods
        function obj = ExportParser(strict)
            % ExportParser Construct an instance of this class
            %   Creates an inputParser and adds default options listed
            %   in the optionList property.
            %   If strict is true, the parser will error on unknown
            %   options, otherwise they will silently passed through. The
            %   default is true.

            if nargin == 0
                strict = true;
            end

            % Create parser
            p = inputParser;
            % Set caller name for proper error reports.
            if length(dbstack) > 1
                p.FunctionName = dbstack(1).name;
            end
            % First positional argument is the output file.
            % We've to use that validationFcn to let the inputParser
            % distinguish from argument names.
            addOptional(p, 'Destination', '', @mayBeFileOrPath);
            % Add all other options.
            fn = fieldnames(obj.optionList);
            for i = 2:numel(fn)
                [defaultVal, fcnHandle, ~] = obj.optionList.(char(fn(i)));
                addParameter(p, char(fn(i)), defaultVal, fcnHandle);
            end

            if ~strict
                % Accept unknown arguments.
                p.KeepUnmatched = true;
            end

            obj.iparser = p;
        end

        function addParameter(obj, name, default, func)
            % ADDPARAMETER Used to add aditional parameters to the parser.
            % Syntax is the same as inputParser's addParameter.
            addParameter(obj.iparser, name, default, func);
            obj.customParams{end+1} = name;
            [obj.optionList.(name)] = deal(default, func, {});
        end

        function results = parse(obj, name, varargin)
            %PARSE Parses the export options in varargin, guesses the format if needed
            % and fully qualifies the destination path.
            %   name: the file name of the source file to be exported, It is
            %         used to set the output file name if not given explicitly.
            %   varargins: the options as name value pairs. Can be empty.
            % Returns a struct with validated options ready to pass through
            % to JS export.

            parse(obj.iparser, varargin{:});

            % Guess format and complete the output path.
            [destPath, betFormat] = obj.processFormatAndDestination( ...
                obj.iparser.Results.Destination, ...
                obj.iparser.Results.Format, ...
                name);

            % Remove default values
            % (except custom options because those have to go back to the caller).
            reals = obj.iparser.Results;
            for k=1:numel(obj.iparser.UsingDefaults)
                if ~any(strcmp(obj.customParams, obj.iparser.UsingDefaults{k}))
                    reals = rmfield(reals, obj.iparser.UsingDefaults{k});
                end
            end
            % Re-assign destination (because it might have changed)
            reals.Destination = destPath;

            % Check remaining options against the given format.
            obj.checkSupportedArgumentsForFormat(reals, betFormat);

            % Final checks and corrections.
            results = postProcessArguments(reals, betFormat);
        end
    end

    methods (Access=private, Hidden=true)
        % This function iterates over the given argument list and
        % uses the optionList property to check if each is supported.
        function checkSupportedArgumentsForFormat(obj, args, actFormat)
            fn = fieldnames(args);
            for k=1:numel(fn)
                [~, ~, formatList] = obj.optionList.(char(fn(k)));
                if ~isempty(formatList) && ~any(strcmp(formatList, actFormat))
                    error(getMsg('UnsupportedOption', char(fn(k)), actFormat));
                end
            end
        end

        function [outDest, outFormat] = processFormatAndDestination(obj, destination, format, sourceFileName)
            % This function tries to find the best guess for the export
            % format from the destination path, resp. the explicitly given format.
            % Depending on where it finds hints, it completes the other one.
            %   destination: The desination file (can be incomplete or entirely empty).
            %   format: The explicitly given format (can be empty).
            %   sourceFileName: Name of the code file to be exported. (Used as fallback name
            %                   for the output file)
            % Returns array of the qualified output path and the final export format.
            outFormat = '';
            if ~isempty(format)
                if obj.isFormatSupported(format, true)
                    % Found favorite export format.
                    outFormat = format;
                end
            end
            [path, name, ext] = fileparts(destination);
            % Complete output path if needed.
            if isempty(path)
                path = pwd;
            end
            if ~isfolder(path)
                error(getMsg('DirNotFound'))
            end
            if isempty(name)
                name = sourceFileName;
            end
            if isempty(ext)
                % No extension
                if isempty(outFormat)
                    % No format at all. Default to pdf
                    ext = '.pdf';
                    outFormat = 'pdf';
                else
                    % Use explicit format for extension.
                    ext = getExtensionForFormat(outFormat);
                end
            else
                % extension found
                formatHint = getFormatFromExtension(ext);
                if obj.isFormatSupported(formatHint, false)
                    % Extension format looks good.
                    if isempty(outFormat)
                        % If no explicit format, use the extension.
                        outFormat = formatHint;
                    elseif ~strcmp(outFormat, formatHint)
                        % Two valid format. Warn about using the explicit
                        % one.
                        warning(getMsg('AmbigiousFormat'));
                    end
                else
                    % There is an unsupported extension
                    if isempty(outFormat)
                        % Give up and error.
                        error(getMsg('UnsupportedFormat', formatHint));
                    end
                end
            end
            % return the fully qualified output path.
            outDest = fullfile(path, [name ext]);
        end

        function out = isFormatSupported(obj, format, strict)
            % Checks if the given format is in the supported list.
            % If strict is false, it just returns the result, otherwise it
            % errors.
            out = any(strcmp(obj.supportedFormats, format));
            if ~out && strict
                error(getMsg('UnsupportedFormat', format));
            end
        end
    end
end

%=================Helper Functions ==========================
function newArgs = postProcessArguments (args, format)
    % Helper function to post process certain options due to
    % functional lacks at other places.
    % This method is supposed to go away in the next file revisions.
    needsRerun = false;
    fn = fieldnames(args);
    for k=1:numel(fn)
        value = args.(fn{k});
        switch fn{k}
            case 'FigureFormat'
                % This information should go into the optionList.
                switch format
                    case {'pdf', 'html'}
                        if ~any(strcmp(value,{'png', 'jpeg', 'bmp', 'tiff', 'svg'}))
                            error(getMsg('UnsupportedValue', value, fn{k}, format));
                        end
                    case 'latex'
                        if ~any(strcmp(value,{'png', 'jpeg', 'pdf', 'eps'}))
                            error(getMsg('UnsupportedValue', value, fn{k}, format));
                        end
                    case {'markdown', 'ipynb'}
                        if ~any(strcmp(value,{'png', 'jpeg'}))
                            error(getMsg('UnsupportedValue', value, fn{k}, format));
                        end
                end
                if ~any(strcmpi(format, {'markdown', 'ipynb'}))
                    needsRerun = true;
                end
            case 'FigureResolution'
                needsRerun = true;
            case 'Margins'
                % The margin array should better be passed through to JS and
                % split up there. The JS code exists.
                args.marginLeft = value(1);
                args.marginTop = value(2);
                args.marginRight = value(3);
                args.marginBottom = value(4);
            case 'PageSize'
                if ~any(ismember({'Letter', 'Legal', 'Tabloid', 'A2', 'A3', 'A4', 'A5'}, value))
                    error(getMsg('UnsupportedPageSize', value));
                end
            case 'Orientation'
                args.pageOrientation = value;
            case 'GenerateFigureAnimationVideo'
                needsRerun = true;
                if value && ~isfield(args, 'FigureAnimationVideoFormat')
                    error(getMsg('MissingOption', 'FigureAnimationVideoFormat'));
                end
                isLinux = ~(ismac || ispc);
                if isLinux && value
                    error(getMsg('UnsupportedValueOnOS', 'true', 'FigureAnimationVideoFormat', 'Linux'));
                end
        end
    end
    if needsRerun
        args.needsRerun = true;
    end
    newArgs = args;
end

function format = getFormatFromExtension(ext)
    formatHint = lower(strip(ext, 'left', '.'));
    switch formatHint
        case 'tex'
            format = 'latex';
        case 'htm'
            format = 'html';
        case {'md', 'rmd'}
            format = 'markdown';
        otherwise
            format = formatHint;
    end
end

function ext = getExtensionForFormat(format)
    switch format
        case 'latex'
            ext = '.tex';
        case 'docbookxml'
            ext = '.xml';
        case 'markdown'
            ext = '.md';
        otherwise
            ext = ['.' format];
    end
end

function out = mayBeFileOrPath(name)
    % Validator Funtion for the first positional argument.
    % This is needed to let the inputParser distinguish
    % between a path value and an argument name. Both are chars.
    out = false;
    if ischar(name) || isstring(name)
        [path, ~, ext] = fileparts(name);
        if ~isempty(path) || ~isempty(ext)
            out = true;
        end
    end
end

function m = getMsg(id,varargin)
    m = message(['MATLAB:Editor:Export:' id], varargin{:});
end

function tf = isValidOrientation(str)
tf = contains(str, {'Portrait', 'Landscape'});
end

%-------------------------------------------------------------------------
% isLogical follows the PRISM standard for accepting logical values,
% namely: isLogical accepts true, false, 0, and 1
function tf = isLogical(value)
tf = isscalar(value) && (islogical(value) || isIntegerInRange(value, 0, 1));
end

function tf = isIntegerInRange(value, a, b)
tf = isInteger(value) && a <= value && value <= b;
end

function tf = isInteger(n)
tf = isscalar(n) && isreal(n) && mod(n, 1) == 0;
end
