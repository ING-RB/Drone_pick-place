classdef VHACDHelpers < robotics.core.internal.InternalAccess
% This class is for internal use only and may be removed in a future release

%VHACDHelpers Helper utilities for fields requiring internal access

%   Copyright 2023 The MathWorks, Inc.

    methods (Static)
        function optionsStruct = readStructFromVHACDOptions(optionsObject)
        %readStructFromVHACDOptions Return the options struct from a vhacdOptions object

            optionsStruct = optionsObject.OptionsStructInternal;
        end

        function [optionsStructArray, sourceMesh] = readRBTStructArrayFromVHACDOptions(optionsObject, numLinks)
        %readRBTStructArrayFromVHACDOptions Return the options struct from a vhacdOptions object

            optionsStruct = optionsObject.OptionsStructInternal;

            % At present, the source mesh can only be a scalar string
            sourceMesh = optionsObject.SourceMesh;

            maxDim = optionsObject.MaxLength;
            if maxDim > 1 && maxDim ~= numLinks
                robotics.core.internal.error('vhacd:OptionsRobotLinksMismatchError', numLinks);
            end

            % Convert to a struct array corresponding to the number of
            % links
            optionsStructArray = repmat(robotics.core.internal.defaultVHACDOpts, [1 numLinks]);
            for i = 1:numLinks
                optionsStructArray(i).VoxelResolution = optionsStruct.VoxelResolution(min(i, numel(optionsStruct.VoxelResolution)));
                optionsStructArray(i).ShrinkWrap = optionsStruct.ShrinkWrap(min(i, numel(optionsStruct.ShrinkWrap)));
                optionsStructArray(i).MaxConvHulls = optionsStruct.MaxConvHulls(min(i, numel(optionsStruct.MaxConvHulls)));
                optionsStructArray(i).MinErrPercent = optionsStruct.MinErrPercent(min(i, numel(optionsStruct.MinErrPercent)));
                optionsStructArray(i).MaxNumVertsPerCH = optionsStruct.MaxNumVertsPerCH(min(i, numel(optionsStruct.MaxNumVertsPerCH)));
                optionsStructArray(i).FillMode = optionsStruct.FillMode(min(i, numel(optionsStruct.FillMode)));
            end
        end
    end

end
