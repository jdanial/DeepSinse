%% DeepSinse
%% ========================================================================
%% imageAnnotatorAddFn
%% Code for classifying / annotating particles in image
%% ========================================================================
%% reguirements:
%% neuralNetwork.mat file saved by networkTrainerAddFn
%% ========================================================================
%% Copyright 2020 John S H Danial
%% Department of Chemistry, Univerity of Cambridge

function [accuracy,fpr] = imageAnnotatorAddFn(data,roiRadius,meanNoise)

%% calculating parameters
roiWidth = roiRadius * 2 + 1;

%% extracting image
image = data.image;

%% thresholding image
thresholdImage = imregionalmax(image,8);

%% extracting connected objects from threshold image
[centroidTemp_y,centroidTemp_x] = ind2sub(size(thresholdImage),find(thresholdImage == true));
centroids = [centroidTemp_x centroidTemp_y];

%% creating an array of all particles in an image
imageVec = zeros(roiWidth,roiWidth,1,size(centroids,1));
for particleId = 1 : size(centroids,1)
    try
        imageVec(:,:,1,particleId) = image(round(centroids(particleId,2)) - roiRadius :...
            round(centroids(particleId,2)) + roiRadius,...
            round(centroids(particleId,1)) - roiRadius:...
            round(centroids(particleId,1)) + roiRadius);
        imageVec(:,:,:,particleId) = (imageVec(:,:,:,particleId) - min(min(imageVec(:,:,:,particleId))))/ ...
            (max(max(imageVec(:,:,:,particleId))) - min(min(imageVec(:,:,:,particleId))));
    catch
    end
end

%% loading trained neural network
net = load(['neuralNetwork.mat']);
neuralNetwork = net.neuralNet;
classVec(:,1) = classify(neuralNetwork,imageVec);

%% accepting or rejecting particles based on classification
trueParticleCount = 0;
for particleId = 1 : size(centroids,1)
    if classVec(particleId,1) == '1' && ...
            centroids(particleId,1) > 2 + roiRadius && ...
            centroids(particleId,1) < size(image,1) - roiRadius - 1 && ...
            centroids(particleId,2) > 2 + roiRadius && ...
            centroids(particleId,2) < size(image,2) - roiRadius - 1
        trueParticleCount = trueParticleCount + 1;
        data.particle(trueParticleCount).state = 'accepted';
        data.particle(trueParticleCount).mean.x = centroids(particleId,1);
        data.particle(trueParticleCount).mean.y = centroids(particleId,2);
    end
end

%% extracting number of particles
numParticles = length(data.particle);

%% calculating ROI intensity
roiInt = max(image(:));

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
                    image(y,x) = roiInt;
                end
            end
        end
    end
end

%% network annotated image saver
imwrite(uint16(image),['Test_Network_Annotated' num2str(meanNoise*100) '.tif']);

%% extracting image
image = data.image;

%% looping through ground-truth generated particles
for particleId = 1 : length(data.mean.x)
    
    % extracting particle centroid
    mean.x = data.mean.x(particleId);
    mean.y = data.mean.y(particleId);
    
    % assigning ROI pixels
    for x = round(mean.x) - roiRadius : round(mean.x) + roiRadius
        for y = round(mean.y) - roiRadius : round(mean.y) + roiRadius
            if (x - round(mean.x)) ^ 2 + (y - round(mean.y)) ^ 2 > (roiRadius - 0.5) ^ 2 && ...
                    (x - round(mean.x)) ^ 2 + (y - round(mean.y)) ^ 2 < (roiRadius + 0.5) ^ 2
                image(y,x) = roiInt;
            end
        end
    end
end

%% calculating accuracy and FPR
TP = 0;
FP = 0;
P = 0;
for particleId_true = 1 : length(data.mean.x)
    
    % extracting particle centroid
    x_true = data.mean.x(particleId_true);
    y_true = data.mean.y(particleId_true);
    
    if y_true > 2 + roiRadius && ...
            y_true < size(image,1) - roiRadius - 1 && ...
            x_true > 2 + roiRadius && ...
            x_true < size(image,2) - roiRadius - 1
        
        P = P + 1;
        falsePos = true;
        % assigning ROI pixels
        for particleId_detect = 1 : numParticles
            if strcmp(data.particle(particleId_detect).state,'accepted')
                
                % extracting particle centroid
                x_detect = data.particle(particleId_detect).mean.x;
                y_detect = data.particle(particleId_detect).mean.y;
                
                if abs(x_true - x_detect) < 2 && abs(y_true - y_detect) < 2
                    TP = TP + 1;
                    falsePos = false;
                    break;
                end
            end
        end
        if falsePos
            FP = FP + 1;
        end
    end
end
accuracy = TP / P;
fpr = FP / P;

%% network annotated image saver
imwrite(uint16(image),['Test_Pre_Annotated' num2str(meanNoise*100) '.tif']);
end