classdef RosBagSegment < handle
%This class is for internal use only. It may be removed in the future.

%RosBagSegment Stores the ros messages fetched in background. 

%   Copyright 2022 The MathWorks, Inc.

   properties
       Id
       Messages = {}
       IsLoaded = false
       ReadType
   end
   
   methods (Access = public)
       function msg = getMessage(obj, idx)
           %getMessage Returns the message from the buffer.
           
           msgStruct = obj.Messages{idx};
           
           if isfield(msgStruct, 'errorId')
               %Handle error cases
               if isequal(msgStruct.errorId , 'ros:mlroscpp:image:DataLengthInconsistency')
                    error(message('ros:mlroscpp:image:DataLengthInconsistency', ...
                                 msgStruct.expectedNumDataElements,msgStruct.width, msgStruct.height, msgStruct.numChannels, msgStruct.numDataElements));
               elseif isequal(msgStruct.errorId , 'ros:mlroscpp:image:UnsupportedFormatRead')
                   error(message('ros:mlroscpp:image:UnsupportedFormatRead',msgStruct.format));
               else
                    error(message(msgStruct.errorId));
               end
           elseif isequal(obj.ReadType, 'image')
            % for image-message
               
               % Also debayer the image if IPT is installed
               if msgStruct.encoding.IsBayer && ...
                       ros.msg.sensor_msgs.internal.ImageLicense.isIPTLicensed
                    msgStruct.img = demosaic(msgStruct.img, msgStruct.encoding.SensorAlignment);
               elseif isa(msgStruct.img,"float")
                   % As per g2826880, Needs to be rescaled if the data is a floating point 
                   msgStruct.img = rescale(msgStruct.img);
               end

               msg.img = msgStruct.img;
               msg.alpha = msgStruct.alpha;
           elseif isequal(obj.ReadType, 'compressedimage')
                % In case of ROS2 the compressed images are fetched as
                % RAW in background thread and converted to image matrix
                % here in MATLAB.
                % Because in ROS2 messages are fetched as MLD in c++ and 
                % it needed an extra conversation from MLD array to mxarray 
                % and again mxarray to MLD array. Also this conversation
                % cannot be done in a background thread.
                
                if ~isfield(msgStruct,'img')
                    [msg.img, msg.alpha] = rosReadImage(msgStruct);
                else
                    msg = msgStruct;
                end
           else
            % for other messages
               msg = msgStruct;
           end
       end
   end
end

