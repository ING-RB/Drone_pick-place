classdef (Hidden) SpecialMsgUtil
%SpecialMsgUtil - Static utilities class for message structs

%   Copyright 2020-2024 The MathWorks, Inc.

%#codegen

    methods(Static)
        % Utilities functions for Image and CompressedImage messages
        function [img, alpha] = readImage(msg, varargin)
        % Validate input message struct
            validateattributes(msg.width,{'uint32','double'},{'scalar'},'rosReadImage');
            validateattributes(msg.height,{'uint32','double'},{'scalar'},'rosReadImage');
            validateattributes(msg.encoding,{'char'},{'nonempty'},'rosReadImage');
            validateattributes(msg.data,{'uint8'},{'vector'},'rosReadImage');

            if isempty(coder.target)
                % Use encoding information from message struct directly
                enc = ros.msg.sensor_msgs.internal.ImageEncoding.info(msg.encoding);
            else
                % Ensure the input message contains valid data
                coder.internal.assert(~isempty(msg.data),'ros:mlroscpp:codegen:EmptyInputMsg','rosReadImage');
                % Parse optional Encoding property for code generation
                nvPairs = struct('Encoding',uint32(0));
                pOpts = struct('PartialMatching',true,'CaseSensitivity',false);
                pStruct = coder.internal.parseParameterInputs(nvPairs,pOpts,varargin{1:end});

                encoding = coder.internal.getParameterValue(pStruct.Encoding,'rgb8',varargin{1:end});
                %validateattributes(encoding,{'char','string'},...
                %                   {'nonempty'},'rosReadImage','Encoding');
                validatestring(encoding,{'rgb8', 'rgba8', 'rgb16', 'rgba16', ...
                                         'bgr8', 'bgra8', 'bgr16', 'bgra16', 'mono8', 'mono16', ...
                                         '32fc1', '32fc2', '32fc3', '32fc4', ...
                                         '64fc1', '64fc2', '64fc3', '64fc4', ...
                                         '8uc1', '8uc2', '8uc3', '8uc4', ...
                                         '8sc1', '8sc2', '8sc3', '8sc4', ...
                                         '16uc1', '16uc2', '16uc3', '16uc4', ...
                                         '16sc1', '16sc2', '16sc3', '16sc4', ...
                                         '32sc1', '32sc2', '32sc3', '32sc4', ...
                                         'bayer_rggb8', 'bayer_bggr8', 'bayer_gbrg8', 'bayer_grbg8', ...
                                         'bayer_rggb16', 'bayer_bggr16', 'bayer_gbrg16', 'bayer_grbg16'},'rosReadImage','Encoding');

                enc = coder.const(ros.msg.sensor_msgs.internal.ImageEncoding.info(encoding));
            end

            % Create Reader object and convert image data into MATLAB image
            Reader = ros.msg.sensor_msgs.internal.ImageReader;
            [img, alpha] = Reader.readImage(msg.data,msg.width,msg.height,enc);
        end

        function [img, alpha] = readCompressedImage(msg, varargin)
        %readCompressedImage Read image from CompressedImage message struct

        % alpha is not applicable for compressed images
            alpha = [];

            % Setup local copy of image data information
            format = msg.format;
            data = msg.data;

            % Return if no data was received
            if isempty(data)
                img = data;
                return;
            end

            % Create Reader object and convert image data into MATLAB image
            Reader = ros.msg.sensor_msgs.internal.ImageReader;

            % An empty format string is not allowed
            % Note that after transitioning to C++, we no longer need
            % information from msg.Format. Image type can be determined
            % directly from raw bitstream header. However, it is still
            % worth making sure the format matches what's supported by ROS
            % community.
            if isempty(format)
                error(message('ros:mlroscpp:image:EmptyFormatRead'));
            end

            if contains(format,';')
                % Older syntax before 2020
                % It has the form of "rgb8; png compressed rgb8"
                parts = strsplit(format,';');
                encoding = parts{1};
            else
                % New syntax since 2020
                % It has the form of "jpeg"
                encoding = format;
            end

            % The decompression routine will take care of any color space
            % conversions.
            switch lower(encoding)
                case {'rgb8','rgba8','bgr8','bgra8','mono8','jpeg','jpg','png'}
                    % Only the RGB channels will be returned. 
                    % The alpha channel is not part of the compressed 
                    % image.
                    img = Reader.decompressImg(data);

                otherwise
                    error(message('ros:mlroscpp:image:UnsupportedFormatRead', ...
                              format));
            end
        end

        function msg = writeImage(msg, varargin)
        %writeImage Write image to image message struct

        % Ensure the message contains enough space for saving streaming data
        %coder.internal.assert(isequal(numel(msg.data),numel(varargin{1})),...
        %    'ros:mlroscpp:codegen:MismatchStreamDataSize');

        % Determine the start location of encoding input argument
            if nargin<=2
                % No alpha and encoding input
                startLoc = 2;
            elseif isnumeric(varargin{2})
                % User specified alpha input
                startLoc = 3;
            else
                % User did not specify alpha input
                startLoc = 2;
            end

            % Parse optional Encoding property for code generation
            nvPairs = struct('Encoding',uint32(0));
            pOpts = struct('PartialMatching',true,'CaseSensitivity',false);
            pStruct = coder.internal.parseParameterInputs(nvPairs,pOpts,varargin{startLoc:end});

            encoding = coder.internal.getParameterValue(pStruct.Encoding,'rgb8',varargin{startLoc:end});
            encoding = convertStringsToChars(encoding);
            validatestring(encoding,{'rgb8', 'rgba8', 'rgb16', 'rgba16', ...
                                     'bgr8', 'bgra8', 'bgr16', 'bgra16', 'mono8', 'mono16', ...
                                     '32fc1', '32fc2', '32fc3', '32fc4', ...
                                     '64fc1', '64fc2', '64fc3', '64fc4', ...
                                     '8uc1', '8uc2', '8uc3', '8uc4', ...
                                     '8sc1', '8sc2', '8sc3', '8sc4', ...
                                     '16uc1', '16uc2', '16uc3', '16uc4', ...
                                     '16sc1', '16sc2', '16sc3', '16sc4', ...
                                     '32sc1', '32sc2', '32sc3', '32sc4', ...
                                     'bayer_rggb8', 'bayer_bggr8', 'bayer_gbrg8', 'bayer_grbg8', ...
                                     'bayer_rggb16', 'bayer_bggr16', 'bayer_gbrg16', 'bayer_grbg16'},'rosReadImage','Encoding');

            if isempty(coder.target)
                % Extract message encoding information
                if isempty(msg.encoding)
                    msg.encoding = encoding;
                    if numel(varargin) < 3
                        % Throw warning only when applying the default
                        % encoding
                        warning(message('ros:mlroscpp:image:NoEncoding'));
                    end
                else
                    if pStruct.Encoding ~= 0
                        if ~strcmp(encoding, msg.encoding)
                            % Throw a warning if using the encoding on the
                            % message but an encoding was also passed as an
                            % argument that doesn't match the message's
                            % encoding
                            warning(message('ros:mlroscpp:image:EncodingArgIgnored'))
                        end
                    end
                end

                enc = msg.encoding;
                validateattributes(enc,{'char'},{'nonempty'},'rosWriteImage');

                enc = ros.msg.sensor_msgs.internal.ImageEncoding.info(enc);
            else
                % Code generation
                % Throw warning when there is no 'Encoding' specified for
                % code generation
                if numel(varargin)<3
                    coder.internal.compileWarning('ros:mlroscpp:image:NoEncoding');
                end
                encoding = convertStringsToChars(encoding);
                enc = coder.const(ros.msg.sensor_msgs.internal.ImageEncoding.info(encoding));
            end

            Writer = ros.msg.sensor_msgs.internal.ImageWriter;
            [data, info] = Writer.writeImage(enc, varargin{:});

            % Assign to message
            msg.data = data;
            msg.width = cast(info.width,'like',msg.width);
            msg.height = cast(info.height,'like',msg.height);
            msg.step = cast(info.step,'like',msg.step);

        end

        function outputs = writeCameraInfo(params, varargin)
        % writeCameraInfo Writes data from params to
        % sensor_msgs/CameraInfo message(s). The params input is either a
        % cameraParameters or stereoParameters struct.

        %     [fx'  0  cx' Tx]
        % P = [ 0  fy' cy' Ty]
        %     [ 0   0   1   0]
        % here, the prime notation indicates the new camera
        % parameters for the rectified image
        % For monocular cameras, Tx = Ty = 0.

            if ~isfield(params, 'CameraParameters1')
                msg1 = varargin{1};
                msg1 = ros.internal.ros2.SpecialMsgUtil.setCameraFields(msg1, params);
                % identity matrix
                msg1.r([1 5 9]) = 1;
                % projection matrix
                P = zeros(3, 4);

                % For backward compatibility concern, this should support both
                % K and IntrinsicMatrix (K replaced IntrinsicMatrix in R2022b
                % as described in g2744701)
                if isfield(params, 'K')
                    P(1:3, 1:3) = params.K';
                else
                    P(1:3, 1:3) = params.IntrinsicMatrix';
                end

                msg1.p = reshape(P', 12, 1);
                outputs = {msg1};

            else % must be a stereoParameters object
                msg1 = varargin{1};
                msg2 = varargin{2};
                msg1 = ros.internal.ros2.SpecialMsgUtil.setCameraFields(msg1, ...
                                                                        params.CameraParameters1);
                msg2 = ros.internal.ros2.SpecialMsgUtil.setCameraFields(msg2, ...
                                                                        params.CameraParameters2);
                [K_new, Rrect1, Rrect2] = ros.internal.ros2.SpecialMsgUtil.getRectifiedParameters(params);
                % rotation matrix
                msg1.r = reshape(Rrect1', 9, 1);
                msg2.r = reshape(Rrect2', 9, 1);
                % projection matrix
                P = zeros(3, 4);
                P(1:3, 1:3) = K_new';
                msg1.p = reshape(P', 12, 1);
                P(1:2, 4) = params.TranslationOfCamera2(1:2);
                msg2.p = reshape(P', 12, 1);
                outputs = {msg1, msg2};
            end

        end

        function msg = setCameraFields(msg, cameraParams)
            msg.distortion_model = 'plumb_bob';
            k3 = cameraParams.RadialDistortion(end)*(cameraParams.NumRadialDistortionCoefficients > 2);
            msg.d = [cameraParams.RadialDistortion(1:2) cameraParams.TangentialDistortion k3]';
            msg.height = uint32(cameraParams.ImageSize(1));
            msg.width = uint32(cameraParams.ImageSize(2));

            % For backward compatibility concern, this should support both
            % K and IntrinsicMatrix (K replaced IntrinsicMatrix in R2022b
            % as described in g2744701)
            if isfield(cameraParams, 'K')
                originalK = cameraParams.K;
            else
                originalK = cameraParams.IntrinsicMatrix;
            end

            % ROS intrinsic camera matrix format for the raw images.
            %     [fx  0 cx]
            % K = [ 0 fy cy]
            %     [ 0  0  1]
            % All ROS matrices are row-major
            msg.k = reshape(originalK, 9, 1);
        end

        function [K_new, Rrect1, Rrect2] = getRectifiedParameters(stereoParams)
            cp1 = stereoParams.CameraParameters1;
            cp2 = stereoParams.CameraParameters2;

            % For backward compatibility concern, this should support both
            % K and IntrinsicMatrix (K replaced IntrinsicMatrix in R2022b
            % as described in g2744701)
            if isfield(cp1, 'K')
                Kl = cp1.K;
                Kr = cp2.K;
            else
                Kl = cp1.IntrinsicMatrix;
                Kr = cp2.IntrinsicMatrix;
            end

            K_new = Kl;
            % find new focal length
            f_new = min([Kr(1,1),Kl(1,1)]);
            % set new focal lengths
            K_new(1,1) = f_new; K_new(2,2)=f_new;
            % find new y center
            cy_new = (Kr(2,3)+Kl(2,3)) / 2;
            % set new y center
            K_new(2,3) = cy_new;
            % set the skew to 0
            K_new(1,2) = 0;
            H1 = stereoParams.RectificationParams.H1;
            H2 = stereoParams.RectificationParams.H2;
            Rrect1 = K_new'\H1'*Kl';
            Rrect2 = K_new'\H2'*Kr';
        end

        % Utilities functions for PointCloud2 messages
        function fieldNames = getAllFieldNames(msg)
        %getAllFieldNames Return all field names in PointCloud2 message

            % If no point fields are available, return
            if isempty(msg.fields)
                fieldNames = {};
                return;
            end
            validateattributes(msg.fields(1).name,{'char'},{'scalartext'},'rosReadAllFieldNames');

            numFieldNames = numel(msg.fields);
            fieldNames = cell(1,numFieldNames);

            for i = 1:numFieldNames
                fieldNames{i} = msg.fields(i).name;
            end
        end

        function fieldData = getPointCloud2Field(msg, fieldName, varargin)
        % Validate Input argument
            validateattributes(msg,{'struct'},{'scalar'},'rosReadField');
            validateattributes(msg.data,{'uint8'},{'vector'},'rosReadField');
            validateattributes(msg.width,{'uint32','double'},{'scalar'},'rosReadField');
            validateattributes(msg.height,{'uint32','double'},{'scalar'},'rosReadField');
            fieldName = convertStringsToChars(fieldName);
            validateattributes(fieldName, {'char', 'string'}, {'scalartext'}, 'rosReadField', ...
                               'fieldName');

            %TypeConversion - Object handling ROS <--> MATLAB type conversions
            TypeConversion = ros.msg.sensor_msgs.internal.PointCloud2Types;

            % Get index of field. This will display an error if the field
            % name does not exist.
            fieldIdx = ros.internal.ros2.SpecialMsgUtil.getFieldNameIndex(msg,fieldName);

            datatype = msg.fields(fieldIdx).datatype;
            count = msg.fields(fieldIdx).count;

            fieldMlType = TypeConversion.rosToMATLABType(datatype);

            pointIndices = 1: msg.width * msg.height;

            % Parse optional PreserveStructureOnRead property
            nvPairs = struct('PreserveStructureOnRead', uint32(0), 'DataType', uint32(0));
            pOpts = struct('PartialMatching',true,'CaseSensitivity',false);
            pStruct = coder.internal.parseParameterInputs(nvPairs,pOpts,varargin{1:end});

            reshapeOutput = coder.internal.getParameterValue(pStruct.PreserveStructureOnRead,false,varargin{1:end});
            validateattributes(reshapeOutput,{'logical'},...
                               {'scalar'},'rosReadField','PreserveStructureOnRead');

            % Extract the bytes corresponding to this field
            [byteIdx, pointIdxIsValid] = ros.internal.ros2.SpecialMsgUtil.getByteIndexForField(msg, fieldIdx, pointIndices, count);

            if isempty(coder.target)
                if pStruct.DataType ~= 0
                    optDataTypeArg = coder.internal.getParameterValue(pStruct.DataType, 'single', varargin{1:end});
                    if ~(strcmp(fieldMlType, optDataTypeArg))
                        warning(message('ros:mlroscpp:pointcloud:DataTypeArgIgnored'))
                    end
                end

                fieldDataTemp = ros.internal.ros2.SpecialMsgUtil.readFieldFromData( ...
                    msg.data, byteIdx, pointIdxIsValid, fieldMlType, count);
            else
                % Parse the data type
                mlType = coder.const(convertStringsToChars(coder.internal.getParameterValue(pStruct.DataType, 'single', varargin{1:end})));
                validatestring(mlType, {'single', 'double'}, 'rosReadField');

                % We must assert that the data type matches the data type
                % specified on the message
                coder.internal.assert(strcmp(fieldMlType, mlType), 'ros:mlros2:codegen:DataTypeConflict','rosReadField');

                fieldDataTemp = ros.internal.ros2.SpecialMsgUtil.readFieldFromData( ...
                    msg.data, byteIdx, pointIdxIsValid, mlType, count);
            end

            % Reshape the output if requested by the user
            if reshapeOutput && msg.height ~= 1
                if count > 1
                    fieldData = reshape(fieldDataTemp, msg.width, msg.height, count);
                    fieldData = permute(fieldData, [2 1 3]);
                else
                    fieldData = reshape(fieldDataTemp, msg.width, msg.height).';
                end
            else
                fieldData = fieldDataTemp;
            end
        end

        function xyz = readXYZ(msg, varargin)
        %readXYZ Read XYZ from PointCloud2 message struct

            % Validate input message data
            validateattributes(msg.data,{'uint8'},{'vector'},'rosReadXYZ');
            validateattributes(msg.width,{'uint32','double'},{'scalar'},'rosReadXYZ');
            validateattributes(msg.height,{'uint32','double'},{'scalar'},'rosReadXYZ');

            % Parse optional PreserveStructureOnRead property and DataType
            % property. The DataType property will only be used in the case
            % of code generation.
            reshapeOutput = false;
            if ~isempty(varargin)
                nvPairs = struct('PreserveStructureOnRead', uint32(0), 'DataType', uint32(0));
                pOpts = struct('PartialMatching', true, 'CaseSensitivity', false);
                pStruct = coder.internal.parseParameterInputs(nvPairs, pOpts, varargin{1:end});

                reshapeOutput = coder.internal.getParameterValue(pStruct.PreserveStructureOnRead, false, varargin{1:end});
                validateattributes(reshapeOutput,{'logical'},...
                    {'scalar'},'rosReadField','PreserveStructureOnRead');
            end

            % Get field indices for X, Y, and Z coordinates
            xIdx = ros.internal.ros2.SpecialMsgUtil.getFieldNameIndex(msg,'x');
            yIdx = ros.internal.ros2.SpecialMsgUtil.getFieldNameIndex(msg,'y');
            zIdx = ros.internal.ros2.SpecialMsgUtil.getFieldNameIndex(msg,'z');

            %TypeConversion - Object handling ROS <--> MATLAB type conversions
            TypeConversion = ros.msg.sensor_msgs.internal.PointCloud2Types;

            % Recover MATLAB data type of field elements
            xMlType = TypeConversion.rosToMATLABType(msg.fields(xIdx).datatype);
            yMlType = TypeConversion.rosToMATLABType(msg.fields(yIdx).datatype);
            zMlType = TypeConversion.rosToMATLABType(msg.fields(zIdx).datatype);

            % Calculate the byte offsets for the different fields
            % This helps with performance, since we can re-use the
            % byte index computed below
            xOff = double(msg.fields(xIdx).offset);

            pointIndices = 1: msg.width * msg.height;
            % Retrieve the XYZ data and concatenate into one matrix
            if isempty(coder.target)
                if ~isempty(varargin) && pStruct.DataType ~= 0
                    optDataTypeArg = coder.internal.getParameterValue(pStruct.DataType, 'single', varargin{1:end});
                    if ~(strcmp(xMlType, optDataTypeArg) && strcmp(yMlType, optDataTypeArg) && strcmp(zMlType, optDataTypeArg))
                        warning(message('ros:mlroscpp:pointcloud:DataTypeArgIgnored'))
                    end
                end

                yOff = double(msg.fields(yIdx).offset);
                zOff = double(msg.fields(zIdx).offset);

                fieldNames = {'x', 'y', 'z'};
                offsets = [xOff yOff zOff];
                dataTypes = [double(msg.fields(xIdx).datatype) ...
                    double(msg.fields(yIdx).datatype) double(msg.fields(zIdx).datatype)];
                xyzRequested = true;
                rgbRequested = false;

                % Compute actual number of available points (accounting for
                % potential truncation)
                numPointsActual = min(msg.height*msg.width, fix(numel(msg.data)/double(msg.point_step)));
                pointIdxIsValid = (0 < pointIndices) & (pointIndices <= numPointsActual);

                validPointIndices = pointIndices(pointIdxIsValid);
                validPointIndicesCasted = cast(validPointIndices(:)-1,'like',uint32(msg.point_step));

                pcReaderCppObj = roscpp.util.internal.RosConvFncsManager;
                xyzTemp = pcReaderCppObj.readPointCloud(msg.data, msg.width, msg.height, ...
                    msg.point_step, fieldNames, offsets, dataTypes, xyzRequested, rgbRequested, validPointIndicesCasted, numel(validPointIndices));
                if any(~pointIdxIsValid(:))
                    numPoints = numel(pointIdxIsValid);
                    if any(strcmp(xMlType, {'single','double'}))
                        fieldPoints = NaN(numPoints, 3, xMlType);
                    else
                        fieldPoints = zeros(numPoints, 3, xMlType);
                    end
                    fieldPoints(pointIdxIsValid, :) = xyzTemp;
                    xyzTemp = fieldPoints;
                end
            else
                % Parse the data type
                mlType = 'single';
                if ~isempty(varargin)
                    mlType = coder.const(convertStringsToChars(coder.internal.getParameterValue(pStruct.DataType, 'single', varargin{1:end})));
                    validatestring(mlType, {'single', 'double'}, 'rosReadXYZ');
                end
                
                % We must assert that the data type matches the data type
                % specified on the message
                coder.internal.assert(strcmp(xMlType, mlType), 'ros:mlros2:codegen:DataTypeConflict', 'rosReadXYZ');
                coder.internal.assert(strcmp(yMlType, mlType), 'ros:mlros2:codegen:DataTypeConflict', 'rosReadXYZ');
                coder.internal.assert(strcmp(zMlType, mlType), 'ros:mlros2:codegen:DataTypeConflict', 'rosReadXYZ');

                % Get byte index only once (this is expensive)
                [byteIdx, pointIdxIsValid] = ros.internal.ros2.SpecialMsgUtil.getByteIndexForField(msg, xIdx, pointIndices, 1);

                yOff = double(msg.fields(yIdx).offset) - xOff;
                zOff = double(msg.fields(zIdx).offset) - xOff;

                xyzTemp = ...
                    [ros.internal.ros2.SpecialMsgUtil.readFieldFromData(msg.data, byteIdx, pointIdxIsValid, mlType, 1),        ...
                     ros.internal.ros2.SpecialMsgUtil.readFieldFromData(msg.data, byteIdx + yOff, pointIdxIsValid, mlType, 1), ...
                     ros.internal.ros2.SpecialMsgUtil.readFieldFromData(msg.data, byteIdx + zOff, pointIdxIsValid, mlType, 1)];
            end

            % Reshape the output if requested by the user
            if reshapeOutput && msg.height ~= 1
                xyz = reshape(xyzTemp, msg.width, msg.height, 3);
                xyz = permute(xyz, [2 1 3]);
            else
                xyz = xyzTemp;
            end
        end

        function rgb = readRGB(msg, varargin)
        %readRGB Read RGB from PointCloud2 message struct

        % Validate input message data
            validateattributes(msg.data,{'uint8'},{'vector'},'rosReadRGB');
            validateattributes(msg.width,{'uint32','double'},{'scalar'},'rosReadRGB');
            validateattributes(msg.height,{'uint32','double'},{'scalar'},'rosReadRGB');

            % Parse optional PreserveStructureOnRead property
            reshapeOutput = false;
            if ~isempty(varargin)
                nvPairs = struct('PreserveStructureOnRead', uint32(0), 'DataType', uint32(0));
                pOpts = struct('PartialMatching', true, 'CaseSensitivity', false);
                pStruct = coder.internal.parseParameterInputs(nvPairs, pOpts, varargin{1:end});

                reshapeOutput = coder.internal.getParameterValue(pStruct.PreserveStructureOnRead, false, varargin{1:end});
                validateattributes(reshapeOutput,{'logical'},...
                    {'scalar'},'rosReadField','PreserveStructureOnRead');
            end

            % Get field index for the RGB field
            rgbIdx = ros.internal.ros2.SpecialMsgUtil.getFieldNameIndex(msg,'rgb');
            TypeConversion = ros.msg.sensor_msgs.internal.PointCloud2Types;

            % Recover MATLAB data type of field elements
            rgbMlType = TypeConversion.rosToMATLABType(msg.fields(rgbIdx).datatype);

            validTypes = {'uint8', 'uint16', 'int32', 'uint32', 'single', 'double'};
            validatestring(rgbMlType, validTypes, 'rosReadRGB');

            pointIndices = 1: msg.height * msg.width;
            numPoints = numel(pointIndices);
            if isempty(coder.target)
                if ~isempty(varargin) && pStruct.DataType ~= 0
                    optDataTypeArg = coder.internal.getParameterValue(pStruct.DataType, 'double', varargin{1:end});
                    if ~(strcmp(rgbMlType, optDataTypeArg))
                        warning(message('ros:mlroscpp:pointcloud:DataTypeArgIgnored'))
                    end
                end
                fieldNames = {'rgb'};
                offsets = double(msg.fields(rgbIdx).offset);
                dataTypes = double(msg.fields(rgbIdx).datatype);
                xyzRequested = false;
                rgbRequested = true;

                % Compute actual number of available points (accounting for
                % potential truncation)
                numPointsActual = min(msg.height*msg.width, fix(numel(msg.data)/double(msg.point_step)));
                pointIdxIsValid = (0 < pointIndices) & (pointIndices <= numPointsActual);

                validPointIndices = pointIndices(pointIdxIsValid);
                validPointIndicesCasted = cast(validPointIndices(:)-1,'like',msg.point_step);

                pcReaderCppObj = roscpp.util.internal.RosConvFncsManager;
                rgbRaw = pcReaderCppObj.readPointCloud(msg.data, msg.width, msg.height, ...
                    msg.point_step, fieldNames, offsets, dataTypes, xyzRequested, rgbRequested, validPointIndicesCasted, numel(validPointIndices));
                if any(~pointIdxIsValid(:))
                    fieldPoints = zeros(numPoints, 3, class(rgbRaw));
                    fieldPoints(pointIdxIsValid, :) = rgbRaw;
                    rgbRaw = fieldPoints;
                end
                rgbTemp = cast(NaN(numPoints,3),rgbMlType);
                rgbTemp(pointIdxIsValid, :) = rgbRaw(pointIdxIsValid,:);
            else
                % Parse the data type
                mlType = 'double';
                if ~isempty(varargin)
                    mlType = coder.const(convertStringsToChars(coder.internal.getParameterValue(pStruct.DataType, 'double', varargin{1:end})));
                    validatestring(mlType, validTypes, 'rosReadRGB');
                end

                % We must assert that the data type matches the data type
                % specified on the message
                coder.internal.assert(strcmp(rgbMlType, mlType), 'ros:mlroscpp:pointcloud:RGBDataTypeConflict', 'rosReadRGB');

                % Get byte index for the RGB field (this is expensive)
                count = 4;
                [byteIdx, pointIdxIsValid] = ros.internal.ros2.SpecialMsgUtil.getByteIndexForField(msg, rgbIdx, pointIndices, count);
                numPoints = numel(pointIndices);
                rgbRaw = ros.internal.ros2.SpecialMsgUtil.readRGBFieldFromData(msg.data, byteIdx, pointIdxIsValid, count);

                rgbTemp = cast(NaN(numPoints,3),mlType);

                if any(strcmp(mlType, {'single', 'double'}))
                    % Scale values from [0,255] to [0,1] range
                    % Also convert from BGR -> RGB
                    rgbTemp(pointIdxIsValid, :) = cast(rgbRaw(pointIdxIsValid, 3:-1:1),mlType) / 255;
                else
                    rgbTemp(pointIdxIsValid, :) = rgbRaw(pointIdxIsValid, 3:-1:1);
                end
            end

            % Reshape the output if requested by the user
            if reshapeOutput && msg.height ~= 1
                % Since image is row-major, this is a two-step process
                rgb = reshape(rgbTemp, msg.width, msg.height, 3);
                rgb = permute(rgb, [2 1 3]);
            else
                rgb = rgbTemp;
            end
        end

        function [cart, cartAngles] = readCartesian(msg, varargin)
        %readCartesian Read cartesian from LaserScan message

        % Validate input message data
            validateattributes(msg.ranges,{'single','uint16'},{'vector'},'rosReadCartesian');
            validateattributes(msg.range_max,{'single','uint16','double','uint32'},{'scalar'},'rosReadCartesian');
            validateattributes(msg.range_min,{'single','uint16','double','uint32'},{'scalar'},'rosReadCartesian');

            defaults.RangeLimits = [msg.range_min,msg.range_max];
            args = ros.internal.ros2.SpecialMsgUtil.parseReadCartesianArguments(defaults, varargin{:});

            R = msg.ranges(:);

            if isempty(coder.target)
                % If no ranges are available, return right away
                if isempty(R)
                    cart = single.empty(0,2);
                    cartAngles = single.empty(0,1);
                    return;
                end
            end

            % Discard all values that are below lower range limit or above the
            % upper range limit. Also discard infinite or NaN values
            validIdx = isfinite(R) & R >= args.RangeLimits(1) & R <= args.RangeLimits(2);
            validR = R(validIdx);

            % Filter scan angles for all valid range readings
            angles = rosReadScanAngles(msg);
            cartAngles = angles(validIdx);
            x = cos(cartAngles) .* validR;
            y = sin(cartAngles) .* validR;
            cart = double([x,y]);
        end

        function angles = readScanAngles(msg)
        %readScanAngles Read scan angles from LaserScan message

        % Validate input message data
            validateattributes(msg.ranges,{'single','uint16'},{'vector'},'rosReadScanAngles');
            validateattributes(msg.angle_increment,{'single','uint16','double','uint32'},{'scalar'},'rosReadScanAngles');
            validateattributes(msg.angle_min,{'single','uint16','double','uint32'},{'scalar'},'rosReadScanAngles');

            numReadings = numel(msg.ranges);
            rawAngles = msg.angle_min + (0:numReadings-1)' * msg.angle_increment;

            % Wrap the angles to the (-pi,pi] interval.
            angles = robotics.internal.wrapToPi(double(rawAngles));
        end

        function lidarScanObj = readLidarScan(msg)
        %readLidarScan Construct LidarScan object from LaserScan message

            validateattributes(msg.ranges,{'single','uint16'},{'vector'},'rosReadLidarScan');

            angles = rosReadScanAngles(msg);
            lidarScanObj = lidarScan(double(msg.ranges), angles);
        end

        function map = readBinaryOccupancyGrid(msg, varargin)
        %readBinaryOccupancyGrid return binary map from input message

        % Validate message values
            validateattributes(msg.data,{'int8','double'},{'vector'},'rosReadBinaryOccupancyGrid');
            validateattributes(msg.info.width,{'uint32','double'},{'scalar'},'rosReadBinaryOccupancyGrid');
            validateattributes(msg.info.height,{'uint32','double'},{'scalar'},'rosReadBinaryOccupancyGrid');
            ros.internal.ros2.SpecialMsgUtil.validateOccGridMsgValues(msg);

            % Define default variables
            defaultOccupancyThreshold = 50;
            defaultValueForUnknown = 0;
            unknownValueInMsg = -1;
            opts.OccupancyThreshold = defaultOccupancyThreshold;
            opts.ValueForUnknown = defaultValueForUnknown;

            if ~isempty(varargin)
                opts = ros.internal.ros2.SpecialMsgUtil.parseReadBOGInputs(varargin{:});
            end

            resolution = 1/double(msg.info.resolution);

            % Handle eps errors in resolution due to single to double
            % conversion. Using 1e-5 as a practical maximum EPS of a single
            % resolution
            if abs(round(resolution) - resolution) < 1e-5
                resolution = round(resolution);
            end

            map = binaryOccupancyMap(double(msg.info.height), ...
                                     double(msg.info.width), resolution, 'grid');

            % Fill in the meta information
            map.GridLocationInWorld = double([msg.info.origin.position.x,...
                                              msg.info.origin.position.y]);

            % Set grid values in the binaryOccupancyMap
            data = msg.data;
            values = double(data);
            values(data == unknownValueInMsg) = opts.ValueForUnknown;
            values(data < opts.OccupancyThreshold & data ~= unknownValueInMsg) = 0;
            values(data >= opts.OccupancyThreshold) = 1;

            % Write the values in the binaryOccupancyMap
            map = ros.internal.ros2.SpecialMsgUtil.writeToOG(map, values);
        end

        function map = readOccupancyGrid(msg)
        %readOccupancyGrid return map from input message

        % Validate message values
            validateattributes(msg.data,{'int8'},{'vector'},'rosReadOccupancyGrid');
            validateattributes(msg.info.width,{'uint32','double'},{'scalar'},'rosReadOccupancyGrid');
            validateattributes(msg.info.height,{'uint32','double'},{'scalar'},'rosReadOccupancyGrid');
            ros.internal.ros2.SpecialMsgUtil.validateOccGridMsgValues(msg);

            unknownValueInMsg = -1;
            MaxValueInMsg = 100;

            resolution = 1/double(msg.info.resolution);

            % Handle eps errors in resolution due to single to double
            % conversion. Using 1e-5 as a practical maximum EPS of a single
            % resolution
            if abs(round(resolution) - resolution) < 1e-5
                resolution = round(resolution);
            end

            map = occupancyMap(double(msg.info.height), ...
                               double(msg.info.width), resolution, 'grid');

            % Fill in the meta information
            map.GridLocationInWorld = double([msg.info.origin.position.x,...
                                              msg.info.origin.position.y]);

            % Set grid values in the occupancyMap
            data = msg.data;
            values = double(data);
            values(data == unknownValueInMsg) = MaxValueInMsg/2;
            values = values/MaxValueInMsg;

            % Write the values in the occupancyMap
            map = ros.internal.ros2.SpecialMsgUtil.writeToOG(map, values);
        end

        function msgAssigned = writeBinaryOccupancyGrid(msg, map)
        %writeBinaryOccupancyGrid Write map to binary OccupancyGrid message

            validateattributes(msg.data,{'int8'},{'vector'},'rosWriteBinaryOccupancyGrid');

            validateattributes(map,{'binaryOccupancyMap'}, {'nonempty', 'scalar'});

            % Fill in the meta information
            msg.info.resolution = single(1/map.Resolution);
            msg.info.width = uint32(map.GridSize(2));
            msg.info.height = uint32(map.GridSize(1));
            msg.info.origin.position.x = double(map.GridLocationInWorld(1));
            msg.info.origin.position.y = double(map.GridLocationInWorld(2));

            % Get grid values from the BinaryOccupancyGrid
            values = ros.internal.ros2.SpecialMsgUtil.readFromBOG(map);
            reshapedValues = values(:);

            % Create returned message based on computed values
            msgAssigned = msg;
            msgAssigned.data = int8(reshapedValues);
        end

        function msgAssigned = writeOccupancyGrid(msg, map)
        %writeOccupancyGrid Write map to OccupancyGrid message

            validateattributes(map,{'occupancyMap'}, {'nonempty', 'scalar'});
            validateattributes(msg.data,{'int8'},{'vector'},'rosWriteOccupancyGrid');

            % Fill in the meta information
            msg.info.resolution = single(1/map.Resolution);
            msg.info.width = uint32(map.GridSize(2));
            msg.info.height = uint32(map.GridSize(1));
            msg.info.origin.position.x = double(map.GridLocationInWorld(1));
            msg.info.origin.position.y = double(map.GridLocationInWorld(2));

            % Get grid values from the OccupancyGrid
            values = ros.internal.ros2.SpecialMsgUtil.readFromOG(map);
            reshapedValues = values(:);

            % Create returned message based on computed values
            msgAssigned = msg;
            msgAssigned.data = int8(reshapedValues);
        end

        function q = readQuaternion(msg)
        %readQuaternion Extract quaternion from input message

            q = quaternion(msg.w, msg.x, msg.y, msg.z);
        end

        function varargout = showDetails(msg)
        %showDetails Display details of a message

        % Print structure
            structLevel = 1;
            detailedDisplay = ros.msg.internal.MessageDisplay.printStruct(msg, structLevel);

            % Return the detailed data string, if requested by user
            if nargout > 0
                varargout{1} = detailedDisplay;
                return
            end

            % Otherwise, print to console
            disp(detailedDisplay)
        end

        function plotHandles = plotPointCloud2(msg, varargin)
        %plotPointCloud2 Plot PointCloud2 given message

            validateattributes(msg.header.frame_id,{'char'},{'scalartext'},'rosPlot');

            % Parse input arguments
            defaults.Parent = [];
            defaults.MarkerEdgeColor = 'invalid';
            args = ros.internal.ros2.SpecialMsgUtil.parseScatterArguments(defaults, varargin{:});

            % Get XYZ coordinates
            xyz = rosReadXYZ(msg);

            % Determine color of point cloud and call scatter3
            sHandle = ros.internal.ros2.SpecialMsgUtil.colorScatter(msg, xyz, defaults, args);

            % Properly scale the data
            axis(args.Parent, 'equal');
            grid(args.Parent, 'on');
            title(args.Parent, message('ros:mlroscpp:pointcloud:PointCloud').getString);
            xlabel(args.Parent, 'X');
            ylabel(args.Parent, 'Y');
            zlabel(args.Parent, 'Z');

            % Show the camera toolbar and enable the orbit camera
            figureHandle = ancestor(args.Parent, 'figure');
            cameratoolbar(figureHandle, 'Show');
            cameratoolbar(figureHandle, 'SetMode', 'orbit');
            cameratoolbar(figureHandle, 'ResetCamera');

            % See http://www.ros.org/reps/rep-0103.html#axis-orientation
            % for information on ROS coordinate systems
            if contains((msg.header.frame_id), '_optical')
                % For point clouds recorded from a camera system, a
                % different axis orientation applies: z forward, x right,
                % and y down.

                % Change the principal axis to -Y and show a good
                % perspective view
                cameratoolbar(figureHandle, 'SetCoordSys','Y');
                set(args.Parent, 'CameraUpVector', [0 -1 0]);
                camorbit(args.Parent, -110, -15, 'data', [0 1 0]);
            else
                % By default, use the standard ROS convention: x forward, y
                % left, and z up.
                cameratoolbar(figureHandle, 'SetCoordSys','Z');
                set(args.Parent, 'CameraUpVector', [0 0 1]);
                camorbit(args.Parent, -70, -15, 'data', [0 0 1]);
            end

            % Use the rotation icon instead of the standard pointer
            ptrData = setptr('rotate');
            set(figureHandle, ptrData{:});

            % Return the scatter handle if requested by the user
            if nargout > 0
                plotHandles = sHandle;
            end
        end

        function plotHandles = plotLaserScan(msg, varargin)
        %plotLaserScan Plot LaserScan given message

            validateattributes(msg.ranges,{'single','uint16','double','uint32'},{'vector'},'rosPlot');
            validateattributes(msg.range_max,{'single','uint16','double','uint32'},{'scalar'},'rosPlot');

            if isa(msg.range_max,'double')
                msg.range_max = single(msg.range_max);
            end
            if isa(msg.ranges,'double')
                msg.ranges = single(msg.ranges);
            end

            [cart, cartAngles] = rosReadCartesian(msg);

            % Parse input arguments
            % By default, use the maximum range for scaling
            defaults.Parent = [];

            % Only take the maximum range as default, if it is finite and
            % positive. Otherwise, use the maximum measured range as default.
            if isfinite(msg.range_max) && msg.range_max > 0
                defaults.MaximumRange = msg.range_max;
            else
                defaults.MaximumRange = max(msg.ranges);
            end

            % keep metaClassObj
            metaClassObj.Name = 'laser';
            lineHandles = robotics.utils.internal.plotScan(metaClassObj, cart, cartAngles, defaults, varargin{:});

            % Return the line handle if requested by the user
            if nargout > 0
                plotHandles = lineHandles;
            end
        end

        function map = readOccupancyMap3D(msg)
        %readOccupancyMap3D Return an occupancyMap3D object

        % Error out for non OcTree Id (i.e., for ColorOcTree)
            if ~strcmp('OcTree', msg.id)
                error(message('ros:mlroscpp:octomap:UnSupportedOctreeFormat', msg.id));
            end

            % Construct the occupancyMap3D object and populate the data
            if isempty(coder.target)
                try
                    % readOccupancyMap3D requires both ROS Toolbox and NAV
                    % Toolbox. Since MapIO comes from backend, this call to
                    % occupancyMap3D ensures error message containing
                    % information about the Navigation Toolbox.
                    map = nav.algs.internal.MapIO.deserializeROSMsgData(msg.binary, msg.resolution, msg.data);
                catch ex
                    validateattributes(msg.data,{'int8'},{'vector'},'rosReadOccupancyMap3D');
                    validateattributes(msg.id,{'char'},{'vector'},'rosReadOccupancyMap3D');
                    validateattributes(msg.binary,{'logical'},{'scalar'},'rosReadOccupancyMap3D');
                    validateattributes(msg.resolution,{'uint32','double'},{'scalar'},'rosReadOccupancyMap3D');
                    % Do license check by instantiating basic Navigation Toolbox class
                    occupancyMap3D;
                    % If not a license issue, propagate exception
                    rethrow(ex)
                end
            end
        end

        function msgProperties = tfMsgProps()
        %tfMsgProps returns proper message properties for
        %geometry_msgs/TransformStamped messages

            persistent rostfProps
            if isempty(rostfProps)
                % Field names for tf message and supported entity
                % messages
                rostfProps = struct('header',{'Header','header'},'frame_id',{'FrameId','frame_id'}, ...
                                    'child_frame_id',{'ChildFrameId','child_frame_id'},'transform',{'Transform','transform'},...
                                    'translation', {'Translation','translation'},'rotation',{'Rotation','rotation'},...
                                    'x',{'X','x'},'y',{'Y','y'},'z',{'Z','z'},'w',{'W','w'},'point',{'Point','point'},...
                                    'quaternion',{'Quaternion','quaternion'},'vector',{'Vector','vector'},...
                                    'pose',{'Pose','pose'},'orientation',{'Orientation','orientation'},...
                                    'position',{'Position','position'});
            end

            % Field names for ROS 2 msg structs
            msgProperties = rostfProps(2);
        end

        function msg = writeXYZ(msg, xyzPoints, offset, pointStep)
        %writeXYZ Write points in (x,y,z) coordinates to the message
        %   writeXYZ(MSG, XYZPOINTS) writes the MxNx3 data or Nx3 matrix of 3D point
        %   coordinates to the point cloud message struct MSG.
        %   Each input row in XYZ is a 3-vector representing one 3D point.
        %   The number of rows of XYZ needs to be equal to the number of
        %   points currently stored in MSG.
        %   This function creates fields with XYZ point information or
        %   completely overwrite any existing XYZ point information and
        %   replaces it with the points given in XYZ.

        % Save local information for the message

            if isequal(msg.width,0) || isequal(msg.height,0)
                % assign height and width to ROS PointCloud2 message struct
                if ismatrix(xyzPoints) % assumes that the points are unordered
                    msg.height = uint32(1);
                    msg.width = uint32(size(xyzPoints, 1));
                else % assumes that the points are ordered
                    msg.height = uint32(size(xyzPoints, 1));
                    msg.width = uint32(size(xyzPoints, 2));
                end
            end

            if ~ismatrix(xyzPoints)
                xyzFlat = reshape(permute(xyzPoints, [2 1 3]), [], 3);
            else
                xyzFlat = xyzPoints;
            end

            numPoints = msg.height * msg.width;
            validateattributes(xyzFlat, {'numeric'}, ...
                {'ncols', 3, 'nrows', numPoints}, 'writeXYZ', 'xyzFlat');

            allFieldNames = ros.internal.ros2.SpecialMsgUtil.getAllFieldNames(msg);
            hasXYZ = false;
            for i=1:length(allFieldNames)
                if strcmp(allFieldNames{i},'x')
                    hasXYZ = true;
                    break;
                end
            end

            if ~hasXYZ
                fieldNames = {'x','y','z'};
                numFields = length(fieldNames);
                fieldOffsets = zeros(numFields, 1, 'uint32');
                fieldDatatypes  = zeros(numFields, 1, 'uint8');

                %numBytesArray used to calulate byte offset
                numBytesArray = zeros(length(fieldNames), 1);
                if ~isempty(coder.target)
                    numExistingFields = length(allFieldNames);
                else
                    numExistingFields = length(allFieldNames) -1 ;
                end
                % Get the index of the last existing field
                xyzStartIdx = numExistingFields + 1;

                if isequal(offset,0) && ~isequal(xyzStartIdx,1)
                    % If the XYZ field is being appended to already
                    % existing fields in message, offset is set according
                    % to the size and offset of the last field.
                    [~, numBytes] = ros.msg.sensor_msgs.internal.PointCloud2Types.rosToMATLABType(msg.fields(numExistingFields).datatype);
                    offset = msg.fields(numExistingFields).offset + uint32(numBytes);
                end

                if ~isempty(coder.target) && isempty(msg.fields)
                    msg.fields = repmat(ros2message('sensor_msgs/PointField'),numFields,1);
                end

                for idx = xyzStartIdx:length(fieldNames)
                    type = class(xyzFlat(:,idx));
                    [rosType, numBytes] = ros.msg.sensor_msgs.internal.PointCloud2Types.matlabToROSType(type);
                    numBytesArray(idx) = numBytes;
                    fieldOffsets(idx) =  uint32(offset);
                    offset = offset + numBytes;
                    fieldDatatypes(idx) = uint8(rosType);

                    % create ROS PointField message with metadata.
                    msg.fields(idx,1) = ros.internal.ros2.SpecialMsgUtil.createPointField(fieldNames{idx}, fieldOffsets(idx), ...
                        fieldDatatypes(idx));
                end

                totalBytesInRow = offset;
                if isequal(msg.point_step, 0)
                    msg.point_step = pointStep;
                end
                if msg.point_step < totalBytesInRow
                    msg.point_step = totalBytesInRow;
                end
                if msg.point_step < pointStep
                    msg.point_step = pointStep;
                end

                msg.row_step = msg.point_step * msg.width;
                if isequal(msg.data,0)
                    msg.data = zeros(msg.point_step*numPoints, 1, 'uint8');
                end
            end

            % set IsDense field in message as xyzFlat may contain infinite or NaN values 
            msg.is_dense = allfinite(xyzFlat);

            % Get PointField information for x, y, and z data. If these do
            % not exist an error will be displayed.
            xIdx = ros.internal.ros2.SpecialMsgUtil.getFieldNameIndex(msg,'x');
            yIdx = ros.internal.ros2.SpecialMsgUtil.getFieldNameIndex(msg,'y');
            zIdx = ros.internal.ros2.SpecialMsgUtil.getFieldNameIndex(msg,'z');

            % Get byte index only once (this is expensive)
            byteIdx = ros.internal.ros2.SpecialMsgUtil.getByteIndexForField(msg, xIdx).';

            % Calculate the byte offsets for the different fields
            % This helps with performance, since we can re-use the
            % already calculated byte index
            xOff = double(msg.fields(xIdx).offset);
            yOff = double(msg.fields(yIdx).offset) - xOff;
            zOff = double(msg.fields(zIdx).offset) - xOff;

            % Write XYZ byte array back to message data property
            writeDataToField(xIdx, xyzFlat(:,1), byteIdx);
            writeDataToField(yIdx, xyzFlat(:,2), byteIdx + yOff);
            writeDataToField(zIdx, xyzFlat(:,3), byteIdx + zOff);

            function writeDataToField(fieldIdx, fieldData, byteIdx)
            %writeDataToField Write data to a point field

                if isempty(coder.target)
                    %TypeConversion - Object handling ROS <--> MATLAB type
                    %conversions
                    TypeConversion = ros.msg.sensor_msgs.internal.PointCloud2Types;
                    % Recover MATLAB data type of field elements
                    datatype = msg.fields(fieldIdx).datatype;
                    mlFieldType = TypeConversion.rosToMATLABType(datatype);
                else
                    mlFieldType = class(fieldData);
                end

                % Cast the input to the expected type
                if ~isa(fieldData, mlFieldType)
                    fieldData = cast(fieldData,mlFieldType);
                end
                % Treat field data as byte array
                fieldDataBytes = typecast(fieldData, 'uint8');

                % Now write the field data to the point field
                msg.data(byteIdx) = fieldDataBytes;
            end
        end

        function msg = writeRGB(msg, rgb, offset, pointStep, allFieldNames)
            %writeRGB Write color information to the message

            % allFieldNames = ros.internal.SpecialMsgUtil.getAllFieldNames(msg);
            % Convert single or double color values to uint8.
            if isa(rgb, 'single') || isa(rgb, 'double')
                % im2uint8 cannot be used here as there cannot be a dependency
                % on IPT which is not a shared library or belong to
                % matlab.
                RGBConverted = uint8(255*rgb);
            else
                RGBConverted = rgb;
            end

            if ismatrix(rgb) % assumes that the points are unordered
                RGBFlat = reshape(RGBConverted', [], 1);
            else % assumes that the points are ordered
                RGBFlat = reshape(permute(RGBConverted, [3 2 1]), [], 1);
            end

            numPoints = msg.height * msg.width;
            type = class(rgb);
            [rosType, numBytesRGB] = ros.msg.sensor_msgs.internal.PointCloud2Types.matlabToROSType(type);

            hasRGB = false;
            for i=1:length(allFieldNames)
                if strcmp(allFieldNames{i},'rgb')
                    hasRGB = true;
                    break;
                end
            end

            if ~hasRGB
                fieldName = 'rgb';
                numExistingFields = length(allFieldNames);
                % Get the index of the last existing field
                idx = numExistingFields + 1;

                if isequal(offset,0) && ~isequal(idx,1)
                    % If the RGB field is being appended to already
                    % existing fields in message, offset is set according
                    % to the size and offset of the last field.
                    [~, numBytes] = ...
                        ros.msg.sensor_msgs.internal.PointCloud2Types.rosToMATLABType(msg.fields(numExistingFields).datatype);
                    offset = msg.fields(numExistingFields).offset + uint32(numBytes);
                end

                fieldOffset =  uint32(offset);
                fieldDatatype = uint8(rosType);

                if ~isempty(coder.target)
                    existingFields = msg.fields;
                    msg.fields = repmat(ros2message('sensor_msgs/PointField'),idx,1);
                    msg.fields(1:idx-1,1) = existingFields;
                end

                % create ROS PointField message with metadata.
                msg.fields(idx,1) = ros.internal.ros2.SpecialMsgUtil.createPointField(fieldName, ...
                    fieldOffset, ...
                    fieldDatatype);

                totalBytesInRow = offset + uint32(numBytesRGB);
                if isequal(msg.point_step, 0)
                    msg.point_step = pointStep;
                end
                if msg.point_step < totalBytesInRow
                    msg.point_step = totalBytesInRow;
                end
                if msg.point_step < pointStep
                    msg.point_step = pointStep;
                end

                msg.row_step = msg.point_step * msg.width;
                if msg.data == 0
                    msg.data = zeros(msg.point_step*numPoints, 1, 'uint8');
                end
            end

            % generate index matrix for convenient indexing
            startIndices = repmat( double( 1 : msg.point_step : msg.point_step*numPoints), 8, 1);
            indexes = startIndices + repmat( ((0:7)'), 1, size(startIndices, 2)); % no data type has more than 8 bytes
            % assign to Data array

            % Get PointField information for rgb data. If these do
            % not exist an error will be displayed.
            rgbIdx = ros.internal.ros2.SpecialMsgUtil.getFieldNameIndex(msg,'rgb');
            byteOffset = double(msg.fields(rgbIdx).offset);

            if ~isequal(length(msg.data),msg.point_step*numPoints)
                % Re-arrange data while appending
                existingData = msg.data;
                msg.data = zeros(msg.point_step*numPoints, 1, 'uint8');
                indexValues = startIndices(1,:);
                existingDataRows = indexValues(:)+(0:byteOffset-1);
                msg.data(existingDataRows(:,:)') = existingData;
            end

            msg.data(indexes(3:-1:1, :) + byteOffset) = typecast(RGBFlat,'uint8');
        end

        function msg = writeIntensity(msg, intensity, offset, pointStep, allFieldNames)
            %writeIntensity Write intensity values to the message

            % Save local information for the message
            numPoints = msg.height * msg.width;
            if ~isequal(size(intensity,2),1)
                intensityFlat = reshape(permute(intensity, [3 2 1]), [], 1);
            else
                intensityFlat = reshape(intensity', [], 1);
            end

            validateattributes(intensityFlat, {'numeric'}, ...
                {'nonempty', 'ncols', 1, 'nrows', numPoints}, 'writeIntensity', 'intensityFlat');

            % Convert single or double intensity values to same type as of
            % xyzPoints.
            if isa(intensityFlat, 'single') || isa(intensityFlat, 'double')
                xFieldIdx = ros.internal.ros2.SpecialMsgUtil.getFieldNameIndex(msg,'x');
                %TypeConversion - Object handling ROS <--> MATLAB type
                %conversions
                TypeConversion = ros.msg.sensor_msgs.internal.PointCloud2Types;
                % Recover MATLAB data type of field elements
                xyzDatatype = msg.fields(xFieldIdx).datatype;
                if isempty(coder.target)
                    mlFieldType = TypeConversion.rosToMATLABType(xyzDatatype);
                else
                    mlFieldType = class(intensity);
                end
                IntensityConverted = cast(intensityFlat, mlFieldType);
            else
                IntensityConverted = intensityFlat;
            end

            type = class(IntensityConverted);
            [rosType, numBytesIntensity] = ros.msg.sensor_msgs.internal.PointCloud2Types.matlabToROSType(type);

            hasIntensity = false;
            for i=1:length(allFieldNames)
                if strcmp(allFieldNames{i},'intensity')
                    hasIntensity = true;
                    break;
                end
            end

            if ~hasIntensity
                fieldName = 'intensity';
                numExistingFields = length(allFieldNames);
                % Get the index of the last existing field
                idx = numExistingFields + 1;

                if isequal(offset,0) && ~isequal(idx,1)
                    % If the INTENSITY field is being appended to already
                    % existing fields in message, offset is set according
                    % to the size and offset of the last field.
                    [~, numBytes] = ros.msg.sensor_msgs.internal.PointCloud2Types.rosToMATLABType(msg.fields(numExistingFields).datatype);
                    offset = msg.fields(numExistingFields).offset + uint32(numBytes);
                end

                fieldOffset =  uint32(offset);
                fieldDatatype = uint8(rosType);

                if ~isempty(coder.target)
                    existingFields = msg.fields;
                    msg.fields = repmat(ros2message('sensor_msgs/PointField'),idx,1);
                    msg.fields(1:idx-1,1) = existingFields;
                end

                % create ROS PointField message with metadata.
                msg.fields(idx,1) = ros.internal.ros2.SpecialMsgUtil.createPointField(fieldName, fieldOffset, ...
                    fieldDatatype);

                totalBytesInRow = offset + uint32(numBytesIntensity);
                if isequal(msg.point_step, 0)
                    msg.point_step = pointStep;
                end
                if msg.point_step < totalBytesInRow
                    msg.point_step = totalBytesInRow;
                end
                if msg.point_step < pointStep
                    msg.point_step = pointStep;
                end

                msg.row_step = msg.point_step * msg.width;
                if msg.data == 0
                    msg.data = zeros(msg.point_step*numPoints, 1, 'uint8');
                end
            end

            % generate index matrix for convenient indexing
            startIndices = repmat( double( 1 : msg.point_step : msg.point_step*numPoints), 8, 1);
            indexes = startIndices + repmat( ((0:7)'), 1, size(startIndices, 2)); % no data type has more than 8 bytes
            % assign to Data array

            % Get PointField information for intensity data. If these do
            % not exist an error will be displayed.
            intensityIdx = ros.internal.ros2.SpecialMsgUtil.getFieldNameIndex(msg,'intensity');
            byteOffset = double(msg.fields(intensityIdx).offset);

            if ~isequal(length(msg.data),msg.point_step*numPoints)
                % Re-arrange data while appending
                existingData = msg.data;
                msg.data = zeros(msg.point_step*numPoints, 1, 'uint8');
                indexValues = startIndices(1,:);
                existingDataRows = indexValues(:)+(0:byteOffset-1);
                msg.data(existingDataRows(:,:)') = existingData;
            end

            msg.data(indexes(1 : numBytesIntensity, :) + byteOffset) = typecast(IntensityConverted,'uint8');
        end

        function [T, hMat, tVec, rMat] = readTransform(tfmsg, option)
        %readTransform Read transformation from transformStamped message
        
            % Initialize output arguments
            T = se3;
            hMat = zeros(4,4);

            % Extract translation and rotation mesasge
            tranMsg = tfmsg.transform.translation;
            rotMsg = tfmsg.transform.rotation;

            % Construct tVec and rMat
            tVec = [tranMsg.x, tranMsg.y, tranMsg.z];
            quat = [rotMsg.w, rotMsg.x, rotMsg.y, rotMsg.z];

            rMat = quat2rotm(quat);
            
            if strcmp(option, 'se3')
                % Construct se3
                T = se3(quat2rotm(quat),tVec);
            elseif strcmp(option, 'single')
                % Construct hMat
                hMat(4,4) = 1;
                hMat(1:3,1:3) = rMat;
                hMat(1:3,4) = tVec';
            end
        end
    end

    methods (Static, Access = private)
        function fieldIdx = getFieldNameIndex(msg, fieldName)
        %getFieldNameIndex Get index of field in PointField array

            allFieldNames = ros.internal.ros2.SpecialMsgUtil.getAllFieldNames(msg);
            fieldIdx = 0;
            for i=1:length(allFieldNames)
                if strcmp(allFieldNames{i},fieldName)
                    fieldIdx = i;
                end
            end

            missingXYZ = isequal(fieldIdx,0) && (strcmp(fieldName,'x') || strcmp(fieldName,'y') || strcmp(fieldName,'z'));
            missingRGB = isequal(fieldIdx,0) && (strcmp(fieldName,'rgb'));
            missingOthers = isequal(fieldIdx,0) && (~(missingXYZ && missingRGB));

            coder.internal.errorIf(missingXYZ,'ros:mlroscpp:pointcloud:InvalidXYZData');
            coder.internal.errorIf(missingRGB,'ros:mlroscpp:pointcloud:NoColorData');
            coder.internal.errorIf(missingOthers,'ros:mlroscpp:pointcloud:InvalidFieldName',...
                                   fieldName, strjoin(allFieldNames, ', '));
        end

        function [byteIdx, pointIdxIsValid] = getByteIndexForField(msg, fieldIdx, pointIndices, count)
        %getByteIndexForField Get a vector of bytes indices for field
        %   at specific points

        % Save local information for the message
            offset = msg.fields(fieldIdx).offset;
            datatype = msg.fields(fieldIdx).datatype;

            %TypeConversion - Object handling ROS <--> MATLAB type conversions
            TypeConversion = ros.msg.sensor_msgs.internal.PointCloud2Types;

            if nargin < 3
                pointIndices = 1:msg.height*msg.width;
            end
            if nargin < 4
                count = msg.fields(fieldIdx).count;
            end

            % Number of points requested
            numPoints = numel(pointIndices);

            % Compute actual number of available points (accounting for
            % potential truncation)
            numPointsActual = min(msg.height*msg.width, fix(numel(msg.data)/double(msg.point_step)));

            % Recover field offset and MATLAB data type of field elements
            [~, numBytes] = TypeConversion.rosToMATLABType(datatype);
            numBytes = numBytes * double(count);

            % Extract the bytes corresponding to this field for all points
            byteIdx = zeros(numPoints, numBytes);
            pointIdxIsValid = (0 < pointIndices) & (pointIndices <= numPointsActual);
            validPointIndices = pointIndices(pointIdxIsValid);
            startIndices = double(offset ...
                                  + msg.point_step*cast(validPointIndices(:)-1,'like',msg.point_step));
            byteIdx(pointIdxIsValid,:) = bsxfun(@plus, startIndices, 1:numBytes);
            if nargout < 2
                byteIdx = byteIdx(pointIdxIsValid,:);
            end
        end

        function fieldPoints = readFieldFromData(data, byteIdx, pointIdxIsValid, mlType, count)
        %readFieldFromData Read data based on given field name
        %   This is a generic function for reading data from any field
        %   name specified
        %
        %   This function returns an NxC array of values. N is the
        %   number of points in the point cloud and C is the number of
        %   values that is assigned for every point in this field. In
        %   most cases, C will be 1.

            numPoints = numel(pointIdxIsValid);
            % Initialize output
            rawData = reshape(data(byteIdx(pointIdxIsValid,:)'),[],1);

            if isempty(coder.target)
                validPoints = reshape(typecast(rawData, mlType), count, []).';
                if any(~pointIdxIsValid(:))
                    if any(strcmp(mlType, {'single','double'}))
                        fieldPoints = NaN(numPoints, count, mlType);
                    else
                        fieldPoints = zeros(numPoints, count, mlType);
                    end
                    fieldPoints(pointIdxIsValid, :) = validPoints;
                else
                    fieldPoints = validPoints;
                end
            else
                validPoints = reshape(typecast(rawData, mlType), count, []).';
                if any(~pointIdxIsValid(:))
                    fieldPoints = NaN(numPoints, count, mlType);

                    fieldPoints(pointIdxIsValid, :) = validPoints;
                else
                    fieldPoints = validPoints;
                end
            end
        end

        function fieldPoints = readRGBFieldFromData(data, byteIdx, pointIdxIsValid, count)
        %readRGBFieldFromData Read data based on given rgb field
        %   This is a generic function for reading data from any field
        %   name specified
        %
        %   This function returns an NxC array of values. N is the
        %   number of points in the point cloud and C is the number of
        %   values that is assigned for every point in this field. In
        %   most cases, C will be 1.

            numPoints = numel(pointIdxIsValid);
            % Initialize output
            rawData = reshape(data(byteIdx(pointIdxIsValid, 1:count)'),[],1);
            validPoints = reshape(rawData, count, []).';

            if any(~pointIdxIsValid(:))
                fieldPoints = zeros(numPoints, count, 'uint8');
                fieldPoints(pointIdxIsValid, :) = validPoints;
            else
                fieldPoints = validPoints;
            end
        end

        function args = parseReadCartesianArguments(defaults, varargin)
        %parseReadCartesianArguments Parse arguments for readCartesian
        %   function

        % Return right away if there is nothing to be parsed

            if isempty(varargin)
                args = defaults;
            end

            % Parse the range limits
            nvPairs = struct('RangeLimits',uint32(0));
            pOpts = struct('PartialMatching',true,'CaseSensitivity',false);
            pStruct = coder.internal.parseParameterInputs(nvPairs,pOpts,varargin{1:end});

            rangeLimits = coder.internal.getParameterValue(pStruct.RangeLimits,defaults.RangeLimits,varargin{1:end});
            validateattributes(rangeLimits,{'numeric'},...
                               {'vector', 'numel', 2, 'nonnan', 'nondecreasing'},'LaserScan','RangeLimits');
            args.RangeLimits = rangeLimits;
        end

        function validateOccGridMsgValues(msg)
        %validateOccGridMsgValues Validate message values

            UnknownValueInMsg = -1;
            MaxValueInMsg = 100;
            % Error if height and width do not match number of elements in
            % the data
            if isempty(coder.target)
                if numel(msg.data) ~= msg.info.height*msg.info.width
                    error(message('ros:mlroscpp:occgrid:InvalidDataSize', ...
                                  num2str(numel(msg.data)), num2str(msg.info.height), ...
                                  num2str(msg.info.width)));
                end
            end

            % Error if resolution is zero
            validateattributes(msg.info.resolution, {'numeric'}, ...
                               {'nonempty', 'nonnan', 'positive'}, ...
                               'readOccupancyGrid', 'Resolution');

            % Validate that Data is between [0, 100] or -1
            validateattributes(msg.data, {'numeric'}, ...
                               {'nonempty', '>=' UnknownValueInMsg, '<=', MaxValueInMsg}, ...
                               'readOccupancyGrid', 'Data');

            % Validate origin
            origin = [msg.info.origin.position.x, msg.info.origin.position.y];
            validateattributes(origin, {'numeric'}, {'nonnan', 'finite'}, ...
                               'readOccupancyGrid', 'Origin');
        end

        function opts = parseReadBOGInputs(varargin)
        %parseReadBOGInputs Input parser for read method

        % default occupancy threshold and value for unknown
            opts.OccupancyThreshold = 50;
            opts.ValueForUnknown = 0;

            if ~isempty(varargin)
                opts.OccupancyThreshold = varargin{1};
                validateattributes(opts.OccupancyThreshold, {'double'}, ...
                                   {'nonnegative', 'scalar', 'finite'});
            end

            if length(varargin)>1
                opts.ValueForUnknown = varargin{2};
                validateattributes(opts.ValueForUnknown, {'numeric','logical'}, ...
                                   {'nonnegative', 'scalar', 'binary'});
            end
        end

        function bog = writeToOG(og,values)
        %writeToOG Write values to binaryOccupancyMap or occupancyMap

        % Use reverse GridSize values because data will be transposed
        % in the next step
            matrix = reshape(values, og.GridSize(2), og.GridSize(1));

            % While writing the data needs to be transposed and flipped to
            % be compatible with ROS
            matrix = flip(matrix');
            [x, y] =  ndgrid(1:og.GridSize(1), 1:og.GridSize(2));
            og.setOccupancy([x(:) y(:)], matrix(:), 'grid');
            bog = og;
        end

        function values = readFromBOG(map)
        %readFromBOG Read values from binaryOccupancyMap

            occgrid = map.occupancyMatrix;

            %maxValueInMsg The maximum value in ROS nav_msgs/OccupancyGrid message
            maxValueInMsg = 100;

            % The data needs to be flipped and transposed to be compatible
            % with ROS
            values = double((flip(occgrid))');
            values(values == 1) = maxValueInMsg;
        end

        function values = readFromOG(map)
        %readFromOG Read values from occupancyMap

            occgrid = map.occupancyMatrix;

            %MaxValueInMsg The maximum value in ROS nav_msgs/OccupancyGrid message
            MaxValueInMsg = 100;

            % The data needs to be flipped and transposed to be compatible
            % with ROS
            values = (flip(occgrid))';
            values = values*MaxValueInMsg;
        end

        function args = parseScatterArguments(defaults, varargin)
        %parseScatterArguments Parse arguments for scatter3 function

        % Parse inputs
            parser = inputParser;

            % Cannot make any assumptions about data type
            addParameter(parser, 'Parent', defaults.Parent);

            addParameter(parser, 'MarkerEdgeColor', defaults.MarkerEdgeColor, ...
                         @(x) validateattributes(x, {'numeric', 'char'}, ...
                                                 {}, 'PointCloud2', 'MarkerEdgeColor'));

            % Return data
            parse(parser, varargin{:});
            args = parser.Results;

            % Delay the preparation of a new plot (and potentially the creation
            % of a new window until all other inputs have been parsed)
            if isnumeric(args.Parent) && isequal(args.Parent, defaults.Parent)
                args.Parent = newplot;
            end

            % Check that parent is a graphics Axes handle
            robotics.internal.validation.validateAxesHandle(args.Parent, ...
                                                            'ros:mlroscpp:pointcloud:ParentNotHandle');
        end

        function rgbExists = hasRGBData(msg)
        %hasRGBData Checks if this point cloud contains RGB data

            if isempty(coder.target)
                try
                    ros.internal.ros2.SpecialMsgUtil.getFieldNameIndex(msg,'rgb');
                    rgbExists = true;
                catch
                    rgbExists = false;
                end
            end
        end

        function scatterHandle = colorScatter(msg, xyz, defaults, args)
        %colorScatter Determine point cloud color and call scatter3
        %   This will be based on user input and the existence of
        %   RGB data in the point cloud.

        % If user specified a marker edge color use it for the scatter
        % plot
            if ~strcmp(args.MarkerEdgeColor, defaults.MarkerEdgeColor)
                color = args.MarkerEdgeColor;
                scatterHandle = scatter3(args.Parent, xyz(:,1), xyz(:,2), ...
                                         xyz(:,3), 1, '.', 'MarkerEdgeColor', color);
                return;
            end

            % Use point RGB color information (if it exists)
            if ros.internal.ros2.SpecialMsgUtil.hasRGBData(msg)
                color = rosReadRGB(msg);
                scatterHandle = scatter3(args.Parent, xyz(:,1), xyz(:,2), ...
                                         xyz(:,3), 1, color, '.');
                return;
            end

            % If no color specified by user, or no RGB information
            % available, use scatter3 defaults
            scatterHandle = scatter3(args.Parent, xyz(:,1), xyz(:,2), ...
                                     xyz(:,3), 1, '.');
        end

        function pField = createPointField(fieldName, fieldOffset, dataType)
            %createPointField Create ROS 2 PointField message and return it

            pField = ros2message('sensor_msgs/PointField');
            pField.name = fieldName;
            pField.offset = fieldOffset;
            pField.datatype = dataType;
            pField.count = uint32(1);
        end
    end
end
