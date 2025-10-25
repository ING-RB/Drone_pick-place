function doBroadcast(pool, id, constantEntry)
%DOBROADCAST Broadcast a constantEntry with a given ID to all workers in a
%pool.
%
% pool - a non-empty parallel pool.
% id - a string ID to identify this Constant.
% constantEntry - a ConstantEntry representing the underlying data.

% Copyright 2022-2024 The MathWorks, Inc.

assert(~isempty(pool), "Attempted to broadcast Constant to empty pool.");

assistant = pool.hGetEngine().getConstantAssistant();
assistant.broadcastConstant(pool, id, constantEntry);
    
end
