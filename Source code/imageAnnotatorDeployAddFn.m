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

function [fpr,fnr,meanSNR,refPos] = imageAnnotatorDeployAddFn(roiRadius,fPath,fName,referenceFlag,refPos)

%% calculatig imageRaw
imageT = Tiff(fullfile(fPath,fName));
imageRaw = imageT.read();
% numFrames = 50;
% imageSub = zeros(size(imageRaw,1),size(imageRaw,2),numFrames);
% for frameId = 1 : numFrames
%     imageT.nextDirectory();
%     imageSub(:,:,frameId) = imageT.read();
% end

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
trueParticlePosCount = 0;
trueParticleFalCount = 0;
snr = [];
lessRoiRad = 3;
for particleId = 1 : size(centroids,1)
    if classVec(particleId,1) == '1' && ...
            centroids(particleId,1) > 2 + roiRadius && ...
            centroids(particleId,1) < size(imageRaw,2) - roiRadius - 2 && ...
            centroids(particleId,2) > 2 + roiRadius && ...
            centroids(particleId,2) < size(imageRaw,1) - roiRadius - 2
        trueParticlePosCount = trueParticlePosCount + 1;
        data.particle(trueParticlePosCount).state = 'accepted';
        data.particle(trueParticlePosCount).pos.x = centroids(particleId,1);
        data.particle(trueParticlePosCount).pos.y = centroids(particleId,2);
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
        data.rejectedParticle(trueParticleFalCount).pos.x = centroids(particleId,1);
        data.rejectedParticle(trueParticleFalCount).pos.y = centroids(particleId,2);
    end
end
meanSNR = median(snr);

%% merging particles
for particleId_1 = 1 : trueParticlePosCount
    if strcmp(data.particle(particleId_1).state,'accepted')
        for particleId_2 = 1 : trueParticlePosCount
            if strcmp(data.particle(particleId_2).state,'accepted') && particleId_1 ~= particleId_2
                if abs(data.particle(particleId_1).pos.x - ...
                        data.particle(particleId_2).pos.x) < 5 &&...
                        abs(data.particle(particleId_1).pos.y - ...
                        data.particle(particleId_2).pos.y) < 5
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
        pos.x = data.particle(particleId).pos.x;
        pos.y = data.particle(particleId).pos.y;
        
        % assigning ROI pixels
        for x = round(pos.x) - roiRadius : round(pos.x) + roiRadius
            for y = round(pos.y) - roiRadius : round(pos.y) + roiRadius
                if (x - round(pos.x)) ^ 2 + (y - round(pos.y)) ^ 2 > (roiRadius - 0.5) ^ 2 && ...
                        (x - round(pos.x)) ^ 2 + (y - round(pos.y)) ^ 2 < (roiRadius + 0.5) ^ 2
                    imageRaw(y,x) = roiInt;
                end
            end
        end
    end
end

if ~referenceFlag
    %% calculating FPR
    TP = 0;
    FP = 0;
    for particleId_detect = 1 : numAccParticles
        if strcmp(data.particle(particleId_detect).state,'accepted')
            
            falsePos = true;
            for particleId_true = 1 : length(refPos.x)
                
                % extracting particle centroid
                x_true = refPos.x(particleId_true);
                y_true = refPos.y(particleId_true);
                
                % extracting particle centroid
                x_detect = data.particle(particleId_detect).pos.x;
                y_detect = data.particle(particleId_detect).pos.y;
                
                if abs(x_true - x_detect) < 1 && abs(y_true - y_detect) < 1
                    TP = TP + 1;
                    falsePos = false;
                    break;
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
        for particleId_true = 1 : length(refPos.x)
            
            % extracting particle centroid
            x_true = refPos.x(particleId_true);
            y_true = refPos.y(particleId_true);
            
            % extracting particle centroid
            x_detect = data.rejectedParticle(particleId_detect).pos.x;
            y_detect = data.rejectedParticle(particleId_detect).pos.y;
            
            if abs(x_true - x_detect) < 1 && abs(y_true - y_detect) < 1
                trueNeg = false;
                break;
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
else
    fpr = 0;
    fnr = 0;
    for particleId = 1 : length(data.particle)
        refPos.x(particleId) = data.particle(particleId).pos.x;
        refPos.y(particleId) = data.particle(particleId).pos.y;
    end
end

%% network annotated imageRaw saver
imwrite(uint16(imageRaw),fullfile(fPath,[fName '_annotated.tif']));
end