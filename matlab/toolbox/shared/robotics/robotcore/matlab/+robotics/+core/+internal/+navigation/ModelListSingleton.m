classdef ModelListSingleton < handle
    %This class is for internal use only. It may be removed in the future.
    
    %ModelListSingleton singleton wrapper for model list.
    %
    %   During interpreted mode, it is assumed that the model definition
    %   xml is constant as it is only used internally.
    %
    %   During code generation, the list would be created in each
    %   getInstance call. Since the whole factory would be constant folded
    %   during code generation, this call doesn't affect generated code.
    %
    %   When user is allowed to create their customized model, it would be
    %   necessary to perform MD5 checks and recreate the model list when
    %   necessary. Or user would need to reinitialize the singleton
    %   instance explicity after changing the model file (for example:
    %   clear classes)
    %
    %   During MATLAB execution, the list would only be created once
    %   until changes are made to the model defintion xml.
    
    
    %   Copyright 2018-2024 The MathWorks, Inc.
    
    %#codegen
    
    methods (Static)
        function out = getInstance()
            %getInstance returns an instance of model list to be used by ModelFactory
            
            persistent instance;
            
            if coder.target('MATLAB')
                % Currently, instance is only populated once within the
                % singleton.
                if isempty(instance)
                    instance = robotics.core.internal.navigation.ModelList;
                end
                out = instance;
                
                
                % TODO: add MD5 checksum verification
                %
                % Instead of populating instance only once, recreate it if XML
                % md5 changes
                %
                % Potential workflow:
                %
                %    persistent instanceCheckSum;
                %    filePath = fullfile(...
                %         fileparts(mfilename('fullpath')), ...
                %         robotics.core.internal.navigation.ModelFactory.ModelDefinitionXML);
                %
                %     currentCheckSum = Simulink.getFileChecksum(filePath);
                %
                %     if isempty(instance) || ~strcmp(instanceCheckSum, currentCheckSum)
                %         instance = robotics.core.internal.navigation.ModelFactory;
                %         instanceCheckSum = currentCheckSum;
                %     end
                %     out = instance;
                
            else
                % During code generation, the model list is recreated in
                % each call. This is due to code generation limitation that
                % requires the out to be compile time constant.
                out = robotics.core.internal.navigation.ModelList;
            end
            
        end
    end
    
end
