# Acf-jacinto

Object detection training for embedded platforms.

###### Notice: 
- If you have not visited our landing page in github, please do so: [https://github.com/TexasInstruments/jacinto-ai-devkit](https://github.com/TexasInstruments/jacinto-ai-devkit)
- **Issue Tracker for jacinto-ai-devkit:** You can file issues or ask questions at **e2e**: [https://e2e.ti.com/support/processors/f/791/tags/jacinto_2D00_ai_2D00_devkit](https://e2e.ti.com/support/processors/f/791/tags/jacinto_2D00_ai_2D00_devkit). While creating a new issue, the part number should be filled in as **TDA4VM**. Also, kindly include **jacinto-ai-devkit** in the tags (at the end of the page as you create a new issue). 
- **Issue Tracker for TIDL:** [https://e2e.ti.com/support/processors/f/791/tags/TIDL](https://e2e.ti.com/support/processors/f/791/tags/TIDL). Please use part number as **TDA4VM** and tag as **TIDL**
- If you do not get a reply within two days, please contact us at: jacinto-ai-devkit@list.ti.com

Acf-jacinto is a modification of the Piotr's toolbox to enable training of ACF object detection models suitable for low power embedded platforms.

The following were the main changes made in acf-jacinto compared to the Piotr’s Toolbox:

* Fast HOG computation method (that doesn't use division or tabkle lookup) and cell sum. It is not MMX accelerated yet.
* Use simple to compute YUV features instead of LUV.
* Disable feature rescale and use feature computation for each scale. (This change is not really required for a reasonably large dataset captured on road, but it helps in InriaPerson dataset, when using the above HOG computation).
* Include positive images also in bootstrap.
* Change channel order and put HOG first.
* Disable gradient normalization as it involves division, and also doesn't seem to be helping.
* Do input pre-processing: adaptive histogram equalization and smoothing.
* Change default size to 64x64 feature, 24x56 object model to be able to detect farther, smaller objects.
* Change detection threshold.
* Write out the descriptor in an easy to read text format.
* Support MP4 videos for extraction. Option to extract only annoted frames in a video. Only few frames in a video need to be annotated. But if a frame is annotated, that frame should be fully annotated for teh object of interest.
* Dataset extraction made easy. Just specify your videos and vbb files directly in the matlab script.
* Added the [caltech pedestrian bench marck evaluation labeling code](http://www.vision.caltech.edu/Image_Datasets/CaltechPedestrians/code/code3.2.1.zip) into the repository under the folder vbb.
* vbbLabeler (see vbb folder) is updated to be able to open and annotate MP4 videos. It can also read a list of bjects if a file called objectTypes.txt is present in the current folder.
* Other cosmetic and usability improvements.

## Usage

* Open Matlab and navigate to detector folder.
* Open acfJacintoExample.m in editor
* Make changes for your dataset path, list of videos and annotations files, object type to be trained etc.
* Run the file to do train and test.




## Acf

The following links will direct to the original Acf / Piotr's toolbox

https://github.com/pdollar/toolbox <br>
https://pdollar.github.io/toolbox/ <br>
