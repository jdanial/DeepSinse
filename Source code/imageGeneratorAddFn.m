%% DeepSinse
%% ========================================================================
%% imageGeneratorAddFn
%% Code for generating image of single molecule bursts
%% ========================================================================
%% Copyright 2020 John S H Danial
%% Department of Chemistry, Univerity of Cambridge

function data = imageGeneratorAddFn(roiRadius,numParticles,photonCount,initialSigma,finalSigma,cameraParam)

%% initializing vectors
photonImage = zeros(200,200);
xMean = 1 + roiRadius + ((200 - 2 * (roiRadius + 1)) * rand(numParticles,1));
yMean = 1 + roiRadius + ((200 - 2 * (roiRadius + 1)) * rand(numParticles,1));
sigma = initialSigma + (finalSigma - initialSigma) * rand(numParticles,1);

%% image generator
for particleId = 1 : numParticles
    for xVal = ceil(xMean(particleId) - roiRadius) : floor(xMean(particleId) + roiRadius)
        for yVal = ceil(yMean(particleId) - roiRadius)  : floor(yMean(particleId) + roiRadius)
                photonImage(yVal,xVal) = photonImage(yVal,xVal) +...
                    photonCount * double(exp(-((xVal - xMean(particleId)) ^ 2 + (yVal - yMean(particleId)) ^ 2) /...
                    (2 * (sigma(particleId)) ^ 2)));
        end
    end
end

%% converting photons to electrons
electronImage = (photonImage .* (cameraParam.efficiency / 100)) + cameraParam.darkCurrent + cameraParam.readoutNoise;
electronImage = (gamrnd(electronImage,(cameraParam.gain - 1 + (1 ./ electronImage))) ./ cameraParam.conversionFactor) + cameraParam.offset;

%% image saver
imwrite(uint16(electronImage),['Test_' num2str(photonCount) '.tif']);

%% data saver
data.image = electronImage;
data.refMean.x = xMean;
data.refMean.y = yMean;
end