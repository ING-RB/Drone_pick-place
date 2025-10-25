classdef ErrorCause
    enumeration
        %% Fixable
        NotOnPath
        NotInstalled
        ShadowedByPwd
        ShadowedByPath
        InFolderNamedPrivate
        NotOnPathAndShadowedByPwd
        ShadowedByPwdAndNotInstalled
        InFolderNamedPrivateAndNotInstalled
        %% Not fixable
        ShadowedByVar
        ShadowedByMex
        ShadowedBySlx
        ShadowedByMdl
        ShadowedBySfx
        ShadowedByMapp
        ShadowedByMlapp
        ShadowedByMlx
        ShadowedByP
        InvalidPkgDef
        ModularPkgsNotSupported
        IncompatiblePkg
        InPkgRepository
        OutOfDatePkg
        NotExecutablePkg
        PkgPrivateFile
        InvalidFilenameForExecution
        InVfsLocation
        %% Sometimes fixable
        ShadowedWithinPkg
    end
end

%   Copyright 2023-2024 The MathWorks, Inc.
