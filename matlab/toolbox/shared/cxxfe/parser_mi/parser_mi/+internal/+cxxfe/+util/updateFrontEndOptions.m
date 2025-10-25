function updateFrontEndOptions(opts, varargin)
%UPDATEFRONTENDOPTIONS Creates a new front-end options object from an
%   existing front-end options object, 'BuildInfo' objects and
%   extra preprocessing options (-I, -D, -U and -include, -C).

%   Copyright 2014-2020 The MathWorks, Inc.

funName = 'internal.cxxfe.util.updateFrontEndOptions';

validateattributes(opts, { 'internal.cxxfe.FrontEndOptions' }, { 'scalar' }, funName, 'opts', 1);

% For each argument...
ii = 1;
while ii <= numel(varargin)
    arg = varargin{ii};
    ii = ii + 1;

    if isa(arg, 'RTW.BuildInfo')
        % If the argument is a 'BuildInfo' object...

        % Extract the corresponding include paths.
        incPaths = arg.getIncludePaths(true);
        opts.Preprocessor.IncludeDirs(end + 1:end + numel(incPaths)) = incPaths;
        
        % With g2199395, it is necessary to set the define PORTABLE_WORDSIZES
        % by resolving compiler requirements. For now, assume 
        % that a host-based toolchain is being used because this
        % maintains existing behaviour.
        % 
        % TODO(2202985): with g2199395, the define PORTABLE_WORDSIZES is no longer
        % "hard-coded" in the serialized buildInfo.mat. Instead there is a 
        % compiler requirement SupportPortableWordSizes and this compiler
        % requirement is stored in buildInfo.mat. The define PORTABLE_WORDSIZES
        % should only be set if a) SupportPortableWordSizes is true and b) the 
        % ToolchainInfo represents a host compiler. Work required to achieve 
        % this is to pass either ToolchainInfo or buildInfo.mat > buildOpts > BuildMethod
        % as an argument to this function.        
        hostBasedToolchainInfo = coder.make.internal.resolveToolchainOrTMF...
            (coder.make.internal.getInfo('default-toolchain'));
        coder.make.internal.resolveCompilerRequirementsForPWS...
            (arg, hostBasedToolchainInfo);
        
        % Extract the defines
        [~, keys, values] = getDefines(arg); 
        if isempty(keys)
            keys = {};
            values = {};
        end

        idx = ~strcmp(values, '');
        defines(~idx) = keys(~idx); %#ok<AGROW>
        if any(idx)
            defines(idx) = strcat(keys(idx), '=', values(idx)); %#ok<AGROW>
        end        
        opts.Preprocessor.Defines(end + 1:end + numel(defines)) = defines;

        continue
    end

    if strncmp(arg, '-I', 2)
        % If the argument starts with '-I', match an extra include path.
        if numel(arg) > 2
            val = arg(3:end);
        else
            val = varargin{ii};
            validateattributes(val, {'char', 'string'}, {'scalartext'}, funName, arg, ii);
            ii = ii + 1;
        end
        opts.Preprocessor.IncludeDirs{end + 1} = char(val);
    elseif strncmp(arg, '-D', 2)
        % If the argument starts with '-D', match an extra define.
        if numel(arg) > 2
            val = arg(3:end);
        else
            val = varargin{ii};
            validateattributes(val, {'char', 'string'}, {'scalartext'}, funName, arg, ii);
            ii = ii + 1;
        end
        opts.Preprocessor.Defines{end + 1} = char(val);
    elseif strncmp(arg, '-U', 2)
        % If the argument starts with '-U', match an extra undefine.
        if numel(arg) > 2
            val = arg(3:end);
        else
            val = varargin{ii};
            validateattributes(val, {'char', 'string'}, {'scalartext'}, funName, arg, ii);
            ii = ii + 1;
        end
        opts.Preprocessor.UnDefines{end + 1} = char(val);
    elseif strcmp(arg, '-include')
        % If the argument is '-include', match an extra pre-include.
        val = varargin{ii};
        validateattributes(val, {'char', 'string'}, {'scalartext'}, funName, arg, ii);
        ii = ii + 1;
        opts.Preprocessor.PreIncludes{end + 1} = char(val);
    elseif strcmp(arg, '-C')
        % If the argument is '-C', make the preprocessor preserve comments.
        opts.Preprocessor.KeepComments = true;
    else
        validatestring(arg, { '-I', '-D', '-U', '-include', '-C' }, funName, arg, ii - 1);
    end
end

% Uniquify...
opts.Preprocessor.IncludeDirs = unique(opts.Preprocessor.IncludeDirs, 'stable');
opts.Preprocessor.Defines = unique(opts.Preprocessor.Defines, 'stable');
opts.Preprocessor.UnDefines = unique(opts.Preprocessor.UnDefines, 'stable');
opts.Preprocessor.PreIncludes = unique(opts.Preprocessor.PreIncludes, 'stable');
