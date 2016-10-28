PaperDoll clothing parser
=========================

Unconstrained clothing parser for a full-body picture.

    Paper Doll Parsing: Retrieving Similar Styles to Parse Clothing Items
    Kota Yamaguchi, M. Hadi Kiapour, Tamara L. Berg
    ICCV 2013

This package only contains source codes. Download additional data files to
use the parser or to run an experiment.

To parse a new image using a pre-trained models, only download the model file (Caution: ~70GB).

    $ cd paperdoll-v1.0/
    $ wget http://vision.cs.stonybrook.edu/~kyamagu/paperdoll/models-v1.0.tar
    $ tar xvf models-v1.0.tar
    $ rm models-v1.0.tar

To run an experiment from scratch, download the dataset.

    $ cd paperdoll-v1.0/
    $ wget http://vision.cs.stonybrook.edu/~kyamagu/paperdoll/data-v1.0.tar
    $ tar xvf data-v1.0.tar
    $ rm data-v1.0.tar

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

The software is designed and tested using Ubuntu 12.04.

The following are the prerequisites for clothing parser.

 * Matlab
 * OpenCV
 * Berkeley DB
 * Boost C++ library

Also, to run all the experiments in the paper, it is required to have a
computing grid with Sun Grid Engine (SGE) or compatible distributed
environment. In Ubuntu, search for how to use `grindengine` package.

To install these requirements in Ubuntu,

    $ apt-get install build-essential libcv-dev libcvaux-dev libdb-dev \
                      libboost-all-dev

In OS X with Macports,

    $ port install opencv db53 boost

After installing prerequisites, the attached `make.m` script will compile all
the necessary binaries within Matlab.

    >> make

In OS X, probably it is necessary to pass additional flags.

    >> make('-I/opt/local/include/db53', '-L/opt/local/lib/db53')

### Runtime error

Depending on the Matlab installation, it is probably necessary to resolve
conflicting library dependency. Use `LD_PRELOAD` environmental variable
to prevent conflict at runtime. For example, in Ubuntu,

    $ LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6:/lib/x86_64-linux-gnu/libgcc_s.so.1:/lib/x86_64-linux-gnu/libz.so.1 matlab -singleCompThread

To find a conflicting library, use `ldd` tool within Matlab and also from
outside of Matlab, then compare the output. Append suspicious library
to the `LD_PRELOAD` variable.

    >> !ldd lib/mexopencv/+cv/imread.mex*
    $ ldd lib/mexopencv/+cv/imread.mex*

In OS X, the variable is named `DYLD_INSERT_LIBRARIES` instead. The `ldd`
equivalent is `otool -L`.

    $ DYLD_INSERT_LIBRARIES=/opt/local/lib/libtiff.5.dylib matlab


Usage
-----

Launch Matlab from the project root directory (i.e., `paperdoll-v1.0/`).
This will automatically call `startup` to initialize necessary environment.

### Run a pre-trained parser for a new image

    >> load data/paperdoll_pipeline.mat config;
    >> input_image = imread('/path/to/new_image.jpg');
    >> input_sample = struct('image', imencode(input_image, 'jpg')); 
    >> result = feature_calculator.apply(config, input_sample)

The result is a struct with the following fields.

 * `image`: input image in JPEG-format.
 * `pose`: estimated pose.
 * `refined_labels`: predicted clothing items.
 * `final_labeling`: PNG-encoded labeling.

To get a per-pixel labeling, use `imdecode`. For example, the following example
access the label of the pixel at (100, 100).

    >> labeling = imdecode(result.final_labeling, 'png');
    >> label = result.refined_labels{labeling(100, 100)};

To visualize the parsing result.

    >> show_parsing(result.image, result.final_labeling, result.refined_labels);

_TIPS_

The pose estimator is set up to process roughly 600x400 pixels in the
pre-trained model. Change the configuration by setting the image scaling
parameter. Also, lower the threshold value if the pipeline throws an error
in pose estimation.

    config{1}.scale = [200,200]; % Set the maximum image size in the pose estimator.
                                 % It is best to specify no larger than 200 pixels.
    config{1}.model.thresh = -2; % Change the threshold value if pose estimation fails.

### Run an experiment from scratch

Due to the copyright concern, we only provide image URLs in the PaperDoll
dataset. We also provide a script to download images. Please note that some of
the images might not be accessible at the provided URL since they might be
deleted by users. Depending on the network connection, downloading images takes
a day or more.

    $ echo task100_download_paperdoll_photos | matlab -nodisplay

After getting training images, use `tasks/paperdoll_main.sh` to run an
experiment from scratch. The script is designed to run on an SGE cluster
environment with Ubuntu 12.04 and all the required libraries.

    $ nohup ./tasks/paperdoll_main.sh < /dev/null > log/paperdoll_main.log 2>&1 &

Again, depending on the configuration, this can take a few days. Note that
because of the randomness in some of the algorithms and also the data
availability, we don't guarantee this reproduces the exact numbers reported in
the paper. However, the resulting model should give a similar figure.


SGE cluster with Debian/Ubuntu
------------------------------

To build an SGE grid in Debian/Ubuntu, install the following packages.

_Master_

    apt-get install gridengine-* default-jre

_Clients_

    apt-get install gridengine-exec gridengine-client default-jre

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

    segmentation = imdecode(truths(i).superpixel_map, 'png');
    clothing_annotation = truhts(i).superpixel_labels(segmentation);

To get a label at pixel (100, 100),

    label = truths(i).labels{clothing_annotation(100, 100)}


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

    tags = labels(samples(i).tagging);


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
