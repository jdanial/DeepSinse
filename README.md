# DeepSinse
Code for detection/segmentation of single molecule bursts under different noise and acquisition conditions using deep learning. To use, clone this repository to a folder of your choice.
## Generating datasets, training and testing
To generate training datasets, train the neural network, validate and test the trained network, please run the `DeepSinse` app from the Source code or Exectuables folder. There are 8 parameters which need to be specified and their units are as follows: `Gain` (unitless), `Offset` (counts), `Conversion Factor` (electrons/ADU), `Exposure Time` (seconds), `Dark Current` (electrons), `Readout Noise` (electrons), `QE Efficiency` (unitless), `ROI Radius` (pixels). A number of files will be saved in the folder where `DeepSinse` is located and these are: `imageVec` a MATLAB array containing the different training ROIs,   `classVec` a categorical array of the classifications of the ROIs in `imageVec`, `neuralNetwork` trained neural network and several image files containing the ground-truth and network-produced annotatons. 
### Generating datasets from experimentally-obtained images
To generate datasets from experimentally-obtained images, run the `ROIPicker` app, select the folder containing all images, select particle or noise ROIs by left-clicking on their respective locations on image and save the extracted data. The 2 saved files, named `imageVec` and `classVec` will be saved in the folder where DeepSinse is cloned.  
## Deployment
To deploy the neural network on experimentally-acquired images (after training), please run the `deploy` code.
## Implementation
For a faster implemention, please check the [StormProcessor](https://github.com/jdanial/DeepSinse/StormProcessor).
