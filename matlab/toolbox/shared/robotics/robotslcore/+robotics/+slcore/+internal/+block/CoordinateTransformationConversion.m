classdef CoordinateTransformationConversion < matlab.System & ...
        robotics.slcore.internal.InternalAccess
%This class is for internal use only. It may be removed in the future.

%COORDINATETRANSFORMATIONCONVERSION Convert between coordinate transformation representations
%   This system object is intended for use with the MATLAB System
%   block. In order to access the conversion functionality from MATLAB,
%   see the Coordinate Transformations in Robotics documentation
%   section.
%
%   Example:
%
%       % Create conversion object
%       ctc = robotics.slcore.internal.block.CoordinateTransformationConversion(...
%           'InputRepresentation', 'Homogeneous Transformation', ...
%           'OutputRepresentation', 'Rotation Matrix', ...
%           'ShowTrVecOutputPort', true);
%
%       % Convert representation
%       [R, p] = ctc(eye(4));

%   Copyright 2017-2024 The MathWorks, Inc.

%#codegen

    properties (Nontunable)
        %InputRepresentation Input representation type
        %   This should be one of the following values:
        %   ['Axis-Angle'|'Euler Angles'|'Homogeneous Transformation'|'Quaternion'|{'Rotation Matrix'}|'Translation Vector']
        InputRepresentation = robotics.slcore.internal.xform.Type.Quaternion

        %OutputRepresentation Output representation type
        %   This should be one of the following values:
        %   ['Axis-Angle'|'Euler Angles'|'Homogeneous Transformation'|'Quaternion'|{'Rotation Matrix'}|'Translation Vector']
        OutputRepresentation = robotics.slcore.internal.xform.Type.RotationMatrix

        %InputEulerSequence Input Euler axis rotation sequence
        %   If Euler Angles are specified as the input representation,
        %   this should be one of the following values: [{'ZYX'}|'ZYZ'|'XYZ'|'ZXY'|'ZXZ'|'YXZ'|'YXY'|'YZX'|'YZY'|'XYX'|'XZY'|'XZX']
        InputEulerSequence = robotics.slcore.internal.xform.Util.getDefaultSpecialization(robotics.slcore.internal.xform.Type.Euler)

        %OutputEulerSequence Output Euler axis rotation sequence
        %   If Euler Angles are specified as the output representation,
        %   this should be one of the following values: [{'ZYX'}|'ZYZ'|'XYZ'|'ZXY'|'ZXZ'|'YXZ'|'YXY'|'YZX'|'YZY'|'XYX'|'XZY'|'XZX']
        OutputEulerSequence = robotics.slcore.internal.xform.Util.getDefaultSpecialization(robotics.slcore.internal.xform.Type.Euler)

        %ShowTrVecOutputPort Show TrVec output port if input is a homogeneous transform
        ShowTrVecOutputPort (1, 1) logical = robotics.slcore.internal.xform.Util.getDefaultSpecialization(robotics.slcore.internal.xform.Type.Homogeneous)

        %ShowTrVecInputPort Show TrVec input port if output is a homogeneous transform
        ShowTrVecInputPort (1, 1) logical = robotics.slcore.internal.xform.Util.getDefaultSpecialization(robotics.slcore.internal.xform.Type.Homogeneous)
    end

    properties (Constant, Hidden)
        InputRepresentationSet = matlab.system.StringSet(robotics.slcore.internal.xform.Util.getAllNames())
        InputEulerSequenceSet = matlab.system.StringSet(robotics.slcore.internal.xform.Util.getSpecializations(robotics.slcore.internal.xform.Type.Euler))
        OutputRepresentationSet = matlab.system.StringSet(robotics.slcore.internal.xform.Util.getAllNames())
        OutputEulerSequenceSet = matlab.system.StringSet(robotics.slcore.internal.xform.Util.getSpecializations(robotics.slcore.internal.xform.Type.Euler))
    end

    methods
        function obj = CoordinateTransformationConversion(varargin)
        %CoordinateTransformationConversion Constructor
            setProperties(obj, nargin, varargin{:});
        end
    end

    methods (Access = protected)
        %% Common functions
        function [outRaw, outPosRaw] = stepImpl(obj, inRaw, inPosRaw)
        %stepImpl Compute conversion
            inSpec = obj.getInputSpecialization();
            outSpec = obj.getOutputSpecialization();

            in = obj.formatInput(obj.InputRepresentation, inRaw);
            out = robotics.slcore.internal.block.CoordinateTransformationConversion.convert(...
                in, obj.InputRepresentation, inSpec, obj.OutputRepresentation, outSpec);

            if obj.hasInputTrVec()
                % Output is TForm; manually set position
                inPos = obj.formatInput(robotics.slcore.internal.xform.Type.TranslationVector, inPosRaw);
                out(1:3, 4) = inPos; % TForm should be scaled correctly
            elseif obj.hasOutputTrVec()
                % Input is TForm; manually extract position
                outPos = tform2trvec(in); % TForm may not be scaled correctly
                outPosRaw = obj.formatOutput(robotics.slcore.internal.xform.Type.TranslationVector, outPos);
            end

            outRaw = obj.formatOutput(obj.OutputRepresentation, out);
        end

        %% Helper functions
        function [in] = formatInput(~, type, inRaw)
        %formatInput Ensure input, if a vector, is converted to a row
        % vector.
            if robotics.slcore.internal.xform.Util.isVector(type)
                in = inRaw(:)';
            else
                in = inRaw;
            end
        end

        function [outRaw] = formatOutput(~, type, out)
        %formatOutput Ensure output, if a vector, is converted to a
        %column vector.
            if robotics.slcore.internal.xform.Util.isVector(type)
                outRaw = out(:);
            else
                outRaw = out;
            end
        end

        function [out] = hasInputTrVec(obj)
        %hasInputTrVec Return whether object must accept an input
        % translation vector
            out = robotics.slcore.internal.xform.Util.canHaveOppositeTrVec(obj.OutputRepresentation, obj.InputRepresentation) && ...
                  obj.ShowTrVecInputPort;
        end

        function [out] = hasOutputTrVec(obj)
        %hasOutputTrVec Return whether object must provide an output
        % translation vector
            out = robotics.slcore.internal.xform.Util.canHaveOppositeTrVec(obj.InputRepresentation, obj.OutputRepresentation) && ...
                  obj.ShowTrVecOutputPort;
        end

        function [spec] = getInputSpecialization(obj)
        %getInputSpecialization Get specialization for input
        % representation.
            switch obj.InputRepresentation
              case robotics.slcore.internal.xform.Type.Euler
                spec = obj.InputEulerSequence;
              case robotics.slcore.internal.xform.Type.Homogeneous
                spec = obj.ShowTrVecOutputPort;
              otherwise
                spec = [];
            end
        end

        function [spec] = getOutputSpecialization(obj)
        %getOutputSpecialization Get specialization for input
        % representation.
            switch obj.OutputRepresentation
              case robotics.slcore.internal.xform.Type.Euler
                spec = obj.OutputEulerSequence;
              case robotics.slcore.internal.xform.Type.Homogeneous
                spec = obj.ShowTrVecInputPort;
              otherwise
                spec = [];
            end
        end

        %% System block property functions
        function validatePropertiesImpl(obj)
        %validatePropertiesImpl Validate properties set for an object
            if ~robotics.slcore.internal.xform.Util.isValidConversion(obj.InputRepresentation, obj.OutputRepresentation)
                robotics.slcore.internal.xform.Util.errorTypeConversion(obj.InputRepresentation, obj.OutputRepresentation);
            end
            % Specializations will be validated via System property
            % constraints
        end

        function inactive = isInactivePropertyImpl(obj, prop)
        %isInactivePropertyImpl True if property should not be displayed
            inactive = false;
            switch prop
              case {'InputRepresentation', 'OutputRepresentation'}
                inactive = false;
              case 'ShowTrVecOutputPort'
                if ~robotics.slcore.internal.xform.Util.canHaveOppositeTrVec(obj.InputRepresentation, obj.OutputRepresentation)
                    inactive = true;
                end
              case 'InputEulerSequence'
                if ~isequal(obj.InputRepresentation, robotics.slcore.internal.xform.Type.Euler)
                    inactive = true;
                end
              case 'ShowTrVecInputPort'
                if ~robotics.slcore.internal.xform.Util.canHaveOppositeTrVec(obj.OutputRepresentation, obj.InputRepresentation)
                    inactive = true;
                end
              case 'OutputEulerSequence'
                if ~isequal(obj.OutputRepresentation, robotics.slcore.internal.xform.Type.Euler)
                    inactive = true;
                end
            end
        end

        %% System block port functions
        function validateInputsImpl(obj, inRaw, inPosRaw)
        % validates the inputs
            robotics.slcore.internal.xform.Util.validateAttributes(obj.InputRepresentation, inRaw);
            if obj.hasInputTrVec()
                robotics.slcore.internal.xform.Util.validateAttributes(robotics.slcore.internal.xform.Type.TranslationVector, inPosRaw);
            end
        end

        function [n1, n2] = getInputNamesImpl(obj)
        %getInputNamesImpl Return input port names for System block
            n1 = robotics.slcore.internal.block.CoordinateTransformationConversion.getPortLabel(obj.InputRepresentation, ...
                                                                                                obj.getInputSpecialization());
            if obj.hasInputTrVec()
                n2 = robotics.slcore.internal.xform.Util.getShortName(robotics.slcore.internal.xform.Type.TranslationVector);
            end
        end

        function [n1, n2] = getOutputNamesImpl(obj)
        %getOutputNamesImpl Return output port names for System block
            n1 = robotics.slcore.internal.block.CoordinateTransformationConversion.getPortLabel(obj.OutputRepresentation, ...
                                                                                                obj.getOutputSpecialization());
            if obj.hasOutputTrVec()
                n2 = robotics.slcore.internal.xform.Util.getShortName(robotics.slcore.internal.xform.Type.TranslationVector);
            end
        end

        function num = getNumInputsImpl(obj)
        %getNumInputsImpl Get number of inputs
            num = 1;
            if obj.hasInputTrVec()
                num = num + 1;
            end
        end

        function num = getNumOutputsImpl(obj)
        %getNumOutputsImpl Define number of outputs for system with optional outputs
            num = 1;
            if obj.hasOutputTrVec()
                num = num + 1;
            end
        end

        function icon = getIconImpl(~)
        %getIconImpl Define icon for System block
            filepath = fullfile(matlabroot, 'toolbox', 'shared', 'robotics', 'robotslcore', 'blockicons', 'CoordinateTransformIcon.dvg');
            icon = matlab.system.display.Icon(filepath);
        end

        function flag = isInputSizeMutableImpl(~, ~)
        %isInputSizeMutableImpl Mutable input size status
            flag = false;
        end

        function [o1, o2] = getOutputSizeImpl(obj)
        %getOutputSizeImpl Return size for each output port
            o1 = robotics.slcore.internal.xform.Util.getSize(obj.OutputRepresentation);
            if nargout >= 2
                o2 = robotics.slcore.internal.xform.Util.getSize(robotics.slcore.internal.xform.Type.TranslationVector);
            end
        end

        function [o1, o2] = getOutputDataTypeImpl(obj)
        %getOutputDataTypeImpl Return data type for each output port
            o1 = propagatedInputDataType(obj, 1);
            o2 = o1;
        end

        function [o1, o2] = isOutputComplexImpl(~)
        %isOutputComplexImpl Return true for each output port with complex data
            o1 = false;
            o2 = false;
        end

        function [o1, o2] = isOutputFixedSizeImpl(~)
        %isOutputFixedSizeImpl Return true for each outport with fixed size
            o1 = true;
            o2 = true;
        end

        %% System block display functions
        function maskDisplay = getMaskDisplayImpl(obj)
        %getMaskDisplayImpl Customize the mask icon display
        % Construct the input labels based no the number of inputs
            portLabelText = {};

            numInputs = obj.getNumInputsImpl;
            [inputNames{1:numInputs}] = obj.getInputNamesImpl;
            for i = 1:numInputs
                portLabelText{end + 1} = ['port_label(''input'', ' num2str(i) ', ''' inputNames{i} ''', ''TexMode'', ''on'')'];
            end

            numOutputs = obj.getNumOutputsImpl;
            [outputNames{1:numOutputs}] = obj.getOutputNamesImpl;
            for i = 1:numOutputs
                portLabelText{end + 1} = ['port_label(''output'', ' num2str(i) ', ''' outputNames{i} ''', ''TexMode'', ''on'')'];
            end

            maskDisplay = { ...
                '% Draw port labels', ...
                portLabelText{:}};
        end

        function flag = supportsMultipleInstanceImpl(~)
            flag = true;
        end
    end

    methods (Static, Access = {?robotics.slcore.internal.InternalAccess})
        %% Core functionality
        function [out] = convert(in, inType, inSpec, outType, outSpec)
        %convert Convert from one representation to the other, given
        % a specialization. This ignores specializations for
        % homogeneous types for handling input / output translation
        % vectors. Assumes that input and output spaces (rot, transl,
        % both) are compatible.
            if isequal(inType, outType) && ...
                    (isequal(inType, robotics.slcore.internal.xform.Type.Homogeneous) || isequal(inSpec, outSpec))
                out = in;
            else
                switch inType
                  case robotics.slcore.internal.xform.Type.AxisAngle
                    out = axang2any(in, outType, outSpec);
                  case robotics.slcore.internal.xform.Type.Euler
                    out = eul2any(in, inSpec, outType, outSpec);
                  case robotics.slcore.internal.xform.Type.Quaternion
                    out = quat2any(in, outType, outSpec);
                  case robotics.slcore.internal.xform.Type.RotationMatrix
                    out = rotm2any(in, outType, outSpec);
                  case robotics.slcore.internal.xform.Type.Homogeneous
                    out = tform2any(in, outType, outSpec);
                  case robotics.slcore.internal.xform.Type.TranslationVector
                    out = trvec2tform(in);
                end
            end
        end
    end

    methods (Static, Access = protected)
        %% System block static functions
        function header = getHeaderImpl(~)
        %getHeaderImpl Get header for display in System block
            header = matlab.system.display.Header(mfilename('class'), ...
                                                  'Title', message('shared_robotics:robotslcore:xform:ConversionBlockName').getString(), ...
                                                  'Text', message('shared_robotics:robotslcore:xform:ConversionBlockHeaderText').getString(), ...
                                                  'ShowSourceLink', false);
        end

        function groups = getPropertyGroupsImpl()
        %getPropertyGroupsImpl Display parameters with groups and tabs
            secInput = matlab.system.display.Section(...
                'Title', message('shared_robotics:robotslcore:xform:DialogInputSectionName').getString(), ...
                'PropertyList', ...
                getPropertyObjects({'InputRepresentation', 'InputEulerSequence', 'ShowTrVecInputPort'}));
            secOutput = matlab.system.display.Section(...
                'Title', message('shared_robotics:robotslcore:xform:DialogOutputSectionName').getString(), ...
                'PropertyList', ...
                getPropertyObjects({'OutputRepresentation', 'OutputEulerSequence', 'ShowTrVecOutputPort'}));
            mainGroup = matlab.system.display.SectionGroup(...
                'Title', message('shared_robotics:robotslcore:xform:DialogConversionGroupName').getString(), ...
                'Sections', [secInput, secOutput]);
            groups = mainGroup;
        end
    end

    methods (Static, Access = {?robotics.slcore.internal.InternalAccess})
        %% Testing helper functions
        function [args] = getConstructorArgs(inType, inSpec, outType, outSpec)
        %getConstructorArgs Get arguments to appropriately redirect
        % specializations for a system object
            args = ['InputRepresentation', inType, ...
                    robotics.slcore.internal.block.CoordinateTransformationConversion.getSpecializationArgs('Input', 'Output', inType, inSpec, outType), ...
                    'OutputRepresentation', outType, ...
                    robotics.slcore.internal.block.CoordinateTransformationConversion.getSpecializationArgs('Output', 'Input', outType, outSpec, inType)];
        end

        function [args] = getSpecializationArgs(prefix, prefixOpposite, type, spec, typeOpposite)
        %getSpecializationArgs Get additional args to pass to system object constructor
        % prefix - 'Input' or 'Output'
            switch type
              case robotics.slcore.internal.xform.Type.Euler
                args = {[prefix, 'EulerSequence'], spec};
              case robotics.slcore.internal.xform.Type.Homogeneous
                if robotics.slcore.internal.xform.Util.canHaveOppositeTrVec(type, typeOpposite)
                    args = {['ShowTrVec', prefixOpposite, 'Port'], spec};
                else
                    args = {};
                end
              otherwise
                args = {};
            end
        end

        %% System block helper static functions
        function [label] = getPortLabel(type, spec)
        %getPortLabel Get TeX formatted port label for a representation
        % type and its specialization
            shortName = robotics.slcore.internal.xform.Util.getShortName(type);
            switch type
              case robotics.slcore.internal.xform.Type.Euler
                % Only show specialization for Euler
                label = sprintf('%s%s', shortName, spec);
              otherwise
                label = shortName;
            end
        end
    end
end

function [ps] = getPropertyObjects(names)
%getPropertyObjects Take a cell array of names and return a cell array of
% display properties to permit using the message catalog
    ps = cell(size(names));
    for i = 1:numel(names)
        name = names{i};
        desc = message(['shared_robotics:robotslcore:xform:Dialog', name]).getString();
        ps{i} = matlab.system.display.internal.Property(name, ...
                                                        'Description', desc);
    end
end

function [out] = axang2any(in, outType, outSpec)
%axang2any Convert Axis-Angle to any. Assume that this is a valid
% conversion (non-idempotent, compatible space)
    switch outType
      case robotics.slcore.internal.xform.Type.Quaternion
        out = axang2quat(in);
      case robotics.slcore.internal.xform.Type.RotationMatrix
        out = axang2rotm(in);
      case robotics.slcore.internal.xform.Type.Homogeneous
        out = axang2tform(in);
      case robotics.slcore.internal.xform.Type.Euler
        tmp = axang2rotm(in);
        out = rotm2eul(tmp, outSpec);
    end
end

function [out] = eul2any(in, inSpec, outType, outSpec)
%eul2any Convert Euler Angles to any. Assume that this is a valid
% conversion (non-idempotent, compatible space)
    switch outType
      case robotics.slcore.internal.xform.Type.Quaternion
        out = eul2quat(in, inSpec);
      case robotics.slcore.internal.xform.Type.RotationMatrix
        out = eul2rotm(in, inSpec);
      case robotics.slcore.internal.xform.Type.Homogeneous
        out = eul2tform(in, inSpec);
      case robotics.slcore.internal.xform.Type.AxisAngle
        tmp = eul2rotm(in, inSpec);
        out = rotm2axang(tmp);
      case robotics.slcore.internal.xform.Type.Euler
        tmp = eul2rotm(in, inSpec);
        out = rotm2eul(tmp, outSpec);
    end
end

function [out] = quat2any(in, outType, outSpec)
%quat2any Convert Quaternion to any. Assume that this is a valid
% conversion (non-idempotent, compatible space)
    switch outType
      case robotics.slcore.internal.xform.Type.AxisAngle
        out = quat2axang(in);
      case robotics.slcore.internal.xform.Type.Euler
        out = quat2eul(in, outSpec);
      case robotics.slcore.internal.xform.Type.RotationMatrix
        out = quat2rotm(in);
      case robotics.slcore.internal.xform.Type.Homogeneous
        out = quat2tform(in);
    end
end

function [out] = rotm2any(in, outType, outSpec)
%rotm2any Convert Rotation Matrix to any. Assume that this is a valid
% conversion (non-idempotent, compatible space)
    switch outType
      case robotics.slcore.internal.xform.Type.AxisAngle
        out = rotm2axang(in);
      case robotics.slcore.internal.xform.Type.Euler
        out = rotm2eul(in, outSpec);
      case robotics.slcore.internal.xform.Type.Quaternion
        out = rotm2quat(in);
      case robotics.slcore.internal.xform.Type.Homogeneous
        out = rotm2tform(in);
    end
end

function [out] = tform2any(in, outType, outSpec)
%tform2any Convert Homogeneous to any. Assume that this is a valid
% conversion (non-idempotent, compatible space)
    switch outType
      case robotics.slcore.internal.xform.Type.AxisAngle
        out = tform2axang(in);
      case robotics.slcore.internal.xform.Type.Euler
        out = tform2eul(in, outSpec);
      case robotics.slcore.internal.xform.Type.Quaternion
        out = tform2quat(in);
      case robotics.slcore.internal.xform.Type.RotationMatrix
        out = tform2rotm(in);
      case robotics.slcore.internal.xform.Type.TranslationVector
        out = tform2trvec(in);
    end
end
