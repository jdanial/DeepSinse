%% DeepSinse
%% ========================================================================
%% main
%% Entry point for DeepSinse.
%% ========================================================================
%% Editable paramaters: 
%% gener                true / false     to generate dataset
%% train                true / false     to train neural network
%% test                 true / false     to test on unseen ground-truth data.
%% roiRadius            integer > 0      radius of the regions of interest.
%% noiseLevel           0 to 1           normalized lamda factor of poisson distribution
%% numParticles         integer > 0      number of particles to generate
%% numTrainParticles    integer > 0      number of particles to use for training
%% numValidParticles    integer > 0      number of particles to use for validation
%% uppTestnoiseLevel    0 to 1           upper bound of noise level for testing
%% lowTestnoiseLevel    0 to 1           lower bound of noise level for testing
%% numParticlesPerImage integer > 0      number of particles to simulate per field of view (image)
%% initialSigma         numeric > 0      standard deviation of the smallest bursts
%% finalSigma           numeric > 0      standard deviation of the largest bursts
%% ========================================================================
%% Dependencies:
%% trainingSetGeneratorAddFn
%% networkTrainerAddFn
%% networkValidatorAddFn
%% imageGeneratorAddFn
%% imageAnnotatorAddFn
%% ========================================================================
%% Copyright 2020 John S H Danial
%% Department of Chemistry, Univerity of Cambridge

%% clear all
clear all;

%% user inputs
roiRadius = 3;
noiseLevel = 0.6;
numParticles = 100000;
numTrainParticles = 10000;
numValidParticles = 10000;
lowTestnoiseLevel = 0.1;
uppTestnoiseLevel = 0.8;
numParticlesPerImage = 100;
initialSigma = 1;
finalSigma = 1;

%% workflow
gener = false;
train = false;
test = true;

%% initializing structs
imageVec = struct();
classVec = struct();

if gener
    
    %% training network
    [imageVecTmp,classVecTmp] =...
        trainingSetGeneratorAddFn(roiRadius,numParticles,numParticlesPerImage,noiseLevel,initialSigma,finalSigma);
    imageVec.noise(1).array = imageVecTmp;
    classVec.noise(1).array = classVecTmp;
    
    %% saving generated data
    save(['imageVec_' num2str(roiRadius)],'imageVec');
    save(['classVec_' num2str(roiRadius)],'classVec');
end

if train
    
    %% loading generated data
    load(['imageVec_' num2str(roiRadius)]);
    load(['classVec_' num2str(roiRadius)]);
    
    %% validating network
    imageVecTmp = imageVec.noise(1).array;
    classVecTmp = classVec.noise(1).array;
    neuralNet = networkTrainerAddFn(roiRadius,imageVecTmp(:,:,1,1:numTrainParticles),classVecTmp(1:numTrainParticles,1));
    [accuracy,FPR] =...
        networkValidatorAddFn(neuralNet,...
        imageVecTmp(:,:,1,numParticles - numValidParticles + 1:numParticles),...
        classVecTmp(numParticles - numValidParticles + 1:numParticles,1));
end

if test
    
    noiseLevelVec = lowTestnoiseLevel:0.1:uppTestnoiseLevel;
    
    %% generating images
    for noiseId = 1 : length(noiseLevelVec)
        data.noise(noiseId).array = imageGeneratorAddFn(roiRadius,numParticlesPerImage,noiseLevelVec(noiseId),initialSigma,finalSigma);
    end
    
    %% annotating images
    for noiseId = 1 : length(noiseLevelVec)
        [accuracy(noiseId),FPR(noiseId)] = imageAnnotatorAddFn(data.noise(noiseId).array,roiRadius,noiseLevelVec(noiseId));
    end
end