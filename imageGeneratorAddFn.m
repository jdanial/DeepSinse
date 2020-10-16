%% DeepSinse
%% ========================================================================
%% imageGeneratorAddFn
%% Code for generating image of single molecule bursts
%% ========================================================================
%% Copyright 2020 John S H Danial
%% Department of Chemistry, Univerity of Cambridge

function data = imageGeneratorAddFn(roiRadius,numParticles,meanNoise,initialSigma,finalSigma)

%% initializing vectors
factor = 1000;
image = poissrnd(meanNoise * factor,200,200);
xMean = 1 + roiRadius + ((200 - 2 * (roiRadius + 1)) * rand(numParticles,1));
yMean = 1 + roiRadius + ((200 - 2 * (roiRadius + 1)) * rand(numParticles,1));
sigma = initialSigma + (finalSigma * rand(numParticles,1));


%% image generator
for particleId = 1 : numParticles
    for xVal = ceil(xMean(particleId) - roiRadius) : floor(xMean(particleId) + roiRadius)
        for yVal = ceil(yMean(particleId) - roiRadius)  : floor(yMean(particleId) + roiRadius)
            image(yVal,xVal) = max([image(yVal,xVal),...
                factor * double(exp(-((xVal - xMean(particleId)) ^ 2 + (yVal - yMean(particleId)) ^ 2) /...
                (2 * (sigma(particleId)) ^ 2)))]);
        end
    end
end

%% augmenting noise
for rowId = 1 : 200
    for colId = 1 : 200
        image(rowId,colId) = ...
            gamrnd(image(rowId,colId),300);
    end
end
image = image / (max(max(image))) * 10000;

%% image saver
imwrite(uint16(image),['Test_' num2str(meanNoise*100) '.tif']);

%% data saver
data.image = image;
data.mean.x = xMean;
data.mean.y = yMean;
end