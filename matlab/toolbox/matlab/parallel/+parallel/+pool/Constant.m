%Constant Constant data used by multiple PARFOR loops
%   parallel.pool.Constant allows a constant to be defined where
%   the value can be accessed by multiple PARFOR loops or other parallel
%   language constructs (i.e. SPMD or PARFEVAL) without the need
%   to transfer the data multiple times.
%
%   A parallel.pool.Constant can be constructed from an existing variable
%   in the workspace of the MATLAB client. In this case, the data is
%   transferred to the workers in the parallel pool, and is available to be
%   used by accessing the 'Value' field of the Constant object inside a
%   PARFOR loop (or other parallel language construct).
%
%   A parallel.pool.Constant can also be constructed using a function
%   handle specified at the client. In this case, the function handle
%   is evaluated in each worker of the parallel pool. This mode of
%   operation is useful with handle objects or similar resources
%   such as file handles.
%
%   parallel.pool.Constant methods:
%      Constant - Build a Constant from data or a function handle
%
%   parallel.pool.Constant properties:
%      Value - Access the contents
%
%   See also PARFOR, PARFEVAL.

% Copyright 2015-2024 The MathWorks, Inc.
classdef Constant < handle
    properties (GetAccess = private, SetAccess = immutable)
        %ID Key defined on the client and used by the workers to reference
        % the underlying data
        ID

        % A version number for compatibility.
        SaveVersion = 1;
    end

    properties (GetAccess = private, SetAccess = immutable, Transient)
        %Entry Data that backs Constant, and manages which pools it has
        %been sent to.
        Entry

        % Whether we're the context in which this Constant was first
        % created.
        OriginatingMVM = false;

        % Whether we're created from a composite
        CreatedFromComposite = false;
    end

    properties (Transient, Dependent, SetAccess = private)
        %Value Value of the constant accessible on workers
        %   The Value field contains the data referred to by the
        %   parallel.pool.Constant. The Value cannot be modified after
        %   construction
        Value
    end

    properties (Access = private, Constant)
        % IDs are strings, an invalid ID is the empty string.
        InvalidID = '';
    end

    properties (Transient, Constant, Access = private)
        % Registry to enable this class to act as a Flyweight, with one handle
        % object per UUID. Used during deserialization to recover the
        % same object for a given UUID.
        Registry = matlab.internal.parallel.FlyweightRegistry()

        Displayer = parallel.internal.constant.PoolConstantDisplayer()
    end

    methods
        function obj = Constant(arg, cleanupFcn)
            %Constant Build a parallel.pool.Constant from data or a function handle
            %   C = parallel.pool.Constant(X) copies the value X to each
            %   worker and returns a Constant object C which allows the
            %   value X to be accessed on each worker within a parallel
            %   language construct (i.e. PARFOR, SPMD, or PARFEVAL) using
            %   the field C.Value.
            %
            %   C = parallel.pool.Constant(FH) evaluates function handle FH
            %   on each worker and stores the result in C.Value.
            %
            %   C = parallel.pool.Constant(FH, CLEANUP) evaluates function
            %   handle FH on each worker and stores the result in C.Value.
            %   When C is destroyed, the function handle CLEANUP is
            %   evaluated on each worker with a single argument C.Value.
            %
            %   C = parallel.pool.Constant(COMP) uses the values stored in
            %   Composite COMP and stores them in C.Value on each worker.
            %   It is an error if COMP does not define a value on every
            %   worker.
            %
            %   parallel.pool.Constant(...) must be called in the MATLAB
            %   client.
            %
            %   Examples:
            %   % Create some large data on the client
            %   data = rand(1000);
            %   % Build a Constant - transferring the data only once
            %   c = parallel.pool.Constant(data);
            %   for ii = 1:10
            %      % Run multiple PARFOR loops accessing the data.
            %      parfor jj = 1:10
            %         x(ii,jj) = c.Value(ii,jj);
            %      end
            %   end
            %
            %   % Create a temporary file handle on each worker. By passing
            %   % in @fclose as the second argument, the file is
            %   % automatically closed when 'c' goes out of scope.
            %   c = parallel.pool.Constant(@() fopen(tempname, 'wt'), @fclose);
            %   spmd
            %      disp(fopen(c.Value)); % Display the temporary filename
            %   end
            %   parfor idx = 1:1000
            %      fprintf(c.Value, 'Iteration: %d\n', idx);
            %   end
            %   clear c; % closes the temporary file.
            %
            %   See also PARFOR, PARFEVAL.

            arguments
                arg = []
                cleanupFcn {iMustBeFunctionHandle} = function_handle.empty()
            end

            switch nargin
                case 0
                    % For zero-arg syntax, return a Constant in an invalid
                    % state.
                    obj.ID = parallel.pool.Constant.InvalidID;
                    return;
                case 2
                    % For two-arg syntax, first input must also be a function handle.
                    iMustBeFunctionHandle(arg);
            end

            if isa(arg, 'parallel.internal.constant.ConstantID')
                % Serialized with ID only.
                id = arg.ID;
            elseif isa(arg, 'parallel.internal.constant.SerializedConstant')
                % Serialized with ID and payload.
                [id, arg, cleanupFcn] = arg.unpackInputs();
            else
                % Constructing new Constant.
                id = iGetNextID();
            end

            try
                if isa(arg, 'parallel.internal.constant.ConstantID')
                    try
                        % Try to get Entry from global store.
                        obj.Entry = parallel.pool.Constant.hGetStore().getEntry(id);
                    catch
                        id = parallel.pool.Constant.InvalidID;
                    end
                else
                    % Constructing directly.
                    obj.OriginatingMVM = true;

                    if isa(arg, 'Composite')
                        obj.CreatedFromComposite = true;
                    end

                    obj.Entry = parallel.internal.constant.ConstantEntry(id, arg, cleanupFcn);
                end
            catch E
                throw(E);
            end

            obj.ID = id;

            % Finally, add this object to the FlyweightRegistry with this
            % ID.
            parallel.pool.Constant.Registry.add(obj, id);
        end

        function v = get.Value(obj)
            %get.Value Return the value
            if ~obj.hGetIsValidID()
                error(message('MATLAB:parallel:constant:InvalidConstantValue'));
            else
                try
                    v = obj.Entry.getValue();
                catch E
                    throw(E);
                end
            end
        end

        function delete(obj)
            %DELETE Execute the cleanup function if required
            if obj.hGetIsValidID() && obj.OriginatingMVM
                err = obj.Entry.cleanup();
                if ~isempty(err)
                    warning(message('MATLAB:parallel:constant:ConstantErrorsDuringCleanup', ...
                        err.message));
                end
            end
        end

        function disp(obj)
            %DISP Display the value of the Constant
            if any([obj.CreatedFromComposite])
                disp(string(message('MATLAB:parallel:constant:ConstantCompositeValueOnClient')))
            else
                parallel.pool.Constant.Displayer.doDisp(obj);
            end
        end
    end
    methods (Hidden, Static)
        function obj = loadobj(s)
            %LOADOBJ
            % Note, 's' could represent a struct with a single field (ID)
            % or a struct containing the original constructor arguments.

            % Check first if object with this ID already exists.
            obj = parallel.pool.Constant.Registry.getIfExists(s.ID);
            if ~isempty(obj)
                return
            end

            % Object doesn't already exist, so need to call our constructor.
            if isfield(s, 'ConstructorArgs')
                s = parallel.internal.constant.SerializedConstant(s.ID, s.ConstructorArgs{:});
            else
                s = parallel.internal.constant.ConstantID(s.ID);
            end
            obj = parallel.pool.Constant(s);
        end
    end
    methods (Hidden)
        function s = saveobj(obj)
            %SAVEOBJ - returns either a struct with a single field (ID), or
            % additionally includes the original constructor arguments to
            % allow reconstruction.
            if ~obj.hGetIsValidID() || obj.CreatedFromComposite
                % Serialize the ID only.
                s = struct('ID', obj.ID);
            else
                % Get the pool serialization context. If none exists, this
                % will return empty.
                sessionId = parallel.internal.pool.serializationContext();

                if ~isempty(sessionId)
                    % Transfer underlying data to workers if required.
                    obj.Entry.broadcast(sessionId);

                    % Serialize only the ID.
                    s = struct('ID', obj.ID);
                else
                    % No pool serialization context exists, so serialize
                    % the entire entry representing the Constant, with
                    % enough information to allow reconstruction.
                    s = struct('ID', obj.ID, ...
                        'SaveVersion', obj.SaveVersion, ...
                        'ConstructorArgs', {obj.Entry.getConstructorArgs()});
                end
            end
            parallel.internal.general.SerializationNotifier.notifySerialized(...
                class(obj));
        end

        % Functions to ensure that the following code doesn't behave
        % strangely.
        % c = parallel.pool.Constant(7)
        % spmd, if false, c.Value = 8; end, end
        % In that case, the SPMD static analysis machinery thinks that you
        % "might" be assigning to part of 'c', and therefore even though
        % the assignment line is never hit, it converts 'c' to Composite,
        % c.f.
        % x = 1; spmd, if false, x.y = 2; end, end, assert(isa(x, 'Composite'))

        function [fcn, userData] = getRemoteFromSPMD(obj)
            % This method allows us to override what happens to variables
            % inside an SPMD block being assigned outside the block. We
            % override this behavior for the case:
            %   c = parallel.pool.Constant(..);
            %   spmd; if false; c.Value.foo = blah; end; end
            % This assignment causes SPMD to build a composite ordinarily.
            % To avoid this issue, we force the returned variable to be a
            % constant in this one case.
            if isscalar(obj)
                % Defer construction of the output to a function on the
                % client that can decide whether the relevant constant
                % existed prior to the SPMD block.
                fcn = @iBuildFromSPMD;
                userData = obj.ID;
            else
                % This special behavior is disabled for an array of
                % constant.
                fcn = @spmdlang.plainCompositeBuilder;
                userData = [];
            end
        end
        function obj = init(obj, varargin)
            % This method is required to exist by the SPMD infrastructure,
            % it provides us an opportunity to deal with data held by the
            % Composite resource management.

            % If we don't actually build a composite, we will leak
            % parallel.pool.Constant objects copied into the Composite
            % resource management on workers. To reach this situation, the
            % constant existed before the SPMD block, so we already have
            % the relevant references registered. We don't need further
            % copies of the constant existing in alternate systems.
            comp = spmdlang.plainCompositeBuilder();
            comp = init(comp, varargin{:}); %#ok<NASGU>
        end
        function [poolConstantPropertyDictionary, propNames] =  hGetDisplayItems(obj, diFactory)
            % Create a dictionary to hold displayable pool Constant
            % properties
            propNames = {'Value'};
            poolConstantPropertyDictionary = dictionary(propNames{1}, diFactory.createDefaultItem(obj.Value));
        end
        function tf = hGetIsValidID(obj)
            tf = ~isequal(obj.ID, parallel.pool.Constant.InvalidID);
        end
    end
    methods (Hidden, Static)
        function [ids, values] = getAll()
            % For test purposes only
            [ids, values] = parallel.pool.Constant.hGetStore().getAll();
        end

        function store = hGetStore()
            % Get the ConstantStore that backs this Constant.
            store = parallel.internal.constant.ConstantStore.getInstance();
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Allocate and return a new key.
function id = iGetNextID()
% Use TEMPNAME to generate the ID so it will be unique across processes and
% invocations.
id = tempname('.');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Deal with constants being returned from SPMD. This is invoked on the
% client.
function out = iBuildFromSPMD(ids)
% If all workers share the same constant ID and that constant ID is valid
% on the client, then this constant existed before the SPMD
% block. We force the SPMD framework to return an equivalent constant
% object to the one prior to SPMD block. This function is evaluated on
% the client with ids provided by getRemoteFromSPMD.
ids = unique(ids);
if isscalar(ids)
    id = ids{1};
    out = parallel.pool.Constant.Registry.getIfExists(id);
    if ~isempty(out)
        assert(isa(out, "parallel.pool.Constant"));
        return
    end
end
% Otherwise the constant was constructed on workers, we allow the SPMD
% rules to take precedence, and that variables assigned within SPMD become
% composites.
out = spmdlang.plainCompositeBuilder;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Use this validation function for consistent error for two-arg syntax.
function iMustBeFunctionHandle(fcn)
if ~isa(fcn,"function_handle")
    throwAsCaller(MException(message('MATLAB:parallel:constant:ConstantTwoFunctions')));
end
end

