classdef Util
%This class is for internal use only. It may be removed in the future.

%XFORM.UTIL - Utilities for coordinate transformation representation
% conversion. Please note that this class only has static and constant
% properties.

%   Copyright 2017-2024 The MathWorks, Inc.

%#codegen

    properties (Constant)
        %RotationOnlyTypes Representation types that indicate rotation only
        RotationOnlyTypes = {
            robotics.slcore.internal.xform.Type.AxisAngle;
            robotics.slcore.internal.xform.Type.Euler;
            robotics.slcore.internal.xform.Type.Quaternion;
            robotics.slcore.internal.xform.Type.RotationMatrix;
                            };

        %TranslationOnlyTypes Representation types that indicate translation
        % only
        TranslationOnlyTypes = {
            robotics.slcore.internal.xform.Type.TranslationVector;
                               };

        %RotationAndTranslationTypes Representation types that indicate
        % rotation and translation
        RotationAndTranslationTypes = {
            robotics.slcore.internal.xform.Type.Homogeneous;
                   };

        %RotationTypes Representation types that indicate rotation (and
        % possibly other spaces). Codegen does not support cell
        % concatenation, so we must explicitly combine them here.
        RotationTypes = {
            robotics.slcore.internal.xform.Type.AxisAngle;
            robotics.slcore.internal.xform.Type.Euler;
            robotics.slcore.internal.xform.Type.Quaternion;
            robotics.slcore.internal.xform.Type.RotationMatrix;
            robotics.slcore.internal.xform.Type.Homogeneous;
                        };

        %TranslationTypes Representation types that indicate translation
        % (and possibly other spaces)
        TranslationTypes = {
            robotics.slcore.internal.xform.Type.TranslationVector;
            robotics.slcore.internal.xform.Type.Homogeneous;
                           };

        %AllTypes All types, ordered for showing in popup widget
        AllTypes = {
            robotics.slcore.internal.xform.Type.AxisAngle;
            robotics.slcore.internal.xform.Type.Euler;
            robotics.slcore.internal.xform.Type.Homogeneous;
            robotics.slcore.internal.xform.Type.Quaternion;
            robotics.slcore.internal.xform.Type.RotationMatrix;
            robotics.slcore.internal.xform.Type.TranslationVector;
                   };
    end

    methods (Static)
        % Properties per representation type

        function [names] = getAllNames()
        %getAllNames Get all types available for conversion
            names = robotics.slcore.internal.xform.Util.AllTypes;
        end

        function [sz] = getSize(type)
        %getSize Get size of a given type
            switch type
              case robotics.slcore.internal.xform.Type.Quaternion
                sz = 4;
              case robotics.slcore.internal.xform.Type.Euler
                sz = 3;
              case robotics.slcore.internal.xform.Type.RotationMatrix
                sz = [3, 3];
              case robotics.slcore.internal.xform.Type.Homogeneous
                sz = [4, 4];
              case robotics.slcore.internal.xform.Type.AxisAngle
                sz = 4;
              case robotics.slcore.internal.xform.Type.TranslationVector
                sz = 3;
            end
        end

        function [name] = getShortName(type)
        %getShortName Get short name for display as a port label
            switch type
              case robotics.slcore.internal.xform.Type.Quaternion
                name = 'Quat';
              case robotics.slcore.internal.xform.Type.Euler
                name = 'Eul';
              case robotics.slcore.internal.xform.Type.RotationMatrix
                name = 'RotM';
              case robotics.slcore.internal.xform.Type.Homogeneous
                name = 'TForm';
              case robotics.slcore.internal.xform.Type.AxisAngle
                name = 'AxAng';
              case robotics.slcore.internal.xform.Type.TranslationVector
                name = 'TrVec';
            end
        end

        function [specs] = getSpecializations(type)
        %getSpecializations Get specializations available for a
        % specific representation type
            switch type
              case robotics.slcore.internal.xform.Type.Euler
                % Axis rotation sequence
                specs = {'ZYX','ZYZ','XYZ','ZXY','ZXZ','YXZ','YXY','YZX','YZY','XYX','XZY','XZX'};
              case robotics.slcore.internal.xform.Type.Homogeneous
                % With opposite TrVec port
                specs = {true, false};
              case {robotics.slcore.internal.xform.Type.AxisAngle, robotics.slcore.internal.xform.Type.Quaternion, ...
                    robotics.slcore.internal.xform.Type.RotationMatrix, robotics.slcore.internal.xform.Type.TranslationVector}
                specs = {};
            end
        end

        function [spec] = getDefaultSpecialization(type)
        %getDefaultSpecialization Get default (initial) specialization
        % for a specific type
            switch type
              case robotics.slcore.internal.xform.Type.Euler
                spec = 'ZYX';
              case robotics.slcore.internal.xform.Type.Homogeneous
                spec = true;
              case {robotics.slcore.internal.xform.Type.AxisAngle, robotics.slcore.internal.xform.Type.Quaternion, ...
                    robotics.slcore.internal.xform.Type.TranslationVector}
                spec = [];
            end
        end

        function [out] = isVector(type)
        %isVector Return true if type is specified using a vector
            sz = robotics.slcore.internal.xform.Util.getSize(type);
            out = isscalar(sz);
        end

        function [out] = isValidConversion(inType, outType)
        %isValidConversion Return true if INTYPE can be converted to
        %  OUTTYPE.
            switch outType
              case robotics.slcore.internal.xform.Util.getValidTypes(inType)
                out = true;
              otherwise
                out = false;
            end
        end

        function [] = validateAttributes(type, value)
        %validateAttributes Validate attributes for a given type, with
        %  respect to Simulink-allowed data types
            sz = robotics.slcore.internal.xform.Util.getSize(type);
            if isscalar(sz)
                validateattributes(value, ...
                                   {'single','double'}, ...
                                   {'nonempty', 'real', 'finite', 'column', 'nrows', sz}, ...
                                   '', '');
            else
                validateattributes(value, ...
                                   {'single','double'}, ...
                                   {'nonempty', 'real', 'finite', '2d', 'size', sz}, ...
                                   '', '');
            end
        end

        function [canHaveExtra] = canHaveOppositeTrVec(typeA, typeB)
        %canHaveOppositeTrVec Can have extra TrVec on opposite side
            if isequal(typeA, robotics.slcore.internal.xform.Type.Homogeneous) && ...
                    ~isequal(typeB, robotics.slcore.internal.xform.Type.Homogeneous) && ~isequal(typeB, robotics.slcore.internal.xform.Type.TranslationVector)
                canHaveExtra = true;
            else
                canHaveExtra = false;
            end
        end

        function [] = errorTypeConversion(inType, outType)
            inSpace = robotics.slcore.internal.xform.Util.getSpaceString(inType);
            outSpace = robotics.slcore.internal.xform.Util.getSpaceString(outType);
            coder.internal.error('shared_robotics:robotslcore:xform:InvalidConversionWithSpace', ...
                                 inType, inSpace, outType, outSpace);
        end
    end

    methods (Static, Access = protected)
        function [validTypes] = getValidTypes(inType)
        %getValidTypes Get valid types that input type can be converted
        % to
            switch inType
              case robotics.slcore.internal.xform.Util.RotationOnlyTypes
                validTypes = robotics.slcore.internal.xform.Util.RotationTypes;
              case robotics.slcore.internal.xform.Util.TranslationOnlyTypes
                validTypes = robotics.slcore.internal.xform.Util.TranslationTypes;
              case robotics.slcore.internal.xform.Util.RotationAndTranslationTypes
                validTypes = robotics.slcore.internal.xform.Util.AllTypes;
            end
        end

        function [space] = getSpaceString(inType)
        %getSpaceName Get the string for a given representation's space
        % (rotation, translation, rotation + translation)
            switch inType
              case robotics.slcore.internal.xform.Util.RotationOnlyTypes
                space = message('shared_robotics:robotslcore:xform:RotationOnlySpace').getString();
              case robotics.slcore.internal.xform.Util.TranslationOnlyTypes
                space = message('shared_robotics:robotslcore:xform:TranslationOnlySpace').getString();
              case robotics.slcore.internal.xform.Util.RotationAndTranslationTypes
                space = message('shared_robotics:robotslcore:xform:RotationAndTranslationSpace').getString();
            end
        end
    end
end
