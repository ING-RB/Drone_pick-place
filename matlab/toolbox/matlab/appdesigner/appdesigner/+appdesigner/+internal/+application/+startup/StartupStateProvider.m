classdef  StartupStateProvider < handle
	% An interface for objects that want to provide any type of state for
	% App Designer client side

	% Copyright 2018 The MathWorks, Inc.

	methods(Abstract)
		% Required method for StartupStateProvider
		%
		% Must return a struct representing whatever state the provider
		% would like to make available to the client
		%
		% Each provider should put all information under a single struct
		% fieldname to avoid potential conflicts
        %
        % Providers will be passed a struct containing the arguments passed to
        % the appdesigner command, with fields FileName, Tutorial, and URL
		%
		% Ex: How to implement the 'Foo' state provider.  Note that all Foo
		% - related information is under a 'Foo' fieldname to avoid
		% collisions
		%
		% function state = getState(obj, startupArguments)
		%
		%		state = struct;
		%		state.Foo.A = ...
		%		state.Foo.B = ...
		%		state.Foo.C = ...
		%
		% end
		state = getState(obj, startupArguments)
	end
end
