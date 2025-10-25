function[reportArgs, mainFileArgs, remainingArgs] = resolveStandaloneReportInputs(reportFileOrFolder, varargin)
% This function is undocumented and may change in a future release.

% Copyright 2023 The MathWorks, Inc.
    [reportFolder,reportFile,fileExt] = fileparts(reportFileOrFolder);
    fileExtSpecified = isNonEmptyString(fileExt);
    isHTMLFileExt = any(strcmpi(fileExt,{'.html','.htm'}));
    if fileExtSpecified && ~isHTMLFileExt
        error(message('MATLAB:unittest:HTMLMainFile:InvalidMainFileExtension'));
    end
    standaloneTestReport = isNonEmptyString(reportFile) && fileExtSpecified && isHTMLFileExt;
    
    if standaloneTestReport
        reportFolder = matlab.unittest.internal.parentFolderResolver(reportFolder);
    else
        reportFolder = matlab.unittest.internal.parentFolderResolver(reportFileOrFolder);
    end

    [eMainFileArgs, remainingArgs] = matlab.unittest.internal.extractParameterArguments('MainFile',varargin{:});
    mainFileNameSpecified = ~isempty(eMainFileArgs);
    
    if standaloneTestReport && mainFileNameSpecified
        error(message('MATLAB:unittest:HTMLMainFile:TooManyInputsForMainFile'));
    elseif standaloneTestReport & ~mainFileNameSpecified
        reportFile = strcat(reportFile, fileExt);
        matlab.unittest.internal.mixin.MainFileMixin.validateMainFile(reportFile);
        mainFileArgs = {'MainFile', reportFile};
    else
        mainFileArgs = eMainFileArgs;
    end

    reportArgs = struct('reportFolder', reportFolder, 'standaloneTestReport', standaloneTestReport);
end

function bool = isNonEmptyString(input)
    bool = strlength(input) > 0;
end