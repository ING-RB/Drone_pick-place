classdef Utilities
%UTILITIES Utility class of static methods for shared positioning

%   Copyright 2023 The MathWorks, Inc.    

    %#codegen

    methods (Static)
        function validateQuatOrRotmat(orient, fname, argname, inputnum)
            %VALIDATEQUATORROTMAT Ensure the input is an array of quaternions or rotation matrices
            
            if isa(orient, "quaternion")
                validateattributes(orient, 'quaternion', {'column', 'finite', 'nonnan'}, fname, argname, inputnum);
            elseif isa(orient, "numeric")
                % rotation matrix. 3-by-3 or 3-by-3-by=N
                validateattributes(orient, {'double', 'single'}, {'3d', 'ncols', 3, 'nrows', 3, 'finite', 'nonnan'}, fname, argname, inputnum);
            else
                coder.internal.error('shared_positioning:utilities:RotmatOrQuat', fname, inputnum);
            end
        end

        function q = convertToQuat(orient)
            % CONVERTTOQUAT convert an orientation to a quaternion
            %   The input orient can be a quaternion or rotation matrix.
            %   The output is a quaternion.
            %
            %   No validation of input.

            if isa(orient, "quaternion")
                q = orient;
            else
                % Rotation matrix
                q = quaternion(orient, 'rotmat', 'frame');
            end
        end

        function q = convertToRotmat(orient)
            % CONVERTTOROTMAT convert an orientation to a rotation matrix
            %   The input orient can be a quaternion or rotation matrix.
            %   The output is a (frame) rotation matrix
            %
            %   No validation of input.

            if isa(orient, "quaternion")
                q = rotmat(orient, "frame");
            else
                q = orient;
            end
        end

    end

end
