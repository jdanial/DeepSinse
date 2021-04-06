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

function [fpr,fnr,refMeanSNR] = imageAnnotatorAddFn(data,roiRadius,photonCount)

%% calculating parameters
roiWidth = roiRadius * 2 + 1;

%% extracting image
imageRaw = data.image;

%% looping through ground-truth generated particles
varInt = [];
lessRoiRad = 3;
for particleId = 1 : length(data.refMean.x)
    
    % extracting particle centroid
    refMean.x = data.refMean.x(particleId);
    refMean.y = data.refMean.y(particleId);
    
    % assigning ROI pixels
    varInt = [varInt max(max(imageRaw(round(refMean.y) - (roiRadius - lessRoiRad) : round(refMean.y) + (roiRadius - lessRoiRad),round(refMean.x) - (roiRadius - lessRoiRad) : round(refMean.x) + (roiRadius - lessRoiRad))))];
end


%% thresholding image
thresholdImage = imregionalmax(imageRaw,8);

%% extracting connected objects from threshold image
[centroidTemp_y,centroidTemp_x] = ind2sub(size(thresholdImage),find(thresholdImage == true));
centroids = [centroidTemp_x centroidTemp_y];

%% creating an array of all particles in an image
imageVec = zeros(roiWidth,roiWidth,1,size(centroids,1));
for particleId = 1 : size(centroids,1)
    try
        imageVec(:,:,1,particleId) = imageRaw(round(centroids(particleId,2)) - roiRadius :...
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
classVec(:,1) = classify(neuralNetwork,imageVec,'ExecutionEnvironment','gpu','MiniBatchSize',100000,'Acceleration','auto');

%% accepting or rejecting particles based on classification
trueParticlePosCount = 0;
trueParticleFalCount = 0;
snr = [];
for particleId = 1 : size(centroids,1)
    if classVec(particleId,1) == '1' && ...
            centroids(particleId,1) > 2 + roiRadius && ...
            centroids(particleId,1) < size(imageRaw,1) - roiRadius - 1 && ...
            centroids(particleId,2) > 2 + roiRadius && ...
            centroids(particleId,2) < size(imageRaw,2) - roiRadius - 1
        trueParticlePosCount = trueParticlePosCount + 1;
        data.particle(trueParticlePosCount).state = 'accepted';
        data.particle(trueParticlePosCount).refMean.x = centroids(particleId,1);
        data.particle(trueParticlePosCount).refMean.y = centroids(particleId,2);
        bkgIn = [];
        for rowId = centroids(particleId,2) - roiRadius - 2 : centroids(particleId,2) + roiRadius + 2
            for colId = centroids(particleId,1) - roiRadius - 2 : centroids(particleId,1) + roiRadius + 2
                if (rowId < centroids(particleId,2) - (roiRadius - lessRoiRad) || rowId > centroids(particleId,2) + (roiRadius - lessRoiRad)) && ...
                        (colId < centroids(particleId,1) - (roiRadius - lessRoiRad) || colId > centroids(particleId,1) + (roiRadius - lessRoiRad))
                    bkgIn = [bkgIn imageRaw(rowId,colId)];
                end
            end
        end
        intIn = mean(mean(imageRaw(centroids(particleId,2) - 1 : centroids(particleId,2) + 1,centroids(particleId,1) - 1 : centroids(particleId,1) + 1)));
        snr = [snr double(intIn - mean(bkgIn)) / sqrt(var(double(bkgIn)))];
    elseif classVec(particleId,1) == '0'
        trueParticleFalCount = trueParticleFalCount + 1;
        data.rejectedParticle(trueParticleFalCount).refMean.x = centroids(particleId,1);
        data.rejectedParticle(trueParticleFalCount).refMean.y = centroids(particleId,2);
    end
end
refMeanSNR = median(snr);

%% merging particles
for particleId_1 = 1 : trueParticlePosCount
    if strcmp(data.particle(particleId_1).state,'accepted')
        for particleId_2 = 1 : trueParticlePosCount
            if strcmp(data.particle(particleId_2).state,'accepted') && particleId_1 ~= particleId_2
                if abs(data.particle(particleId_1).refMean.x - ...
                        data.particle(particleId_2).refMean.x) < 5 &&...
                        abs(data.particle(particleId_1).refMean.y - ...
                        data.particle(particleId_2).refMean.y) < 5
%                     data.particle(particleId_1).refMean.x = ...
%                         (data.particle(particleId_1).refMean.x +...
%                         data.particle(particleId_2).refMean.x) / 2;
%                     data.particle(particleId_1).refMean.y = ...
%                         (data.particle(particleId_1).refMean.y +...
%                         data.particle(particleId_2).refMean.y) / 2;
                    data.particle(particleId_2).state = 'rejected';
                    break;
                end
            end
        end
    end
end

%% extracting number of particles
numAccParticles = length(data.particle);
numRejParticles = length(data.rejectedParticle);

%% calculating ROI intensity
roiInt = max(imageRaw(:));

%% looping through network accepted particles
for particleId = 1 : numAccParticles
    
    if strcmp(data.particle(particleId).state,'accepted')
        
        % extracting particle centroid
        refMean.x = data.particle(particleId).refMean.x;
        refMean.y = data.particle(particleId).refMean.y;
        
        % assigning ROI pixels
        for x = round(refMean.x) - roiRadius : round(refMean.x) + roiRadius
            for y = round(refMean.y) - roiRadius : round(refMean.y) + roiRadius
                if (x - round(refMean.x)) ^ 2 + (y - round(refMean.y)) ^ 2 > (roiRadius - 0.5) ^ 2 && ...
                        (x - round(refMean.x)) ^ 2 + (y - round(refMean.y)) ^ 2 < (roiRadius + 0.5) ^ 2
                    imageRaw(y,x) = roiInt;
                end
            end
        end
    end
end

%% network annotated image saver
imwrite(uint16(imageRaw),['Test_Network_Annotated' num2str(photonCount) '.tif']);

%% extracting image
imageRaw = data.image;

%% looping through ground-truth generated particles
for particleId = 1 : length(data.refMean.x)
    
    % extracting particle centroid
    refMean.x = data.refMean.x(particleId);
    refMean.y = data.refMean.y(particleId);
    
    % assigning ROI pixels
    for x = round(refMean.x) - roiRadius : round(refMean.x) + roiRadius
        for y = round(refMean.y) - roiRadius : round(refMean.y) + roiRadius
            if (x - round(refMean.x)) ^ 2 + (y - round(refMean.y)) ^ 2 > (roiRadius - 0.5) ^ 2 && ...
                    (x - round(refMean.x)) ^ 2 + (y - round(refMean.y)) ^ 2 < (roiRadius + 0.5) ^ 2
                imageRaw(y,x) = roiInt;
            end
        end
    end
end

%% calculating FPR
TP = 0;
FP = 0;
for particleId_detect = 1 : numAccParticles
    if strcmp(data.particle(particleId_detect).state,'accepted')
        
        falsePos = true;
        for particleId_true = 1 : length(data.refMean.x)
            
            % extracting particle centroid
            x_true = data.refMean.x(particleId_true);
            y_true = data.refMean.y(particleId_true);
            
            if y_true > 2 + roiRadius && ...
                    y_true < size(imageRaw,1) - roiRadius - 1 && ...
                    x_true > 2 + roiRadius && ...
                    x_true < size(imageRaw,2) - roiRadius - 1
                
                % extracting particle centroid
                x_detect = data.particle(particleId_detect).refMean.x;
                y_detect = data.particle(particleId_detect).refMean.y;
                
                if abs(x_true - x_detect) < 1 && abs(y_true - y_detect) < 1
                    TP = TP + 1;
                    falsePos = false;
                    break;
                end
            end
        end
        if falsePos
            FP = FP + 1;
        else
            TP = TP + 1;
        end
    end
end

%% calculating FNR
TN = 0;
FN = 0;
for particleId_detect = 1 : numRejParticles

        trueNeg = true;
        for particleId_true = 1 : length(data.refMean.x)
            
            % extracting particle centroid
            x_true = data.refMean.x(particleId_true);
            y_true = data.refMean.y(particleId_true);
            
            if y_true > 2 + roiRadius && ...
                    y_true < size(imageRaw,1) - roiRadius - 1 && ...
                    x_true > 2 + roiRadius && ...
                    x_true < size(imageRaw,2) - roiRadius - 1
                
                % extracting particle centroid
                x_detect = data.rejectedParticle(particleId_detect).refMean.x;
                y_detect = data.rejectedParticle(particleId_detect).refMean.y;
                
                if abs(x_true - x_detect) < 1 && abs(y_true - y_detect) < 1
                    trueNeg = false;
                    break;
                end
            end
        end
        if trueNeg
            TN = TN + 1;
        else
            FN = FN + 1;
        end
end
fpr = FP / (FP + TN);
fnr = FN / (FN + TP);

%% network annotated image saver
imwrite(uint16(imageRaw),['Test_Pre_Annotated' num2str(photonCount) '.tif']);
end