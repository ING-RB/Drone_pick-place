function libraries = setupLibDll(libraries, headerFiles, manufacturer)
% Use .lib if .dll is provided

%   Copyright 2024 The MathWorks, Inc.

if ~iscellstr(libraries)
    libraries = cellstr(convertStringsToChars(libraries));
end

% Search and update ".lib" file if exists for every DLL file provided under
% Libraries option
for lIndex = 1:length(libraries)
    [~,filename,ext] = fileparts(libraries{lIndex});
    if strcmpi(ext,'.dll')
        % search for ".lib" file only for Visual studio compiler
        if strcmp(manufacturer, 'Microsoft')
            % libraryFile = strcat(char(filename), ".lib");
            [libraries,~] = clibgen.internal.searchForLib(filename,libraries,headerFiles);
        else
            % throw error if user provided DLL file in Windows and
            % compiler is other than Visual Studio
            if strcmp(computer('arch'), 'win64')
                error(message('MATLAB:CPP:UnsupportedLibraryForCompiler'));
            end
        end
    end
end
libraries = clibgen.internal.removeUnmatchedLibsWithDlls(libraries);

end
