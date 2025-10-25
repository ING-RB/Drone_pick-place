classdef VideoReaderDisplayHelper < matlab.mixin.CustomDisplay & dynamicprops
    % audiovideo.internal.VideoReaderDisplayHelper Helper class for VideoReader 
    % display.
    %
    % This class helps customize the display of the VideoReader object in
    % situations when the number of frames has not been computed when
    % object display us requested.
    
    %   Copyright 2019 The MathWorks, Inc.
    
    properties(Access='private', Constant)
        % List the properties to be displayed along with the groups they
        % belong to.
        GeneralProps = {'Name', 'Path', 'Duration', 'CurrentTime', 'NumFrames'};
        VideoProps = {'Width', 'Height', 'FrameRate', 'BitsPerPixel', 'VideoFormat'};
    end
    
    properties(Access='private')
        VidObj;
    end
    
    methods
        function obj = VideoReaderDisplayHelper(vidObj)
            obj.VidObj = vidObj;
            for cnt = 1:numel(obj.GeneralProps)
                prop = addprop(obj, obj.GeneralProps{cnt});
                prop.GetMethod = @(obj) obj.getDynamicProp(obj.GeneralProps{cnt});
            end
            for cnt = 1:numel(obj.VideoProps)
                prop = addprop(obj, obj.VideoProps{cnt});
                prop.GetMethod = @(obj) obj.getDynamicProp(obj.VideoProps{cnt});
            end
        end
    end
    
    methods(Access='public', Static)
        function propGroups = computePropGroups()
            import matlab.mixin.util.PropertyGroup;
            
            propGroups(1) = PropertyGroup( audiovideo.internal.VideoReaderDisplayHelper.GeneralProps, ...
                                           getString( message('multimedia:videofile:GeneralProperties') ) );
                                       
            propGroups(2) = PropertyGroup( audiovideo.internal.VideoReaderDisplayHelper.VideoProps, ...
                                           getString( message('multimedia:videofile:VideoProperties') ) );
        end
    end
    
    methods(Access='private')
        function out = getDynamicProp(obj, propName)
            if strcmp(propName, 'NumFrames')
                out = 0;
            else
                out = obj.VidObj.(propName);
            end
        end
    end
    
    methods (Access='protected')
        function propGroups = getPropertyGroups(~)
            propGroups = audiovideo.internal.VideoReaderDisplayHelper.computePropGroups();
        end
    end
end