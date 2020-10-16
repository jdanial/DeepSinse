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
roiRadius = 4;

%% get folder containing images
[fileName,fPath] = uigetfile('*.tif','MultiSelect','on');

%% looping across files
for fileId = 1 : numel(fileName)
    
    if numel(fileName) == 1
        fName = fileName(fileId);
    else
        fName = fileName{fileId};
    end
    
    %% reading image
    imageT = Tiff(fullfile(fPath,fName));
    imageRaw = read(imageT);
    
    %% annotating images
    try
        imageAnnotatorTestAddFn(imageRaw,roiRadius,fPath,fName);
    catch
    end
end