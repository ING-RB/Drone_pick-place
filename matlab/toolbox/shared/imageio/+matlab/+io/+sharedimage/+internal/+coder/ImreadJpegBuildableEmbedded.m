classdef ImreadJpegBuildableEmbedded < coder.ExternalDependency %#codegen
    %IMREADJPEGBUILDABLEEMBEDDED Encapsulate the implementation of the
    % methods to read the JPEG files on embedded targets. The methods here call into the
    % functions in jpegEmbeddedInterface.c which have libjpeg-turbo API
    % calls to get the image dimensions from the JPEG header and read the
    % image.
    
    % Copyright 2024 The MathWorks, Inc.

    methods (Static)
        
    function bName = getDescriptiveName(~)
        bName = 'ImreadJpegBuildableEmbedded';
    end
    
    function tf = isSupportedContext(buildContext)
        % build context for this file is supported for embedded targets
        % only.
        tf = ~buildContext.isMatlabHostTarget();
    end
    
    function updateBuildInfo(buildInfo, buildContext)
        % File extensions
        [~, linkLibExt, execLibExt] = ...
                buildContext.getStdLibInfo();

        % Copy jpegEmbeddedInterface.c and jpegEmbeddedInterface.h to the
        % codegen folder
        cfilesPath = coder.const(fullfile(matlabroot,'toolbox', 'shared', 'imageio', '+matlab', '+io', '+sharedimage', '+internal', '+coder'));
        copyfile([cfilesPath, filesep, 'jpegEmbeddedInterface*'], buildContext.getBuildDir())
        buildInfo.addSourceFiles("jpegEmbeddedInterface.c");
        
        % Set the build flags and linker flags for libjpeg-turbo
        libjpeg_build_flags = '`pkg-config --cflags libjpeg`';
        libjpeg_link_flags = '`pkg-config --libs libjpeg`';
        
        buildInfo.addCompileFlags(libjpeg_build_flags);
        buildInfo.addLinkFlags(libjpeg_link_flags);

   end

   function [outDims, fileStatus, colorSpaceStatus, bitDepthStatus, libjpegMsgCode, libjpegWarnBuffer, errWarnType] ...
           = jpegreadercore_getimagesize(filename, outDims, fileStatus, colorSpaceStatus,bitDepthStatus, libjpegMsgCode, libjpegWarnBuffer, errWarnType)
       % Method to return the dimensions of the image, which will help in
       % creating the output buffer
       coder.inline('always');
       coder.cinclude('jpegEmbeddedInterface.h');
       % Return status from the C interface code.
       % If the operation is successful, return a positive value.
       status = int8(0);
       status = coder.ceval('jpegreader_getimagesize', coder.rref(filename), coder.ref(outDims),...
                coder.ref(fileStatus),...
                coder.ref(colorSpaceStatus),...
                coder.ref(bitDepthStatus),...
                coder.ref(libjpegMsgCode),...
                coder.ref(libjpegWarnBuffer),...
                coder.ref(errWarnType));

   end

   function [outBuffer, fileStatus, libjpegReadDone, msgCode, warnBuffer,warnBufferFlag, runtimeFileDimsConsistency] ...
           = jpegreadercore_uint8(filename, outBuffer, fileStatus, libjpegReadDone, msgCode, warnBuffer, warnBufferFlag, runtimeFileDimsConsistency)
       % Method to decompress the JPEG image and fill the output buffer
       coder.inline('always');
       coder.cinclude('jpegEmbeddedInterface.h');
       % Return status from the C interface code.
       % If the operation is successful, return a positive value.
       status = int8(0);
       status = coder.ceval('jpegreader_uint8', coder.rref(filename), coder.ref(outBuffer),...
                coder.ref(fileStatus),...
                coder.ref(libjpegReadDone),...
                coder.ref(msgCode),...
                coder.ref(warnBuffer),...
                coder.ref(warnBufferFlag),...
                coder.ref(runtimeFileDimsConsistency));
        
   end

end

end
