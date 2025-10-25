function cgDirInfo = getCodeGenerationDir(systemName)
%GETCODEGENERATIONDIR 

% Copyright 2011-2020 The MathWorks, Inc.

cgDirInfo = cell(0, 2);
      
% Force to be a string
systemName = getfullname(systemName);
mdlDir = fileparts(get_param(bdroot(systemName), 'FileName'));

allSys = dsdd('find','/Subsystems','ObjectKind','SubSystem');
for ii = 1:numel(allSys)
    blkPath = dsdd('GetSubsystemInfoBlockPath', allSys(ii));
    if ~isempty(blkPath)
        blkHandle = (getSimulinkBlockHandle(blkPath));
        if blkHandle ~= -1
            blkInfo = tl_get_subsystem_info(blkHandle);
            if strcmp(systemName, blkInfo.tlSubsystemPath)
                % Stop on first match?
                cfile = get_codefile(blkPath);
                if ~isempty(cfile)
                    fpath = fileparts(cfile);
                    if isempty(fpath)
                        codeGenDir = mdlDir;
                    else
                        if ~polyspace.internal.isAbsolutePath(fpath)
                            % Start from current directory
                            tmpPath = fullfile(pwd, fpath);
                            if ~isfolder(tmpPath)
                                tmpPath = fullfile(mdlDir, fpath);
                            end
                            fpath = tmpPath;
                        end
                        % Get the canonical path for removing any intermediate
                        % . or ..
                        codeGenDir = polyspace.internal.getAbsolutePath(fpath);
                    end

                    codeGenName = dsdd('GetAttribute', allSys(ii), 'name');
                    cgDirInfo = [cgDirInfo; {codeGenDir, codeGenName}]; %#ok<AGROW>
                end
            end
        end
    end
end
