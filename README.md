PaperDoll clothing parser
=========================

Unconstrained clothing parser for a full-body picture.

    Paper Doll Parsing: Retrieving Similar Styles to Parse Clothing Items
    Kota Yamaguchi, M. Hadi Kiapour, Tamara L. Berg
    ICCV 2013

This package only contains source codes. Download additional data files to
use the parser or to run an experiment.

Web-scraped data (Update 2018-10-28)
------------------------------------

We also release the metadata we scraped from Chictopia for academic research.
[Check the data directory](data/chictopia/).

Related work:

Shuai Zheng, Fan Yang, M. Hadi Kiapour, Robinson Piramuthu. ModaNet: A Large-Scale Street Fashion Dataset with Polygon Annotations. ACM Multimedia, 2018.
https://github.com/eBay/modanet


Getting a pre-trained model
---------------------------

To parse a new image using a pre-trained models, only download the model file (Caution: ~70GB).

```bash
cd paperdoll/
for i in 00 01 02 03 04 05 06 07 08 09 10 11 12 13 14
do
    wget http://vision.is.tohoku.ac.jp/~kyamagu/research/paperdoll/models-v1.0.tar.$i
done
```

Check the MD5SUM to make sure download is successful.

```bash
md5sum -b models-v1.0.tar.*
```

    3f14f5d90e4c3c3ce014311dce0df1bf *models-v1.0.tar.00
    46bb5d046dc6f9a6e6cb3c9832ab4c6d *models-v1.0.tar.01
    85f089dd4a589e02fe5da1fb16b7dbae *models-v1.0.tar.02
    b0f0d18bd9ec13fbc6c63e0a1fd6356d *models-v1.0.tar.03
    1b7838c2d4c8287f900992f3e7969f9c *models-v1.0.tar.04
    5e7f9c7a87e3cc753b4508daa65c247a *models-v1.0.tar.05
    e7ae269f42e1b7bdf30f9cac3b7ea62a *models-v1.0.tar.06
    96c92e94ae179fd805f731da65636604 *models-v1.0.tar.07
    b3c5f7a89a78a7dc60ee57641b6297e9 *models-v1.0.tar.08
    0371ddec6c5ce04cf185f30cfd8e92ce *models-v1.0.tar.09
    e9b7a90856b58d7d47f5f28902ccc561 *models-v1.0.tar.10
    6ced6bf6292c3893cc4ba429ac4617b8 *models-v1.0.tar.11
    57d4b0617d984c767b4617da2e44158f *models-v1.0.tar.12
    1ee83b90fd49b0fe4310c89ceaf69a17 *models-v1.0.tar.13
    7db0e3291730e53ffed526144c2c8e10 *models-v1.0.tar.14

If files are clean, unarchive.

```bash
cat models-v1.0.tar.* | tar xf -
```

To run an experiment from scratch, download the training data (without photos).

```bash
cd paperdoll/
wget http://vision.is.tohoku.ac.jp/~kyamagu/research/paperdoll/data-v1.0.tar
tar xvf data-v1.0.tar
rm data-v1.0.tar
```

Contents
--------

    data/        Directory to place data.
    lib/         Library directory.
    log/         Log directory.
    tasks/       Experimental scripts.
    tmp/         Temporary data directory.
    README.md    This file.
    LICENSE.txt  Lincense notice.
    make.m       Build script.
    startup.m    Runtime initialization script.

Build
-----

The software is originally developed on Ubuntu 12.04 LTS and also tested
using Ubuntu 14.04 LTS with Matlab R2014a.

The following are the prerequisites for clothing parser.

 * Matlab
 * OpenCV
 * Berkeley DB
 * Boost C++ library

Also, to run all the experiments in the paper, it is required to have a
computing grid with Sun Grid Engine (SGE) or compatible distributed
environment. In Ubuntu, search for how to use `grindengine` package.

To install these requirements in Ubuntu,

```bash
sudo apt-get install build-essential libopencv-dev libdb-dev libboost-all-dev
```

After installing prerequisites, the attached `make.m` script will compile all
the necessary binaries within Matlab.

```matlab
make
```

### Runtime error

Depending on the Matlab installation, it is probably necessary to resolve
conflicting library dependency. Use `LD_PRELOAD` environmental variable
to prevent conflict at runtime. For example, in Ubuntu,

```bash
LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6:/lib/x86_64-linux-gnu/libgcc_s.so.1:/lib/x86_64-linux-gnu/libz.so.1 matlab -singleCompThread
```

To find a conflicting library, use `ldd` tool within Matlab and also from
outside of Matlab, then compare the output. Append suspicious library
to the `LD_PRELOAD` variable.

```matlab
!ldd lib/mexopencv/+cv/imread.mex*
```

```bash
ldd lib/mexopencv/+cv/imread.mex*
```


Usage
-----

Launch Matlab from the project root directory (i.e., `paperdoll-v1.0/`).
This will automatically call `startup` to initialize necessary environment.

### Run a pre-trained parser for a new image

