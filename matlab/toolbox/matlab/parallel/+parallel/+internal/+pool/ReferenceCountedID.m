%  Any class that wishes to use distributed reference counting must
%  hold a ReferenceCountedID as a member. All objects with the same ID
%  will be counted. The count includes objects on remote workers, and
%  objects in transit to remote workers. When the count reaches 0 
%  (i.e. all objects have been destroyed globally), the provided
%  callback will eventually be called.

% Copyright 2024 The MathWorks, Inc.

classdef ReferenceCountedID < handle

    properties
        ID
    end

    properties(Constant, Access=private)
        InvalidID = "";
    end

    methods
        function obj = ReferenceCountedID(id, callback)
            arguments
                id (1,1) string;
                callback (1,1) function_handle = @()[];
            end

            obj.ID = id;

            if obj.isValid()

                if nargin > 1
                    parallel.internal.referencecounter.addReferenceDestroyedCallback(obj.ID, callback);
                end

                parallel.internal.referencecounter.referenceCreated(obj.ID);
            end
        end

        function v = isValid(obj)
            v = obj.ID ~= obj.InvalidID;
        end

        function sobj = saveobj(obj)
            if obj.isValid
                contextSet = parallel.internal.referencecounter.referenceSerialized(obj.ID);

                if contextSet
                    sobj.ID = obj.ID;
                else
                    sobj.ID = obj.InvalidID;
                end
            else
                sobj.ID = obj.InvalidID;
            end
        end

        function delete(obj)
            if ~isempty(obj.ID)
                parallel.internal.referencecounter.referenceDeleted(obj.ID);
            end
        end
    end

    methods(Static)
        function obj = loadobj(sobj)
            if isstruct(sobj)
                obj = parallel.internal.pool.ReferenceCountedID(sobj.ID);
            else
                obj = sobj;
                parallel.internal.referencecounter.referenceCreated(obj.ID);
            end
        end
    end
end