classdef FilePathState < uint32
    enumeration
        FILE_NOT_ON_PATH                    (0)
        FILE_WILL_RUN                       (1)
        FILE_SHADOWED_BY_PWD                (2)
        FILE_SHADOWED_BY_TBX                (3)
        FILE_SHADOWED_BY_PFILE              (4)
        FILE_SHADOWED_BY_MEXFILE            (5)
        FILE_SHADOWED_BY_MLXFILE            (6)
        FILE_SHADOWED_BY_MLAPPFILE          (7)
        INVALID_FILENAME_FOR_EXECUTION      (8)
        IN_FOLDER_NAMED_PRIVATE             (9)
        INVALID_PKG_DEF                     (10)
        IN_PKG_REPOSITORY                   (11)
        OUT_OF_DATE_PKG                     (12)
        PKG_PRIVATE_FILE                    (13)
        INCOMPATIBLE_PKG                    (14)
        NOT_EXECUTABLE_PKG                  (15)
        MODULAR_PKGS_NOT_SUPPORTED          (16)
        SHADOWED_BY_VAR                     (17)
        NOT_INSTALLED_PKG                   (18)
        NOT_INSTALLED_PKG_SHADOWED_BY_PWD   (19)
    end
end