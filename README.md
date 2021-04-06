# DeepSinse
Code for detection/segmentation of single molecule bursts under different noise and acquisition conditions using deep learning. To use, clone this repository to a folder of your choice.
## Training and validation
To generate training datasets, train the neural network, validate and test the trained network, please run the `DeepSinse` app from the Source code or Exectuables folder. There are 8 parameters which need to be specified and their units are as follows: `Gain` (unitless), `Offset` (counts), `Conversion Factor` (electrons/ADU), `Exposure Time` (seconds), `Dark Current` (electrons), `Readout Noise` (electrons), `QE Efficiency` (unitless), `ROI Radius` (pixels).  
### Generating datasets from experimentally-obtained images
To generate datasets from experimentally-obtained images, run the `ROIPicker` app, select the folder containing all images, select particle or noise ROIs by left-clicking on their respective locations on image and save the extracted data. The 2 saved files, named `imageVec` and `classVec` will be saved in the folder where DeepSinse is cloned.  
## Deployment
To deploy the neural network on experimentally-acquired images (after training), please run the `deploy` code.
## Implementation
For a faster implemention, please check the [StormProcessor](https://github.com/jdanial/DeepSinse/StormProcessor).
