classdef SchemaDatastore < matlab.io.Datastore ...
        & matlab.io.datastore.internal.ComposedDatastore
%matlab.io.datastore.internal.SchemaDatastore   Overrides the result of
%   empty readall() and preview() with a Schema property.
%
%   SCHDS = matlab.io.datastore.internal.SchemaDatastore(DS, SCHEMA)
%       returns a new datastore SCHDS that returns the value of SCHEMA whenever
%       calling readall() or preview() whenever the datastore is empty.
%
%       In order to verify whether DS is empty, a copy() is made, reset(), and
%       then hasdata() is checked.
%
%   matlab.io.datastore.internal.SchemaDatastore Properties:
%
%     UnderlyingDatastore - The underlying datastore.
%     Schema              - Value that is returned from readall/preview when
%                           the underlying datastore is empty.
%
%   See also: arrayDatastore, matlab.io.datastore.internal.ComposedDatastore

%   Copyright 2022 The MathWorks, Inc.

    properties (Access = protected)
        UnderlyingDatastore = arrayDatastore([]);
    end

    properties (SetAccess = protected)
        Schema
    end

    properties (Access = private, Constant)
        % Save-load metadata.
        % ClassVersion = 1 corresponds to the first release of SchemaDatastore in R2022b.
        ClassVersion(1, 1) double = 1;
    end

    methods
        function schds = SchemaDatastore(UnderlyingDatastore, Schema)
            arguments
                UnderlyingDatastore (1, 1) {matlab.io.datastore.internal.validators.mustBeDatastore}
                Schema
            end

            % Copy and reset the input datastore on construction.
            schds.UnderlyingDatastore = UnderlyingDatastore.copy();
            schds.UnderlyingDatastore.reset();

            % ishandle(x) only works for graphics handles. Use isa(x, "handle") instead.
            assert(~isa(Schema, "handle"), "TODO: support handle objects as schema by overriding copyElement.");

            schds.Schema = Schema;
        end
    end

    methods (Hidden)
        S = saveobj(schds);
    end

    methods (Hidden, Static)
        schds = loadobj(S);
    end
end
