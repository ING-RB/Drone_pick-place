classdef Dependency < matlab.mixin.CustomElementSerialization
    properties
        Name (1,1) string {mustBeNonmissing}
        VersionRange (1,1) string {mustBeNonmissing, mustBeValidVersionRange}
        ID (1,1) string {mustBeNonmissing}
    end
    properties(SetAccess=?matlab.mpm.Package, Transient)
        ResolvedVersion
    end

    methods
        function obj = Dependency(Name, VersionRange, ID)
            arguments
                Name (1,1) string {mustBeNonmissing}
                VersionRange (1,1) string {mustBeNonmissing, mustBeValidVersionRange}
                ID (1,1) string {mustBeNonmissing, mustBeValidUUID}
            end
            obj.Name = Name;
            obj.VersionRange = VersionRange;
            obj.ID = ID;
            obj.ResolvedVersion = matlab.mpm.Version(missing);
        end

        function obj = set.ID(obj, ID)
            arguments
                obj (1,1) matlab.mpm.Dependency
                ID (1,1) string {mustBeNonmissing, mustBeValidUUID}
            end
            obj.ID = ID;
        end

        function ret = isequal(dep, otherDep)
            if ~isequal(size(dep), size(otherDep))
                ret = false;
                return;
            end

            depClass = 'matlab.mpm.Dependency';
            depType = whos('dep').class;
            if strcmp(depType, depClass) ~= 1
                ret = false;
                return;
            end
            otherDepType = whos('otherDep').class;
            if strcmp(otherDepType, depClass) ~= 1
                ret = false;
                return;
            end

            if isscalar(dep) && isscalar(otherDep)
                ret = compareScalar(dep, otherDep);
            else
                isEq = false(size(dep));
                for i=1:numel(dep)
                    isEq(i) = isequal(dep(i),otherDep(i));
                end
                ret = all(isEq);
            end
        end
    end

    methods(Static)
        function obj = finalizeIncomingObject(obj)
            obj.ResolvedVersion = matlab.mpm.Version(missing);
        end
    end
end

function r = compareScalar(dep, otherDep)
    r = dep.ID == otherDep.ID && ...
        dep.VersionRange == otherDep.VersionRange;
end

function mustBeValidVersionRange(versionRange)
    matlab.mpm.internal.parseVersionRange(versionRange);
end

function mustBeValidUUID(uuid)
    matlab.mpm.internal.parseUUID(uuid);
end

%   Copyright 2024 The MathWorks, Inc.