```matlab
load data/paperdoll_pipeline.mat config;
input_image = imread('/path/to/new_image.jpg');
input_sample = struct('image', imencode(input_image, 'jpg'));
result = feature_calculator.apply(config, input_sample)
```

The result is a struct with the following fields.

 * `image`: input image in JPEG-format.
 * `pose`: estimated pose.
 * `refined_labels`: predicted clothing items.
 * `final_labeling`: PNG-encoded labeling.

To get a per-pixel labeling, use `imdecode`. For example, the following example
access the label of the pixel at (100, 100).

```matlab
labeling = imdecode(result.final_labeling, 'png');
label = result.refined_labels{labeling(100, 100)};
```

To visualize the parsing result.

```matlab
show_parsing(result.image, result.final_labeling, result.refined_labels);
```

_TIPS_

The pose estimator is set up to process roughly 600x400 pixels in the
pre-trained model. Change the configuration by setting the image scaling
parameter. Also, lower the threshold value if the pipeline throws an error
in pose estimation.

```matlab
config{1}.scale = [200,200]; % Set the maximum image size in the pose estimator.
                             % It is best to specify no larger than 200 pixels.
config{1}.model.thresh = -2; % Change the threshold value if pose estimation fails.
```

### Run an experiment from scratch

Due to the copyright concern, we only provide image URLs in the PaperDoll
dataset. We also provide a script to download images. Please note that some of
the images might not be accessible at the provided URL since they might be
deleted by users. Depending on the network connection, downloading images takes
a day or more.

```bash
echo task100_download_paperdoll_photos | matlab -nodisplay
```

After getting training images, use `tasks/paperdoll_main.sh` to run an
experiment from scratch. The script is designed to run on an SGE cluster
environment with Ubuntu 12.04 and all the required libraries.

```bash
nohup ./tasks/paperdoll_main.sh < /dev/null > log/paperdoll_main.log 2>&1 &
```

Again, depending on the configuration, this can take a few days. Note that
because of the randomness in some of the algorithms and also the data
availability, we don't guarantee this reproduces the exact numbers reported in
the paper. However, the resulting model should give a similar figure.


SGE cluster with Debian/Ubuntu
------------------------------

To build an SGE grid in Debian/Ubuntu, install the following packages.

_Master_

```bash
sudo apt-get install gridengine-* default-jre
```

_Clients_

```bash
apt-get install gridengine-exec gridengine-client default-jre
```

See [Documentation](http://docs.oracle.com/cd/E24901_01/index.htm) for
configuration details. The `qmon` tool can be used to set up the environment.
Sometimes it is necessary to change how the hostname is resolved in
`/etc/hosts`.

Data format
-----------

### `data/fashionista_v0.2.mat`

This file contains the Fashionista dataset from [Yamaguchi et. al. CVPR 2011]
with ground truth annotation and also their parsing results in unconstrained
parsing. The file contains three variables:

 * `truths`: ground truth annotation in struct array.
 * `predictions`: predicted parsing results in struct array.
 * `test_index`: samples used for training.

The sample struct has the following fields.

 * `index`: index of the sample.
 * `url`: URL of the original image.
 * `image`: JPEG-encoded image data.
 * `pose`: struct of pose annotation or prediction.
 * `annotation`: struct of clothing segmentation.
 * `id`: unique sample ID.

The pose annotation contains 14 points in image coordinates (x,y). The order
of annotation is the following.

    {...
        'right_ankle',...
        'right_knee',...
        'right_hip',...
        'left_hip',...
        'left_knee',...
        'left_ankle',...
        'right_hand',...
        'right_elbow',...
        'right_shoulder',...
        'left_shoulder',...
        'left_elbow',...
        'left_hand',...
        'neck',...
        'head'...
    }

The clothing segmentation struct consists of the following fields.

* `superpixel_map`: PNG-encoded superpixel segmentation.
* `superpixel_labels`: Clothing annotation for each superpixel.
* `labels`: Cell strings of clothing names.
* `marginals`: Marginal probability of clothing labels at each superpixel.

To access per-pixel annotation of sample `i`,

```matlab
segmentation = imdecode(truths(i).superpixel_map, 'png');
clothing_annotation = truhts(i).superpixel_labels(segmentation);
```

To get a label at pixel (100, 100),

```matlab
label = truths(i).labels{clothing_annotation(100, 100)}
```


### `data/paperdoll_dataset.mat`

The file contains two variables:

 * `labels`: cell strings of all clothing labels in the dataset.
 * `samples`: struct array of data samples with following fields.

Each sample has the following fields.

 * `id`: unique sample ID.
 * `url`: URL of the jpg file.
 * `post_url`: URL of the blog post.
 * `tagging`: indices of the associated tags.

To access tags of the sample `i`:

```matlab
tags = labels(samples(i).tagging);
```


### `data/INRIA_data.mat`

The file contains negative samples to train a pose estimator. There is one
variable:

* `samples`: struct array of samples. The `im` field contains JPEG-encoded
  images. The `point` is empty.


License
-------

The PaperDoll codes are distributed under BSD license. However, some of the
dependent libraries in `lib/` might be protected by other license. Check each
directory for detail.
