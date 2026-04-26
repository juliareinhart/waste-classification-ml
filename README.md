# Real Waste Classification

## Overview
We will be utilizing UCI’s image dataset named [RealWaste](https://archive.ics.uci.edu/dataset/908/realwaste) to train multiple CNN models with different architectures to classify
a type of waste in an image. We will be comparing and contrasting the different CNN Architectures.

## Data
RealWaste dataset was provided from the Research Paper:
["RealWaste: A Novel Real-Life Data Sert for Landfill Waste Classification Using Deep Learning"](https://www.mdpi.com/2078-2489/14/12/633)
and RealWaste dataset is licensed under the [Creative Commons Attribution 4.0 International](https://creativecommons.org/licenses/by/4.0/legalcode)

The dataset used for this project was retrieved from UCI's Machine Learning Repository Datasets
https://archive.ics.uci.edu/dataset/908/realwaste

### Structure
The dataset contains multiple images classified as one of the following labels:
  * Cardboard: 461
  * Food Organics: 411
  * Glass: 420
  * Metal: 790
  * Miscellaneous Trash: 495
  * Paper: 500
  * Plastic: 921
  * Textile Trash: 318
  * Vegetation: 436
   
## Objective
Classify waste objects using different CNNs to compare and contrast

### Model Training Supervision
Supervised Learning

### Performance Measure

### Assumptions
Any waste classification that is not cardboard, food organics, glass, metal, paper, plastic, textile, or vegetation will
be classified as miscellaneous trash.