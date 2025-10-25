classdef Type
%This class is for internal use only. It may be removed in the future.

%XFORM.TYPE - Stand-in enumeration type for coordinate transformation
% representations. Please note that this class only has constant
% properties, and this class does not represent the corresponding
% enumeration types.

%   Copyright 2017-2018 The MathWorks, Inc.

%#codegen

    properties (Constant)
        AxisAngle = getText('AxisAnglePopup')
        Euler = getText('EulerPopup')
        Homogeneous = getText('HomogeneousPopup')
        Quaternion = getText('QuaternionPopup')
        RotationMatrix = getText('RotationMatrixPopup')
        TranslationVector = getText('TranslationVectorPopup')
    end

end

function [s] = getText(type)
%getText Obtain text for a given type from the message catalog
%   Always retrieve the text in English to preserve block mask appearance.

    s = message(['shared_robotics:robotslcore:xform:', type]).getString;
end
