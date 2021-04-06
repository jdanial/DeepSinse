%% DeepSinse
%% ========================================================================
%% test
%% Code for testing trained network on acquired images
%% ========================================================================
%% Dependencies:
%% imageAnnotatorTestAddFn
%% ========================================================================
%% Copyright 2020 John S H Danial
%% Department of Chemistry, Univerity of Cambridge

clear all;

%% setting roiradius
roiRadius = 5;

%% get folder containing images
[fileName,fPath] = uigetfile('*.tif','MultiSelect','on');

%% looping across files
for fileId = 1 : numel(fileName)
    fileId
    if numel(fileName) == 1
        fName = fileName(fileId);
    else
        fName = fileName{fileId};
    end
    
    %% annotating images
    if fileId == 1
        [fpr(fileId),fnr(fileId),meanSNR(fileId),refMean] = imageAnnotatorDeployAddFn(roiRadius,fPath,fName,true,[]);
    else
        [fpr(fileId),fnr(fileId),meanSNR(fileId),refMean] = imageAnnotatorDeployAddFn(roiRadius,fPath,fName,false,refMean);
    end
end