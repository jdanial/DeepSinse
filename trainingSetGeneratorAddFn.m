%% DeepSinse
%% ========================================================================
%% trainingSetGeneratorAddFn 
%% Code for generating ground-truth regions of interest of single molecules
%% and noise.
%% ========================================================================
%% Copyright 2020 John S H Danial
%% Department of Chemistry, Univerity of Cambridge

function [imageVec,classVec] = trainingSetGeneratorAddFn(roiRadius,numParticles,numParticlesPerImage,meanNoise,initialSigma,finalSigma)

%% initializing vectors
factor = 1000;
classVec = round(rand(numParticles,1));
imageVec = zeros((2 * roiRadius) + 1,(2 * roiRadius) + 1,1,numParticles);

%% generating images
globalParticleId = 1;
for imageId = 1 : numParticles / numParticlesPerImage

    %% generating a random factor
    randFactor = 0.1 + (meanNoise - 0.1) * rand;
    
    %% initializing parameters
    particleImage = poissrnd(randFactor * factor,200,200);
    xMean = 1 + roiRadius + ((200 - 2 * (roiRadius + 1)) * rand(numParticlesPerImage,1));
    yMean = 1 + roiRadius + ((200 - 2 * (roiRadius + 1)) * rand(numParticlesPerImage,1));
    sigma = initialSigma + (finalSigma * rand(numParticlesPerImage,1));
    
    %% particle image generator
    for particleId = 1 : numParticlesPerImage
        for xVal = ceil(xMean(particleId) - roiRadius) : floor(xMean(particleId) + roiRadius)
            for yVal = ceil(yMean(particleId) - roiRadius)  : floor(yMean(particleId) + roiRadius)
                particleImage(yVal,xVal) = max([particleImage(yVal,xVal),...
                    factor * double(exp(-((xVal - xMean(particleId)) ^ 2 + (yVal - yMean(particleId)) ^ 2) /...
                    (2 * (sigma(particleId)) ^ 2)))]);
            end
        end
    end
    
    %% augmenting noise
    particleImage = gamrnd(particleImage,300);
    
    %% thresholding image
    thresholdNoiseImage = imregionalmax(particleImage,8);
    
    %% extracting connected objects from threshold image
    [centroidTemp_y,centroidTemp_x] = ind2sub(size(thresholdNoiseImage),find(thresholdNoiseImage == true));
    centroids = [centroidTemp_x centroidTemp_y];
    
    %% looping through noise particles
    xMeanNoise = [];
    yMeanNoise = [];
    while length(xMeanNoise) < numParticlesPerImage
        particleId = floor(1 + (size(centroids,1) - 1) * rand);
        if round(centroids(particleId,2)) - roiRadius > 1 && ...
                round(centroids(particleId,2)) + roiRadius < size(particleImage,1) && ...
                round(centroids(particleId,1)) - roiRadius > 1 && ...
                round(centroids(particleId,1)) + roiRadius < size(particleImage,2)
            if sum(abs(centroids(particleId,1) - xMean) < 2) == 0 && ...
                    sum(abs(centroids(particleId,2) - yMean) < 2) == 0
                xMeanNoise = [xMeanNoise centroids(particleId,2)];
                yMeanNoise = [yMeanNoise centroids(particleId,1)];
            end
        end
    end
    
    %% filling and normalizing imageVec
    for particleId = 1 : numParticlesPerImage
        if classVec(globalParticleId) == 1
            imageVec(:,:,:,globalParticleId) = particleImage(round(yMean(particleId) - roiRadius) : round(yMean(particleId) + roiRadius),...
                round(xMean(particleId) - roiRadius) : round(xMean(particleId) + roiRadius));
        else
            imageVec(:,:,:,globalParticleId) = particleImage(round(yMeanNoise(particleId) - roiRadius) : round(yMeanNoise(particleId) + roiRadius),...
                round(xMeanNoise(particleId) - roiRadius) : round(xMeanNoise(particleId) + roiRadius));
        end
        imageVec(:,:,:,globalParticleId) = (imageVec(:,:,:,globalParticleId) - min(min(imageVec(:,:,:,globalParticleId)))) / ...
            (max(max(imageVec(:,:,:,globalParticleId))) - min(min(imageVec(:,:,:,globalParticleId))));
        globalParticleId = globalParticleId + 1;
    end
end
end