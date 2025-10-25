function feOpts = getFrontEndOptions(headerFiles,includePath,definedMacros,undefinedMacros,configuredCompilerFlags,additionalCompilerFlags)
% Get front end options

%   Copyright 2024 The MathWorks, Inc.

% Create front-end options object
compilerFlags = additionalCompilerFlags;
if ~isempty(compilerFlags)
    compilerFlags = join(additionalCompilerFlags,' ');
    if(iscellstr(compilerFlags)) %#ok
        compilerFlags = compilerFlags{1};
    end
end
if(~isempty(compilerFlags))
    compilerFlags = horzcat(configuredCompilerFlags, ' ', char(compilerFlags));
    feOpts = internal.cxxfe.util.getMexFrontEndOptions('lang', 'cxx', 'overrideCompilerFlags', compilerFlags);
else
    feOpts = internal.cxxfe.util.getMexFrontEndOptions('lang', 'cxx');
end
if ~any(contains(feOpts.Language.LanguageExtra, '--microsoft'))
    % Some non-msvc dialects skip defaulted and deleted methods
    % then force to keep them
    feOpts.Language.LanguageExtra{end+1} = '--keep_deleted_functions';
else
    % Workaround for g2615465. Replace with actual fix from g2615164 when available
    feOpts.ExtraOptions{end+1} = '--ms_std_preprocessor';
    feOpts.Preprocessor.Defines(strncmp(feOpts.Preprocessor.Defines, '_MSVC_TRADITIONAL=', 18)) = [];
    feOpts.Preprocessor.Defines(strncmp(feOpts.Preprocessor.Defines, '__COUNTER__=', 12)) = [];
end
% When a class is instantiated, instantiate its nested classes also even if
% they are not used.
feOpts.ExtraOptions{end+1} = '--always_instantiate_nested_classes';
% Always normalize the included files path to avoid instability due to
% order of parsing (g2944296).
feOpts.ExtraOptions{end+1} = '--normalize_included_file_paths';
if(~isscalar(cellstr(convertStringsToChars(headerFiles))))
    feOpts.ExtraSources = headerFiles(2:end);
end
if not(isempty(includePath))
    feOpts.Preprocessor.IncludeDirs = cellstr(includePath);
end
% Add macro definitions
if(~isempty(definedMacros))
    for macro = cellstr(definedMacros)
        feOpts.Preprocessor.Defines{end+1} = macro{1};
    end
end
% Add macro cancellations
if(~isempty(undefinedMacros))
    for undefmacro = cellstr(undefinedMacros)
        feOpts.Preprocessor.UnDefines{end+1} = undefmacro{1};
    end
end

end
