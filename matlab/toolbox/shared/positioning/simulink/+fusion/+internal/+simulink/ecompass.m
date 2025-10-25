classdef ecompass < matlab.System
%   This class is for internal use only. It may be removed in the future.

%ECOMPASS  Simulink version of the ecompass.

%   The ECOMPASS class implements an orientation estimation system from
%   magnetometer and accelerometer readings for use in MATLAB System Block.

%   Copyright 2023-2024 The MathWorks, Inc.

    %#codegen

    properties (Nontunable)
        % ReferenceFrame Reference frame of orientation output
        %   The reference frame of the orientation output. Specify the
        %   property ReferenceFrame as one of 'NED' (North-East-Down) or
        %   'ENU' (East-North-Up). The default value is 'NED'.
        ReferenceFrame = 'NED';

        %OrientationFormat Output orientation format
        %   Output the computed orientation as an N-by-4 quaternion element
        %   or a 3-by-3-by-N rotation matrix. Specify the property
        %   OrientationFormat as one of 'quaternion' or 'Rotation
        %   matrix'. The default is a quaternion. 
        OrientationFormat = 'quaternion'
    end

    properties (Access = private)
        %pNavFrame Reference frame specific math object
        pNavFrame
    end

    properties (Constant, Hidden)
        ReferenceFrameSet = matlab.system.StringSet( ...
            fusion.internal.frames.ReferenceFrame.getOptions);

        OrientationFormatSet = matlab.system.internal.MessageCatalogSet({...
            'shared_positioning:ecompass:OrientationQuat',...
            'shared_positioning:ecompass:OrientationRotmat'});
    end

    methods
        function obj = ecompass(varargin)
            setProperties(obj,nargin,varargin{:});
        end
    end

    methods (Access = protected)
        function setupImpl(obj)
            % Get reference frame specific math object
            obj.pNavFrame = ...
                fusion.internal.frames.ReferenceFrame.getMathObject( ...
                            obj.ReferenceFrame);
        end

        function validateInputsImpl(~, a, m)
            if isempty(m) && isempty(a)
                % Nothing to validate here
            else
                validateattributes(m, {'double', 'single'}, {'nonempty',...
                    '2d', 'ncols', 3, 'finite', 'nonsparse'}, ...
                    'ecompass', 'MagneticField');

                validateattributes(a, {'double', 'single'}, {'nonempty',...
                    '2d', 'ncols', 3, 'finite', 'nonsparse' }, ...
                    'ecompass', 'Acceleration');
            end
        end

        function orientOut = stepImpl(obj, a, m)

            if isempty(m) && isempty(a)
                if isa(m, 'single') || isa(a, 'single')
                    orient = zeros(3,3,size(m,1), 'single');
                else
                    orient = zeros(3,3, size(m,1), 'double');
                end
            else
                numframes = size(a,1);
                coder.internal.assert(isequal(numframes, size(m,1)), ...
                    'shared_positioning:ecompass:NumSamplesMismatch', ...
                    'Acceleration', 'MagneticField');

                orient = obj.pNavFrame.ecompass(a, m);
            end

            % Unpack the quaternion if necessary
            if strcmpi(obj.OrientationFormat, 'quaternion')
                orientOut = quaternion(orient, 'rotmat', 'frame');
                orientOut = compact(orientOut);
            else
                orientOut = orient;
            end
        end
    end

    % Save and Load
    methods (Access = protected)
        function s = saveObjectImpl(obj)
            % Default implementation saves all public properties
            s = saveObjectImpl@matlab.System(obj);

            if isLocked(obj)
                s.pNavFrame = obj.pNavFrame;
            end
        end

        function s = loadObjectImpl(obj, s, wasLocked)
            % Reload states if saved version was locked 
            if wasLocked 
                obj.pNavFrame = s.pNavFrame;
            end
            loadObjectImpl@matlab.System(obj, s, wasLocked);
        end
    end

    % Simulink block icon
    methods (Access = protected)
        function icon = getIconImpl(~)
            %getIconImpl Define icon for System block
            filepath = fullfile(matlabroot, 'toolbox', 'shared', ...
                        'positioning', 'simulink', 'blockicons', ...
                        'ecompass.svg');
            icon = matlab.system.display.Icon(filepath);
        end
    end

    % Input and Output: name, type, and size
    methods (Access = protected)
        function num = getNumInputsImpl(~)
          num = 2;
        end

        function n = getInputNamesImpl(~)
            n = ["Accel", ...
                 "Mag"];
        end

        function num = getNumOutputsImpl(~)
            num = 1;
        end

        function n = getOutputNamesImpl(~)
            n = "Orientation";
        end
    end

    % Propagators
    methods (Access = protected)
        function s1 = getOutputSizeImpl(obj)
            ps = propagatedInputSize(obj, 1);
            numsamples = ps(1);

            % Orientation
            if strcmpi(obj.OrientationFormat, 'quaternion')
                s1 = [numsamples, 4];
            else
                s1 = [3 3 numsamples];
            end
        end

        function dt = getOutputDataTypeImpl(obj)
           dt1 = propagatedInputDataType(obj,1);
           dt2 = propagatedInputDataType(obj,2);

           if strcmp(dt1, 'single') || strcmp(dt2, 'single')
               dt = 'single';
           else
               dt = 'double';
           end
        end

        function tf1  = isOutputComplexImpl(~)
            tf1 = false;
        end

        function tf1 = isOutputFixedSizeImpl(~)
            tf1 = true;
        end
    end

    methods (Access = protected, Static, Hidden)
        % Property group and description
        function groups = getPropertyGroupsImpl

            ParameterInputSectionName = message( ...
                        'Simulink:studio:ToolBarParametersMenu').getString;

            % Parameters
            refFrame = matlab.system.display.internal.Property( ....
                'ReferenceFrame', ...
                'Description', lookupDesc('ReferenceFrame'));
            orientFormat = matlab.system.display.internal.Property(...
                'OrientationFormat', ...
                'Description', lookupDesc('OrientationFormat'));
            groups = matlab.system.display.Section( ...
                'Title', ParameterInputSectionName, ...
                'PropertyList', {refFrame, orientFormat});
        end

        % Simulink block description
        function header = getHeaderImpl
            heading = string(lookupDesc('ecompassBlockHeader'));
            blockDesc = string(lookupDesc('ecompassBlockDesc'));
            paramsDesc = string(lookupDesc('specifyParamsDesc'));

            % We don't translate block names, so okay to not use message
            % catalog
            header = matlab.system.display.Header(mfilename('class'),...
                'Title', 'ecompass', ...
                'Text', heading + newline + newline + ...
                        blockDesc  + newline + newline + ...
                        paramsDesc, ...
                'ShowSourceLink', false);
        end
    end

    methods (Hidden, Static)
        function flag = isAllowedInSystemBlock
            flag = true;
        end
    end
end

function txt = lookupDesc(desc)
%LOOKUPDESC Find the property description in the message catalog
    m = message("shared_positioning:ecompass:" + desc);
    txt = m.getString;
end