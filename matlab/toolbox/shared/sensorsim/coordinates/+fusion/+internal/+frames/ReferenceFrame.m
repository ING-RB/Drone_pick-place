classdef (Hidden) ReferenceFrame
%REFERENCEFRAME Internal utility class for listing supported reference
%   frames and getting specific reference-frame-specific math objects.
%
%   This class is for internal use only. It may be removed in the future.

%   Copyright 2018-2020 The MathWorks, Inc.

%#codegen

    methods (Static)
        function framesOpts = getOptions
        %GETOPTIONS Return a cell array of supported reference frames.
            framesOpts = {'NED', 'ENU'};
        end

        function defaultFrame = getDefault
        %GETDEFAULT Return the default reference frame.
            defaultFrame = 'NED';
        end

        function refFrame = getMathObject(refFrameStr)
        %GETMATHOBJECT Return a class of type
        %   FUSION.INTERNAL.FRAMES.ABSTRACTREFERENCEFRAME with math
        %   specific to the reference frame string REFFRAMESTR.

            if strcmpi(refFrameStr, 'NED')
                refFrame = fusion.internal.frames.NED;
            else % ENU
                refFrame = fusion.internal.frames.ENU;
            end
        end
    end

end
