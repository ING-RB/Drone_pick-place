%ABSTRACTCONSTANTSTORE Interface for ConstantStore, which backs
% parallel.pool.Constant.

% Copyright 2022 The MathWorks, Inc.

classdef AbstractConstantStore < handle
  
    methods (Abstract)

        % Check if the supplied ID is a key for this ConstantStore.
        tf = isKey(obj, ID)

        % Store a value.
        storeValue(obj, value)

        % Store a function handle (without immediate evaluation) and
        % optional cleanup function handle.
        storeFcn(obj, fcn, cleanupFcn)

        % Store a Composite.
        storeComposite(obj, comp)

        % Add a reference to an existing entry in the ConstantStore. 
        %
        % Throws if ID does not already exist.
        addReference(obj, ID)

        % Get the value for a given ID. For function based entries, this
        % will trigger evaluation.
        %
        % Throws if ID does not already exist.
        % Throws any error caught on evaluation.
        value = get(obj, ID)

        % Remove and cleanup an entry in the store with corresponding ID.
        %
        % Returns an MException of captured errors.
        error = cleanup(obj, ID)   
    end

    methods (Abstract, Hidden, Static)
        % For test purposes only.
        [ids, values] = getAll();
    end
end