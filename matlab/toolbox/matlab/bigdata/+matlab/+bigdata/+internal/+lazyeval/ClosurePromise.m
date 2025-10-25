%ClosurePromise
% A class that represents the promise end of a ClosureFuture.
%
% Properties:
%                      Id: A unique ID.
%                   IdStr: Unique ID between closure, promise and future.
%                 Closure: The underlying closure that will fulfill this
%                          promise.
%             ArgoutIndex: The index into the output of the underlying
%                          closure that this promise represents.
%                  IsDone: A flag that is true if and only if the value
%                          this promise represents has been calculated.
%  IsPartitionIndependent: Logical flag that specifies if the result is
%                          independent of the partitioning of the input. If
%                          false, the result becomes transient, it will not
%                          be saved to disk. This is to protect against
%                          Value becoming incorrect if a tall array is
%                          saved and loaded into a different environment.
%                  Future: A reference to the Future object corresponding
%                          to this promise.
%
% Methods:
%  obj = ClosurePromise(value) creates a promise that has already been
%  fulfilled with the given value.
%
%  setValue(obj, value) sets the result of this promise. This completes the
%  promise and if partition independent, clears the closure.
%
%  setPartitionIndependent(obj, flag) set the IsPartitionIndependent flag.
%
%  swap(promise1, promise2) swap two ClosurePromise instances. The caller
%  must guarantee these two promises are equivalent, that the two promises
%  will be given the same output when their respective closures are
%  evaluated. This exists to allow optimizers to move output promises from
%  one Closure instance to another. It is a swap instead a pure move
%  because both Closure and ClosurePromise instances are not allowed
%  to be in an invalid state.
%

% Copyright 2015-2022 The MathWorks, Inc.
