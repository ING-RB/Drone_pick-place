function [Height, Width, FPFieldLengths, PointStep, RowStep, DataLength, Data, FPNames, FPNameLengths, FPOffsets, FPDatatypes, FPCounts] = ...
    WritePointCloudFcnBlock(MaxDataLength, NumFields, NameLength, XYZ, RGB, Alpha, Intensity, unstructured, HasRGB, HasAlpha, HasIntensity, FieldNamesStruct, ROSVer) %#codegen
%This function is for internal use only. It may be removed in the future.

%WriteImageFcnBlock creates ROS point cloud data from input XYZ and RGB
%FieldNamesStruct amps the PointField name field to the encoding
% (e.g. single)

%   Copyright 2021-2024 The MathWorks, Inc.

    % Verification
    switch ROSVer
        case 'ROS'
            ROSVerification(unstructured, HasRGB, HasAlpha, HasIntensity, XYZ, RGB, Alpha, Intensity);
        case 'ROS2'
            ROS2Verification(unstructured, HasRGB, HasAlpha, HasIntensity, XYZ, RGB, Alpha, Intensity);
    end

    if HasAlpha && unstructured
        RGBA = cat(2, RGB, Alpha);
    elseif HasAlpha
        RGBA = cat(3, RGB, Alpha);
    else
        RGBA = RGB;
    end

    % convert RGB(A) from double to uint8
    RGBAConverted = uint8(RGBA*255);

    % assign metadata
    if ismatrix(XYZ) % assumes that the points are unordered
        NumPts = size(XYZ, 1);
        Height = uint32(1);
        Width = uint32(NumPts);
        RGBFlat = reshape(RGBAConverted', [], 1);
        XYZunordered = XYZ;
        IntensityFlat = reshape(Intensity', [], 1);

    else % assumes that the points are ordered
        Height = uint32(size(XYZ, 1));
        Width = uint32(size(XYZ, 2));
        NumPts = Height*Width;
        RGBFlat = reshape(permute(RGBAConverted, [3 2 1]), [], 1);
        XYZunordered = reshape(permute(XYZ, [2 1 3]), [], 3);
        IntensityFlat = reshape(Intensity', [], 1);
    end

    Data = zeros(MaxDataLength, 1, 'uint8');
    FNames = fieldnames(FieldNamesStruct);

    % FP prefix designates sensor_msgs/PointField properties
    % allocate properties
    FPFieldLengths = uint32(length(FNames));
    FPNames_M      = zeros(NumFields, NameLength, 'uint8');
    FPNameLengths  = zeros(NumFields, 1, 'uint32');
    FPOffsets      = zeros(NumFields, 1, 'uint32');
    FPDatatypes    = zeros(NumFields, 1, 'uint8');
    FPCounts       = zeros(NumFields, 1, 'uint32');

    % NumBytesArray used to calculate byte offset
    NumBytesArray = zeros(length(FNames), 1);

    % assign sensor_msgs/PointField properties
    TotalBytes = 0;
    for idx = 1:length(FNames)
        FName = FNames{idx};
        Type = FieldNamesStruct.(FName);
        FPNameLengths(idx) = uint32(numel(FName));
        FPNames_M(idx, 1:numel(FName)) = uint8(FName);

        [RosType, numBytes] = ros.msg.sensor_msgs.internal.PointCloud2Types.matlabToROSType(Type);
        
        NumBytesArray(idx) = numBytes;
        FPOffsets(idx) = uint32(TotalBytes);
        
        TotalBytes = TotalBytes + numBytes;
        
        FPDatatypes(idx) = uint8(RosType);
        FPCounts(idx) = uint32(1);
    end

    % flatten names matrix to one dim
    FPNames = reshape(FPNames_M', [], 1);

    % assign metadata
    PointStep = uint32(sum(NumBytesArray));
    stride = uint32(sum(NumBytesArray));
    RowStep = uint32(PointStep * Width); %PointStep* Width;
    DataLength = uint32(stride*NumPts);

    % generate index matrix for convenient indexing
    StartIndices = repmat(double(1 : stride : DataLength), 8, 1);
    Inds = StartIndices + repmat(((0:7)'), 1, size(StartIndices, 2)); % no data type has more than 8 bytes
                                                                      % assign to Data array

    for idx = 1:length(FNames)
        FName = FNames{idx};
        byteOffset = double(FPOffsets(idx));
        switch FName
            case 'x'
                Data(Inds(1 : NumBytesArray(idx), :) + byteOffset) = typecast(XYZunordered(:, 1), 'uint8');
            case 'y'
                Data(Inds(1 : NumBytesArray(idx), :) + byteOffset) = typecast(XYZunordered(:, 2), 'uint8');
            case 'z'
                Data(Inds(1 : NumBytesArray(idx), :) + byteOffset) = typecast(XYZunordered(:, 3), 'uint8');
            case 'rgb'
                Data(Inds(NumBytesArray(idx)-1:-1:1, :) + byteOffset) = typecast(RGBFlat, 'uint8');
            case 'rgba'
                Data(Inds([NumBytesArray(idx)-1:-1:1, NumBytesArray(idx)], :) + byteOffset) = typecast(RGBFlat, 'uint8');
            case 'intensity'
                Data(Inds(1 : NumBytesArray(idx), :) + byteOffset) = typecast(IntensityFlat, 'uint8');
        end
    end

end

function ROSVerification(unstructured, HasRGB, HasAlpha, HasIntensity, XYZ, RGB, Alpha, Intensity)
    % check types
    coder.internal.assert(isa(XYZ, 'single'), 'ros:slros:pointcloud:InvalidXYZType', 'single')
    if HasRGB
        coder.internal.assert(isa(RGB, 'float'), 'ros:slros:pointcloud:InvalidRGBType', 'single or double')
    end
    if HasAlpha
        coder.internal.assert(isa(Alpha, 'double'), 'ros:slros:pointcloud:InvalidAlphaType', 'double')
    end
    if HasIntensity
        coder.internal.assert(isa(Intensity, 'single'), 'ros:slros:pointcloud:InvalidIntensityType', 'single')
    end

    % check sizes   
    if unstructured  
        coder.internal.assert((size(XYZ, 2) == 3 && ismatrix(XYZ)), 'ros:slros:pointcloud:IncorrectSizeXYZ')
        
        if HasRGB
            coder.internal.assert((size(RGB, 2) == 3 && ismatrix(RGB)), 'ros:slros:pointcloud:IncorrectSizeRGB')
            coder.internal.assert(all(size(XYZ) == size(RGB)), 'ros:slros:pointcloud:IncompatibleSizesRGBXYZ')
        end
        if HasAlpha
            coder.internal.assert((size(Alpha, 2) == 1 && ismatrix(Alpha)), 'ros:slros:pointcloud:IncorrectSizeAlpha')
            coder.internal.assert((size(Alpha, 1) == size(RGB, 1)), 'ros:slros:pointcloud:IncompatibleSizesRGBAlpha')
        end
        if HasIntensity
            coder.internal.assert((size(Intensity, 2) == 1 && ismatrix(Intensity)), 'ros:slros:pointcloud:IncorrectSizeIntensity')
            coder.internal.assert((size(XYZ, 1) == size(Intensity, 1)), 'ros:slros:pointcloud:IncompatibleSizesIntensityXYZ')
        end

    else % structured 
        coder.internal.assert((size(XYZ, 3) == 3 && ~ismatrix(XYZ)), 'ros:slros:pointcloud:IncorrectSizeXYZ')

        if HasRGB
            coder.internal.assert((size(RGB, 3) == 3 && ~ismatrix(RGB)), 'ros:slros:pointcloud:IncorrectSizeRGB')
            coder.internal.assert(all(size(XYZ) == size(RGB)), 'ros:slros:pointcloud:IncompatibleSizesRGBXYZ')
        end
        if HasAlpha
            coder.internal.assert(ismatrix(Alpha), 'ros:slros:pointcloud:IncorrectSizeAlpha')
            coder.internal.assert(all(size(Alpha, [1 2]) == size(RGB, [1 2])), 'ros:slros:pointcloud:IncompatibleSizesRGBAlpha')
        end      
        if HasIntensity
            coder.internal.assert(ismatrix(Intensity), 'ros:slros:pointcloud:IncorrectSizeIntensity')
            coder.internal.assert(all(size(XYZ, [1 2]) == size(Intensity, [1 2])), 'ros:slros:pointcloud:IncompatibleSizesIntensityXYZ')
        end
    end
end

function ROS2Verification(unstructured, HasRGB, HasAlpha, HasIntensity, XYZ, RGB, Alpha, Intensity)
    % check types
    coder.internal.assert(isa(XYZ, 'single'), 'ros:slros2:pointcloud:InvalidXYZType', 'single')
    if HasRGB
        coder.internal.assert(isa(RGB, 'float'), 'ros:slros2:pointcloud:InvalidRGBType', 'single or double')
    end
    if HasAlpha
        coder.internal.assert(isa(Alpha, 'double'), 'ros:slros2:pointcloud:InvalidAlphaType', 'double')
    end
    if HasIntensity
        coder.internal.assert(isa(Intensity, 'single'), 'ros:slros2:pointcloud:InvalidIntensityType', 'single')
    end

    % check sizes   
    if unstructured  
        coder.internal.assert((size(XYZ, 2) == 3 && ismatrix(XYZ)), 'ros:slros2:pointcloud:IncorrectSizeXYZ')
        
        if HasRGB
            coder.internal.assert((size(RGB, 2) == 3 && ismatrix(RGB)), 'ros:slros2:pointcloud:IncorrectSizeRGB')
            coder.internal.assert(all(size(XYZ) == size(RGB)), 'ros:slros2:pointcloud:IncompatibleSizesRGBXYZ')
        end
        if HasAlpha
            coder.internal.assert((size(Alpha, 2) == 1 && ismatrix(Alpha)), 'ros:slros2:pointcloud:IncorrectSizeAlpha')
            coder.internal.assert((size(Alpha, 1) == size(RGB, 1)), 'ros:slros2:pointcloud:IncompatibleSizesRGBAlpha')
        end
        if HasIntensity
            coder.internal.assert((size(Intensity, 2) == 1 && ismatrix(Intensity)), 'ros:slros2:pointcloud:IncorrectSizeIntensity')
            coder.internal.assert((size(XYZ, 1) == size(Intensity, 1)), 'ros:slros2:pointcloud:IncompatibleSizesIntensityXYZ')
        end

    else % structured 
        coder.internal.assert((size(XYZ, 3) == 3 && ~ismatrix(XYZ)), 'ros:slros2:pointcloud:IncorrectSizeXYZ')

        if HasRGB
            coder.internal.assert((size(RGB, 3) == 3 && ~ismatrix(RGB)), 'ros:slros2:pointcloud:IncorrectSizeRGB')
            coder.internal.assert(all(size(XYZ) == size(RGB)), 'ros:slros2:pointcloud:IncompatibleSizesRGBXYZ')
        end
        if HasAlpha
            coder.internal.assert(ismatrix(Alpha), 'ros:slros2:pointcloud:IncorrectSizeAlpha')
            coder.internal.assert(all(size(Alpha, [1 2]) == size(RGB, [1 2])), 'ros:slros2:pointcloud:IncompatibleSizesRGBAlpha')
        end       
        if HasIntensity
            coder.internal.assert(ismatrix(Intensity), 'ros:slros2:pointcloud:IncorrectSizeIntensity')
            coder.internal.assert(all(size(XYZ, [1 2]) == size(Intensity, [1 2])), 'ros:slros2:pointcloud:IncompatibleSizesIntensityXYZ')
        end
    end
end
