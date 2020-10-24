%% DeepSinse
%% ========================================================================
%% imageAnnotatorDeployAddFn
%% Code for classifying / annotating particles in acquired image
%% ========================================================================
%% reguirements:
%% neuralNetwork.mat file saved by networkTrainerAddFn
%% ========================================================================
%% Copyright 2020 John S H Danial
%% Department of Chemistry, Univerity of Cambridge

function imageAnnotatorDeployAddFn(imageRaw,roiRadius,fPath,fName)

%% calculating parameters
roiWidth = roiRadius * 2 + 1;

%% thresholding imageRaw
thresholdimageRaw = imregionalmax(imageRaw,8);

%% extracting connected objects from threshold imageRaw
[centroidTemp_y,centroidTemp_x] = ind2sub(size(thresholdimageRaw),find(thresholdimageRaw == true));
centroids = [centroidTemp_x centroidTemp_y];

%% creating an array of all particles in an imageRaw
imageRawVec = zeros(roiWidth,roiWidth,1,size(centroids,1));
for particleId = 1 : size(centroids,1)
    try
        imageRawVec(:,:,1,particleId) = imageRaw(round(centroids(particleId,2)) - roiRadius :...
            round(centroids(particleId,2)) + roiRadius,...
            round(centroids(particleId,1)) - roiRadius:...
            round(centroids(particleId,1)) + roiRadius);
        imageRawVec(:,:,:,particleId) = (imageRawVec(:,:,:,particleId) - min(min(imageRawVec(:,:,:,particleId)))) / ...
            (max(max(imageRawVec(:,:,:,particleId))) - min(min(imageRawVec(:,:,:,particleId))));
    catch
    end
end

%% loading trained neural network
net = load(['neuralNetwork.mat']);
neuralNetwork = net.neuralNet;
classVec(:,1) = classify(neuralNetwork,imageRawVec);


%% accepting or rejecting particles based on classification
trueParticleCount = 0;
for particleId = 1 : size(centroids,1)
    if classVec(particleId,1) == '1' && ... 
            centroids(particleId,1) > 2 + roiRadius && ...
            centroids(particleId,1) < size(imageRaw,2) - roiRadius - 1 && ...
            centroids(particleId,2) > 2 + roiRadius && ...
            centroids(particleId,2) < size(imageRaw,1) - roiRadius - 1
        trueParticleCount = trueParticleCount + 1;
        data.particle(trueParticleCount).state = 'accepted';
        data.particle(trueParticleCount).mean.x = centroids(particleId,1);
        data.particle(trueParticleCount).mean.y = centroids(particleId,2);
    end
end

%% extracting number of particles
numParticles = length(data.particle);

%% calculating ROI intensity
roiInt = max(imageRaw(:));

%% looping through network accepted particles
for particleId = 1 : numParticles
    
    if strcmp(data.particle(particleId).state,'accepted')
        
        % extracting particle centroid
        mean.x = data.particle(particleId).mean.x;
        mean.y = data.particle(particleId).mean.y;
        
        % assigning ROI pixels
        for x = round(mean.x) - roiRadius : round(mean.x) + roiRadius
            for y = round(mean.y) - roiRadius : round(mean.y) + roiRadius
                if (x - round(mean.x)) ^ 2 + (y - round(mean.y)) ^ 2 > (roiRadius - 0.5) ^ 2 && ...
                        (x - round(mean.x)) ^ 2 + (y - round(mean.y)) ^ 2 < (roiRadius + 0.5) ^ 2
                    imageRaw(y,x) = roiInt;
                end
            end
        end
    end
end

%% network annotated imageRaw saver
imwrite(uint16(imageRaw),fullfile(fPath,[fName '_annotated.tif']));
end