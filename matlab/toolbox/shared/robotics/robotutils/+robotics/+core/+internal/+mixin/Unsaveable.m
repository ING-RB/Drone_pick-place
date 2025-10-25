classdef (Abstract) Unsaveable < handle
    %This class is for internal use only. It may be removed in the future.
    
    %Unsaveable Implements correct behavior for Unsaveable handle objects
    %   Some objects are not designed for being saved to a MAT file and
    %   then reloaded. For example, it might be impossible to reconstruct
    %   the exact state of the object if it was part of a ROS network at
    %   saving time.
    %
    %   The Unsaveable mixin will implement correct saving and loading
    %   behavior for this type of class. It will issue a warning when the
    %   object is saved and ensure that the object handle is deleted when
    %   the object is re-loaded.
    %
    %   To use this mixin, derive your class from Unsaveable and make sure
    %   that your class's delete method is either public or Unsaveable is
    %   part of the access list.
    
    %   Copyright 2014-2020 The MathWorks, Inc.
    
    methods (Access = protected)
        function sObj = saveobj(obj)
            %saveobj Implements saving of object to MAT file
            %   Issues a warning that this object cannot be saved to a MAT
            %   file.
            
            % There is no way to prevent saving altogether
            warning(message('shared_robotics:robotutils:common:SavedObjectInvalid', ...
                class(obj)));
            
            % Save object in structure
            sObj.obj = obj;
        end
    end
    
    methods (Static, Access = protected)
        function obj = loadobj(sObj)
            %loadobj Implement loading from a MAT file
            %   The returned object will be a deleted (invalid) handle.
            
            % The original state of the object cannot be reconstructed, so
            % invalidate the handle.
            obj = sObj.obj;
            
            % Issue a warning to the user, so he can act appropriately
            warning(message('shared_robotics:robotutils:common:LoadedObjectInvalid', ...
                class(obj)));

            % Invalidate the handle
            obj.delete;
        end
    end    
end

