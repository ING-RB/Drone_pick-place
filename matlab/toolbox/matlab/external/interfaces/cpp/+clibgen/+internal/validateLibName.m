function validateLibName(libname)
% Validate the library name

%   Copyright 2018-2023 The MathWorks, Inc.
if ~iscellstr(libname) %#ok<*ISCLSTR>
    if isempty(libname)
        error(message('MATLAB:CPP:Filename'));
    end
    try
        validateattributes(libname,{'char','string'},{'vector','row'});
    catch ME
        error(message('MATLAB:CPP:InvalidInputType','Libraries'));
    end
    if ismissing(libname)
        error(message('MATLAB:CPP:InvalidInputType','Libraries'));
    end
else
    if ~isrow(libname)
        error(message('MATLAB:CPP:InvalidInputType','Libraries'));
    end
end

if ~isempty(find(startsWith(libname, "<"), 1))
    % atleast one library seems to refer to a 'RootPaths' key
    % defer validation
    return;
end

libname = cellstr(convertStringsToChars(libname));
for index = 1:length(libname)
    [~,filename,extn]= fileparts(libname{index});
    if isempty(filename)
        error(message('MATLAB:CPP:Filename'));
    end
    if isempty(dir(libname{index}))
        error(message('MATLAB:CPP:FileNotFound',libname{index}));
    end

    % The library extension that are supported are 
    % .lib, .dll on Win64 with VS compiler
    % .lib, .a on Win64 with MinGW compiler
    % .dylib,.a     on mac
    % .so,.a        on linux 
    if(strcmp(extn, '.a'))
        cc = mex.getCompilerConfigurations('C++', 'Selected');
        if ispc && (~strcmp(cc.ShortName, 'mingw64-g++'))
            %.a extension is accepted only for minGW compiler
                error(message("MATLAB:CPP:InvalidLibraryExtensionDotAForVS", extn, computer('arch')));
        else 
            %.a is accepted library extn on unix platforms. 
        end
        
    elseif (ispc && ~(strcmp(extn, '.lib') || strcmp(extn, ".dll"))) || ...
       (ismac && ~(strcmp(extn, '.dylib'))) || ...
       (isunix && ~ismac && ~(strcmp(extn, '.so')))
        
        extnName = extractAfter(extn, '.');
        if(isunix && ~ismac && ~isnan(str2double(extnName)))
            %versions are the format libfoo.so.1.2.1
            %this branch is applicable only for linux. On Mac libraries are
            %named libfoo.1.2.1.dylib
            fullExtension = [extractAfter(filename, '.so'), extn];
            if(ismissing(fullExtension))
                fullExtension = extn;
            end
            vers = regexp(filename,'\.so(\.\d+)*$', 'once');
            if(isempty(vers))
                error(message("MATLAB:CPP:InvalidLibraryExtension", fullExtension, computer('arch')));
            end

        else
            error(message("MATLAB:CPP:InvalidLibraryExtension", extn, computer('arch')));
        end
    end

    % Error if the header file is a wildcard character
    if strfind(libname{index}, '*') > 0
        error(message('MATLAB:CPP:InvalidInputType','Libraries'));
    end
end

% On linux, detect library names without naming convention prefix 'lib' and
% throw error
if strcmp(computer('arch'),'glnxa64')
    for idx = 1:length(libname)
        [~,libFileName,~] = fileparts(libname{idx});
        if ~startsWith(libFileName,'lib')
            error(message('MATLAB:CPP:InvalidLinuxLibName'));
        end
    end
end
end