classdef categoricalAccessor
% CATEGORICALACCESSOR An internal class to provide ACL'd access to some of
% categorical's internals without using hidden public methods, and to provide
% more performant construction than the public ctor. This class will become
% unnecessary when functions are allowed in a class method's ACL.

    % Copyright 2023 The MathWorks, Inc.

    methods(Static)
        function [codes,categoryNames] = codesAndCats(catObj)
            [codes,categoryNames] = codesAndCats(catObj);
        end

        function newCatObj = fastCtor(catObj,codes)
            newCatObj = fastCtor(catObj,codes);
        end
    end
end