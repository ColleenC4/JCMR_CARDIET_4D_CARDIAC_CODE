# README #

JCMR Cardiet et al., Self-gated 5D Cardiac Magnetic Resonance in Mice Model : A detailed study


### What is this repository for? ###
This repository includes code to download input data, reconstruct, analyze, and generate figures for a magnetic resonance cardiac sequence as published under "Self-gated 5D Cardiac Magnetic Resonance in Mice Model : A detailed study" in Journal of Cardiovascular Magnetic Resonance.

Requirements:
-------------
* MATLAB  - for reconstruction, processing, and figure generation
* gpuNUFFT 2.0.8 - find more information at https://github.com/andyschwarzl/gpuNUFFT 
* BruKitchen - compile this file to run the sequence, find more information at https://github.com/tesch1/BruKitchen

Tested Configuration:
---------------------
* Mac OS X 10511.5 (El Capitan)
* MATLAB R2015a
* Python 2.7.13

Installation Options:
---------------------
* Click the `Download ZIP` button on the lower right hand side of the repository to download the code to your local machine
* OR clone the git repository to your local machine
* OR fork to your own repository and then clone the git repository to your local machine

Data:
------
* Mice datasets used in the paper are available here : https://data.mendeley.com/datasets/vhnvp57b6f/draft?a=e004f3c0-78a9-4d2a-8de3-ff90b32791a6

Usage:
------
* Download datasets and place them in the 'data_in' file
* Go to `./code/` and run `UTE_3D_SG_reco.m`
* Choose the number of mouse you want to study
* Choose the type of reconstruction you want (As a function of the respiratory or the cardiac cycle)
* Code is not optimized for speed, the total processing time is ~20 minutes
* Reconstructed images will be in the 'data_out' file

Folder Structure:
--------

`./code/` - (with downloaded contributors) contains all code necessary to reconstruct, process, and generate figures


### License ###

See LICENSE

### Contributors ###

See contributors.txt


