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
%% photonCount          0 to 1           normalized lamda factor of poisson distribution
%% numParticles         integer > 0      number of particles to generate
%% numTrainParticles    integer > 0      number of particles to use for training
%% numValidParticles    integer > 0      number of particles to use for validation
%% highTestphotonCount  0 to 1           higher bound of noise level for testing
%% lowTestphotonCount   0 to 1           lower bound of noise level for testing
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

function main(app)

%% user inputs
cameraParam.gain = app.GainEditField.Value;
cameraParam.offset = app.OffsetEditField.Value;
cameraParam.conversionFactor = app.ConversionFactorEditField.Value;
cameraParam.exposureTime = app.ExposureTimeEditField.Value;
cameraParam.darkCurrent = app.DarkCurrentEditField.Value;
cameraParam.readoutNoise = app.ReadoutNoiseEditField.Value;
cameraParam.efficiency = app.EfficiencyEditField.Value;
roiRadius = app.ROIRadiusEditField.Value;
numParticles = app.ParticlesEditField.Value * 10;
numTrainParticles = app.ParticlesEditField.Value;
numParticlesPerImage = app.ParticlesperImageEditField.Value;

%% workflow
gener = app.GenerateCheckBox.Value;
train = app.TrainCheckBox.Value;
test = app.TestCheckBox.Value;

%% initializing variables and structs
imageVec = struct();
classVec = struct();
lowTestphotonCount = 50;
highTestphotonCount = 100;
initialSigma = 1;
finalSigma = 2;

if gener
    
    %% displaying message
    app.MsgBox.Value = sprintf('%s','Generating dataset.');
    drawnow;

    %% training network
    [imageVecTmp,classVecTmp] =...
        trainingSetGeneratorAddFn(roiRadius,numParticles,numParticlesPerImage,lowTestphotonCount,highTestphotonCount,initialSigma,finalSigma,cameraParam);
    imageVec.noise(1).array = imageVecTmp;
    classVec.noise(1).array = classVecTmp;
    
    %% saving generated data
    save(['imageVec_' num2str(roiRadius)],'imageVec');
    save(['classVec_' num2str(roiRadius)],'classVec');
end

if train
    
    %% displaying message
    app.MsgBox.Value = sprintf('%s','Training neural network.');
    drawnow;
    
    %% loading generated data
    load(['imageVec_' num2str(roiRadius)]);
    load(['classVec_' num2str(roiRadius)]);
    
    %% validating network
    imageVecTmp = imageVec.noise(1).array;
    classVecTmp = classVec.noise(1).array;
    neuralNet = networkTrainerAddFn(roiRadius,imageVecTmp(:,:,1,1:numTrainParticles),classVecTmp(1:numTrainParticles,1));
end

if test
    
    %% displaying message
    app.MsgBox.Value = sprintf('%s','Testing neural network.');
    drawnow;
    photonCountVec = 1:1:100;
    
    %% generating images
    for noiseId = 1 : length(photonCountVec)
        data.noise(noiseId).array = imageGeneratorAddFn(roiRadius,numParticlesPerImage,photonCountVec(noiseId),initialSigma,finalSigma,cameraParam);
    end
    
    %% annotating images
    for noiseId = 1 : length(photonCountVec)
        [FPR(noiseId),FNR(noiseId),snr(noiseId)] = imageAnnotatorAddFn(data.noise(noiseId).array,roiRadius,photonCountVec(noiseId));
    end
    
    %% plotting FPR, FNR against SNR
    fontSize = 20;
    figure;
    x = snr;
    yLeft = FPR .* 100;
    yRight = FNR .* 100;
    yyaxis left
    plot(x,yLeft,'-','MarkerSize',10,'MarkerEdgeColor','red','MarkerFaceColor','red','LineWidth',3);
    ylabel('FPR (%)','FontSize',fontSize);
    yyaxis right
    plot(x,yRight,'-','MarkerSize',10,'MarkerEdgeColor','red','MarkerFaceColor','red','LineWidth',3);
    ylabel('FNR (%)','FontSize',fontSize);
    axis square;
    box off;
    xlabel('SNR','FontSize',fontSize);
    set(gca,'fontsize',fontSize,'FontName','Arial','LineWidth',3);
end

%% displaying message
app.MsgBox.Value = sprintf('%s','Done.');
end