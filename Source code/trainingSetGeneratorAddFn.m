%% DeepSinse
%% ========================================================================
%% trainingSetGeneratorAddFn 
%% Code for generating ground-truth regions of interest of single molecules
%% and noise.
%% ========================================================================
%% Copyright 2020 John S H Danial
%% Department of Chemistry, Univerity of Cambridge

function [imageVec,classVec] = trainingSetGeneratorAddFn(roiRadius,numParticles,numParticlesPerImage,lowTestphotonCount,highTestphotonCount,initialSigma,finalSigma,cameraParam)

%% initializing vectors
classVec = round(rand(numParticles,1));
imageVec = zeros((2 * roiRadius) + 1,(2 * roiRadius) + 1,1,numParticles);

%% generating images
globalParticleId = 1;
for imageId = 1 : numParticles / numParticlesPerImage

    %% initializing parameters
    burstPhotonImage = zeros(200,200);
    noisePhotonImage = zeros(200,200);
    xMean = 1 + roiRadius + ((200 - 2 * (roiRadius + 1)) * rand(numParticlesPerImage,1));
    yMean = 1 + roiRadius + ((200 - 2 * (roiRadius + 1)) * rand(numParticlesPerImage,1));
    sigma = initialSigma + (finalSigma - initialSigma) * rand(numParticlesPerImage,1);
    
    %% particle image generator
    randPhotonCount = lowTestphotonCount + (highTestphotonCount - lowTestphotonCount) * rand;
    for particleId = 1 : numParticlesPerImage
        for xVal = ceil(xMean(particleId) - roiRadius) : floor(xMean(particleId) + roiRadius)
            for yVal = ceil(yMean(particleId) - roiRadius)  : floor(yMean(particleId) + roiRadius)
                burstPhotonImage(yVal,xVal) = burstPhotonImage(yVal,xVal) +...
                    randPhotonCount * double(exp(-((xVal - xMean(particleId)) ^ 2 + (yVal - yMean(particleId)) ^ 2) /...
                    (2 * (sigma(particleId)) ^ 2)));
            end
        end
    end
    
    %% converting photons to electrons
    burstElectronImage = (burstPhotonImage .* (cameraParam.efficiency / 100)) + cameraParam.darkCurrent + cameraParam.readoutNoise;
    burstParticleImage = (gamrnd(burstElectronImage,(cameraParam.gain - 1 + (1 ./ burstElectronImage))) ./ cameraParam.conversionFactor) + cameraParam.offset;
    noiseElectronImage = (noisePhotonImage .* (cameraParam.efficiency / 100)) + cameraParam.darkCurrent + cameraParam.readoutNoise;
    noiseParticleImage = (gamrnd(noiseElectronImage,(cameraParam.gain - 1 + (1 ./ noiseElectronImage))) ./ cameraParam.conversionFactor) + cameraParam.offset;    
    
    %% filling and normalizing imageVec
    for particleId = 1 : numParticlesPerImage
        if classVec(globalParticleId) == 1
            imageVec(:,:,:,globalParticleId) = burstParticleImage(round(yMean(particleId) - roiRadius) : round(yMean(particleId) + roiRadius),...
                round(xMean(particleId) - roiRadius) : round(xMean(particleId) + roiRadius));
        else
            imageVec(:,:,:,globalParticleId) = noiseParticleImage(round(yMean(particleId) - roiRadius) : round(yMean(particleId) + roiRadius),...
                round(xMean(particleId) - roiRadius) : round(xMean(particleId) + roiRadius));
        end
        imageVec(:,:,:,globalParticleId) = (imageVec(:,:,:,globalParticleId) - min(min(imageVec(:,:,:,globalParticleId)))) / ...
            (max(max(imageVec(:,:,:,globalParticleId))) - min(min(imageVec(:,:,:,globalParticleId))));
        globalParticleId = globalParticleId + 1;
    end
end
end